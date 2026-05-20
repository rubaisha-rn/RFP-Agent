"""Agent 3 — Vendor Intelligence.

Receives the Requirements Classifier output and Compliance Auditor output,
queries vendor DB, checks conflicts, predicts bid range, and produces VendorRankingOutput.

Pipeline position:

    Classifier → Auditor → **Vendor Intel** → Drafter

ADK gotcha:
    Some ADK versions reject an Agent that has both output_schema AND tools.
    We attempt the combined form first; if ADK raises a ValueError at import
    time we fall back to tool-only mode and parse the JSON response manually.
"""

from __future__ import annotations

import asyncio
import json
import os
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# 1. Ensure GOOGLE_API_KEY is exported to the environment BEFORE any ADK
#    import that triggers model construction.
# ---------------------------------------------------------------------------
from app.config import settings

os.environ.setdefault("GOOGLE_API_KEY", settings.google_api_key)

# ---------------------------------------------------------------------------
# 2. ADK imports (after the env-var is set)
# ---------------------------------------------------------------------------
from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# ---------------------------------------------------------------------------
# 3. Project imports
# ---------------------------------------------------------------------------
from app.agents.schemas.vendor_ranking import VendorRankingOutput
from app.services.supabase_client import supabase_service
from app.tools.vendor_db import query_vendors
from app.tools.conflict_check import run_conflict_check
from app.tools.bid_predictor import predict_bid_range

# ---------------------------------------------------------------------------
# 4. Load the system prompt verbatim from the markdown file (once at import)
# ---------------------------------------------------------------------------
_PROMPT_PATH = Path(__file__).parent / "prompts" / "vendor_intel.md"
VENDOR_INTEL_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 5. Strict JSON instruction appended when output_schema cannot be used
# ---------------------------------------------------------------------------
_JSON_INSTRUCTION = """

---
CRITICAL OUTPUT RULE:
You MUST output ONLY valid JSON matching the VendorRankingOutput schema below.
No prose, no markdown fences, no explanation — just the raw JSON object.
Do NOT write any thinking, explanation, or conversational text outside the JSON object.
Perform all your reasoning and explanation INSIDE the "reasoning_notes" field of the JSON object.
The very first character of your response MUST be '{'.

Schema:
{
  "shortlist": [
    {
      "vendor_id": "uuid-string",
      "name": "TechNova Solutions Pvt Ltd",
      "email": "bids@technova.pk",
      "score": 4.55,
      "predicted_bid_pkr": 2500000,
      "conflict_status": "clear"
    }
  ],
  "predicted_bid_range_pkr": {
    "min": 1900000.0,
    "max": 3000000.0,
    "median": 2400000.0
  },
  "conflicts_flagged": [
    {"vendor_name": "Quantum IT Services", "flag": "pending_litigation"}
  ],
  "total_vendors_evaluated": 7,
  "reasoning_notes": "Brief explanation of scoring and any notable filtering decisions."
}
"""

# ---------------------------------------------------------------------------
# 6. Define the ADK Agent
# ---------------------------------------------------------------------------
_USE_OUTPUT_SCHEMA = False

from google.adk.models import Gemini

vendor_intel_agent = Agent(
    name="vendor_intel",
    model=Gemini(
        model=settings.model_vendor_intel,
        retry_options=types.HttpRetryOptions(
            attempts=6,
            initial_delay=3.0,
            max_delay=60.0,
            http_status_codes=[408, 429, 500, 503, 504]
        )
    ),
    description=(
        "Identifies, qualifies, scores, and ranks vendors for an RFP."
    ),
    instruction=VENDOR_INTEL_PROMPT + _JSON_INSTRUCTION,
    output_key="vendor_intel",
    tools=[query_vendors, run_conflict_check, predict_bid_range],
    generate_content_config=types.GenerateContentConfig(temperature=0.0),
)

# ---------------------------------------------------------------------------
# 7. Module-level Runner
# ---------------------------------------------------------------------------
_APP_NAME = "rfp_vendor_intel"
_session_service = InMemorySessionService()
_runner = Runner(
    agent=vendor_intel_agent,
    app_name=_APP_NAME,
    session_service=_session_service,
)


# ---------------------------------------------------------------------------
# 8. async helper: rank_vendors
# ---------------------------------------------------------------------------

async def rank_vendors(job_id: str, classification: dict, compliance: dict) -> VendorRankingOutput:
    """Run the Vendor Intelligence agent.
    
    Args:
        job_id: UUID of the rfp_jobs row.
        classification: Output of the Classifier agent.
        compliance: Output of the Auditor agent.
    """
    category = classification.get("category", "unknown")

    # -- trace: started -------------------------------------------------------
    current_step = 1
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="vendor_intel",
        step_number=current_step,
        reasoning=(
            f"Vendor Intel started; received category={category!r}"
        ),
    )
    current_step += 1

    # -- create a fresh session per invocation --------------------------------
    user_id = "system"
    session_id = str(uuid.uuid4())

    await _session_service.create_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session_id,
    )

    # -- build the user Content message ---------------------------------------
    user_text = json.dumps({
        "classification": classification,
        "compliance": compliance
    }, ensure_ascii=False)
    
    user_message = types.Content(
        role="user",
        parts=[types.Part(text=user_text)],
    )

    # -- run the agent, collect events ----------------------------------------
    final_response_text: str | None = None
    try:
        async for event in _runner.run_async(
            user_id=user_id,
            session_id=session_id,
            new_message=user_message,
        ):
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, "function_call") and part.function_call:
                        supabase_service.write_trace(
                            job_id=job_id,
                            agent_name="vendor_intel",
                            step_number=current_step,
                            reasoning=f"Calling tool: {part.function_call.name}",
                            tool_called=part.function_call.name,
                            tool_input=dict(part.function_call.args),
                        )
                        current_step += 1

                    if hasattr(part, "function_response") and part.function_response:
                        raw_resp = part.function_response.response
                        if not isinstance(raw_resp, dict):
                            raw_resp = {"result": str(raw_resp)}
                            
                        # Truncate tool_output for query_vendors traces
                        if part.function_response.name == "query_vendors":
                            vendors_list = raw_resp.get("vendors", [])
                            truncated_resp = {
                                "count": raw_resp.get("count", 0),
                                "category_searched": raw_resp.get("category_searched", ""),
                                "vendors_sample": [v.get("name") for v in vendors_list[:3]]
                            }
                            trace_output = truncated_resp
                        else:
                            trace_output = raw_resp

                        supabase_service.write_trace(
                            job_id=job_id,
                            agent_name="vendor_intel",
                            step_number=current_step,
                            reasoning=f"Tool returned: {part.function_response.name}",
                            tool_called=part.function_response.name,
                            tool_output=trace_output,
                        )
                        current_step += 1

            if event.is_final_response():
                if event.content and event.content.parts:
                    final_response_text = event.content.parts[0].text
                break

    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="vendor_intel",
            step_number=current_step,
            reasoning=f"Agent failed with error: {exc}",
        )
        raise

    # -- parse output ---------------------------------------------------------
    try:
        session = await _session_service.get_session(
            app_name=_APP_NAME,
            user_id=user_id,
            session_id=session_id,
        )
        state_val = session.state.get("vendor_intel") if session else None

        if isinstance(state_val, dict):
            vendor_intel = VendorRankingOutput.model_validate(state_val)
        elif isinstance(state_val, VendorRankingOutput):
            vendor_intel = state_val
        elif final_response_text:
            clean_text = final_response_text.strip()
            # Robust JSON extraction to handle conversational prefix/suffix and markdown fences
            first_brace = clean_text.find("{")
            last_brace = clean_text.rfind("}")
            if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
                clean_text = clean_text[first_brace:last_brace + 1]
            vendor_intel = VendorRankingOutput.model_validate_json(clean_text)
        else:
            raise ValueError(
                "No vendor_intel output found in session state or response text."
            )

    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="vendor_intel",
            step_number=current_step,
            reasoning=f"Output parsing failed: {exc}",
        )
        raise

    # -- trace: completed -----------------------------------------------------
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="vendor_intel",
        step_number=current_step,
        reasoning=(
            f"Vendor Intel completed. "
            f"Evaluated {vendor_intel.total_vendors_evaluated} vendors, "
            f"shortlisted {len(vendor_intel.shortlist)} vendors. "
            f"Notes: {vendor_intel.reasoning_notes[:200]}"
        ),
        output_data=vendor_intel.model_dump(),
    )

    return vendor_intel


# ---------------------------------------------------------------------------
# 9. Test harness
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import sys
    import warnings
    import logging
    warnings.filterwarnings("ignore")
    logging.getLogger("opentelemetry").setLevel(logging.CRITICAL)

    DEMO_BRIEF = (
        "We need a digital citizen services portal for the Punjab government. "
        "Cloud-hosted, must support Urdu and English, integrate with NADRA API "
        "for identity verification. Budget around 2.5 million PKR. "
        "Required within 90 days."
    )

    async def _main() -> None:
        print("=" * 70)
        print("RFP Agent System — Agent 3: Vendor Intelligence (test harness)")
        print("=" * 70)
        print(f"  ADK output_schema mode: {'combined (schema+tools)' if _USE_OUTPUT_SCHEMA else 'manual JSON parsing (tools-only fallback)'}")

        # 1. Create a shared job row in Supabase
        print("\n[1/5] Creating job in Supabase...")
        job = supabase_service.create_job(None, DEMO_BRIEF)
        job_id: str = job["id"]
        print(f"      job_id = {job_id}")

        # 2. Run Agent 1 (Classifier) to get the classification
        print("\n[2/5] Running Agent 1 — Classifier...")
        from app.agents.agent1_classifier import classify_brief  # noqa: PLC0415
        
        try:
            classification_result = await classify_brief(job_id, DEMO_BRIEF)
        except Exception as exc:
            print(f"[ERROR] classify_brief raised: {exc}", file=sys.stderr)
            raise

        # 3. Run Agent 2 (Auditor) on the classification
        print("\n[3/5] Running Agent 2 — Auditor...")
        from app.agents.agent2_auditor import audit_classification # noqa: PLC0415
        classification_dict = classification_result.model_dump()

        try:
            compliance_result = await audit_classification(job_id, classification_dict)
        except Exception as exc:
            print(f"[ERROR] audit_classification raised: {exc}", file=sys.stderr)
            raise
            
        compliance_dict = compliance_result.model_dump()

        # 4. Run Agent 3 (Vendor Intel)
        print("\n[4/5] Running Agent 3 — Vendor Intel...")
        try:
            vendor_intel_result = await rank_vendors(job_id, classification_dict, compliance_dict)
        except Exception as exc:
            print(f"[ERROR] rank_vendors raised: {exc}", file=sys.stderr)
            raise

        print("\nShortlist:")
        print(f"{'ID':<8} {'Name':<30} {'Score':<6} {'Bid (PKR)':<12} {'Status':<10}")
        print("-" * 70)
        for v in vendor_intel_result.shortlist:
            print(f"{v.vendor_id[:8]:<8} {v.name[:30]:<30} {v.score:<6.2f} {v.predicted_bid_pkr:<12,.0f} {v.conflict_status:<10}")

        print("\nBid Range:")
        print(f"Min: {vendor_intel_result.predicted_bid_range_pkr.min:,.0f} PKR")
        print(f"Median: {vendor_intel_result.predicted_bid_range_pkr.median:,.0f} PKR")
        print(f"Max: {vendor_intel_result.predicted_bid_range_pkr.max:,.0f} PKR")

        # 5. Fetch and print all trace rows
        print("\n[5/5] All trace rows from Supabase (classifier + auditor + vendor_intel):")
        traces = supabase_service.list_traces(job_id)
        for t in traces:
            tool_info = (
                f"  tool={t.get('tool_called')!r}" if t.get("tool_called") else ""
            )
            print(
                f"  step={t['step_number']:>2}  agent={t['agent_name']:<12}"
                f"{tool_info}  reasoning={t['reasoning'][:100]!r}"
            )
        print(f"\n  Total traces: {len(traces)}")
        
        supabase_service.update_job_status(job_id, "completed")
        print("\nDone.")

    asyncio.run(_main())
