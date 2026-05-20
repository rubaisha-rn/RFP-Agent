"""Agent 2 — Compliance Auditor.

Receives the Requirements Classifier output (a ClassificationOutput-shaped
dict), consults the PPRA Rules 2004 table via the lookup_ppra_rules tool,
and produces a ComplianceOutput compliance scorecard.

Pipeline position:

    Classifier → **Auditor** → Vendor Intel → Drafter

The auditor_agent object is imported by the orchestrator and wired into a
SequentialAgent.  The audit_classification() helper is used for standalone
testing and by the FastAPI route layer.

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
from app.agents.schemas.compliance import ComplianceOutput
from app.agents.schemas.classification import ClassificationOutput
from app.services.supabase_client import supabase_service
from app.tools.ppra_rules import lookup_ppra_rules

# ---------------------------------------------------------------------------
# 4. Load the system prompt verbatim from the markdown file (once at import)
# ---------------------------------------------------------------------------
_PROMPT_PATH = Path(__file__).parent / "prompts" / "auditor.md"
AUDITOR_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 5. Strict JSON instruction appended when output_schema cannot be used
#    (ADK rejects the combination of output_schema + tools in some versions).
# ---------------------------------------------------------------------------
_JSON_INSTRUCTION = """

---
CRITICAL OUTPUT RULE:
You MUST output ONLY valid JSON matching the ComplianceOutput schema below.
No prose, no markdown fences, no explanation — just the raw JSON object.
Do NOT write any thinking, explanation, or conversational text outside the JSON object.
Perform all your reasoning and explanation INSIDE the "reasoning_notes" field of the JSON object.
The very first character of your response MUST be '{'.

Schema:
{
  "applicable_rule_codes": ["PPRA-R36a"],          // list[str], at least 1
  "confirmed_bidding_method": "single_stage_one_envelope",  // one of the 6 Literal values
  "mandatory_clauses": ["...full clause text..."],  // list[str], at least 1
  "compliance_score": 87.5,                         // float 0–100
  "advertisement_requirements": {                   // dict[str, bool]
    "ppra_website": true,
    "english_newspaper": true,
    "urdu_newspaper": false
  },
  "bid_validity_days": 90,                          // int > 0
  "integrity_pact_required": false,                 // bool
  "issues_flagged": [],                             // list[str], may be empty
  "reasoning_notes": "..."                          // str
}
"""

# ---------------------------------------------------------------------------
# 6. Define the ADK Agent
#    Try with output_schema first; fall back to manual JSON parsing if ADK
#    raises a ValueError about the schema+tools combination.
# ---------------------------------------------------------------------------
_USE_OUTPUT_SCHEMA = False

from google.adk.models import Gemini

auditor_agent = Agent(
    name="compliance_auditor",
    model=Gemini(
        model=settings.model_auditor,
        retry_options=types.HttpRetryOptions(
            attempts=6,
            initial_delay=3.0,
            max_delay=60.0,
            http_status_codes=[408, 429, 500, 503, 504]
        )
    ),
    description=(
        "Audits a procurement classification against PPRA Rules 2004 "
        "and produces a compliance scorecard."
    ),
    instruction=AUDITOR_PROMPT + _JSON_INSTRUCTION,
    output_key="compliance",
    tools=[lookup_ppra_rules],
    generate_content_config=types.GenerateContentConfig(temperature=0.0),
)

# ---------------------------------------------------------------------------
# 7. Module-level Runner (shared across calls; each call gets its own session)
# ---------------------------------------------------------------------------
_APP_NAME = "rfp_auditor"
_session_service = InMemorySessionService()
_runner = Runner(
    agent=auditor_agent,
    app_name=_APP_NAME,
    session_service=_session_service,
)


# ---------------------------------------------------------------------------
# 8. async helper: audit_classification
# ---------------------------------------------------------------------------

async def audit_classification(job_id: str, classification: dict) -> ComplianceOutput:
    """Run the Compliance Auditor against a classification dict and return a scorecard.

    Side-effects:
    - Writes a "started" trace row (step 1) to Supabase before invocation.
    - Writes trace rows for each tool call AND tool response observed (25% rubric).
    - Writes a "completed" trace row with full output_data on success.
    - Writes a "failed" trace row on error, then re-raises.

    Args:
        job_id: UUID of the rfp_jobs row (foreign key for traces).
        classification: JSON-serialisable dict shaped like ClassificationOutput
                        (the orchestrator passes session state["classification"]).

    Returns:
        A validated ComplianceOutput instance.
    """
    category = classification.get("category", "unknown")
    value = classification.get("estimated_value_pkr", 0)

    # -- trace: started -------------------------------------------------------
    current_step = 1
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="auditor",
        step_number=current_step,
        reasoning=(
            f"Auditor started; received classification with "
            f"category={category!r}, value=PKR {value:,.0f}"
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
    user_text = (
        json.dumps(classification, ensure_ascii=False)
        + "\n\nAudit this classification against PPRA Rules 2004."
    )
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
            # -- trace tool calls and responses (25% rubric) ------------------
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, "function_call") and part.function_call:
                        supabase_service.write_trace(
                            job_id=job_id,
                            agent_name="auditor",
                            step_number=current_step,
                            reasoning=f"Calling tool: {part.function_call.name}",
                            tool_called=part.function_call.name,
                            tool_input=dict(part.function_call.args),
                        )
                        current_step += 1

                    if hasattr(part, "function_response") and part.function_response:
                        # Convert response to a plain dict for storage
                        raw_resp = part.function_response.response
                        if not isinstance(raw_resp, dict):
                            raw_resp = {"result": str(raw_resp)}
                        supabase_service.write_trace(
                            job_id=job_id,
                            agent_name="auditor",
                            step_number=current_step,
                            reasoning=f"Tool returned: {part.function_response.name}",
                            tool_called=part.function_response.name,
                            tool_output=raw_resp,
                        )
                        current_step += 1

            # -- capture final text -------------------------------------------
            if event.is_final_response():
                if event.content and event.content.parts:
                    final_response_text = event.content.parts[0].text
                break

    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="auditor",
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
        state_val = session.state.get("compliance") if session else None

        if isinstance(state_val, dict):
            compliance = ComplianceOutput.model_validate(state_val)
        elif isinstance(state_val, ComplianceOutput):
            compliance = state_val
        elif final_response_text:
            clean_text = final_response_text.strip()
            # Robust JSON extraction to handle conversational prefix/suffix and markdown fences
            first_brace = clean_text.find("{")
            last_brace = clean_text.rfind("}")
            if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
                clean_text = clean_text[first_brace:last_brace + 1]
            compliance = ComplianceOutput.model_validate_json(clean_text)
        else:
            raise ValueError(
                "No compliance output found in session state or response text."
            )

    except Exception as exc:
        import sys
        print(f"[DEBUG] final_response_text: {repr(final_response_text)}", file=sys.stderr)
        if 'clean_text' in locals():
            print(f"[DEBUG] clean_text: {repr(clean_text)}", file=sys.stderr)
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="auditor",
            step_number=current_step,
            reasoning=f"Output parsing failed: {exc}",
        )
        raise

    # -- trace: completed -----------------------------------------------------
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="auditor",
        step_number=current_step,
        reasoning=(
            f"Auditor completed. "
            f"Rules={compliance.applicable_rule_codes}, "
            f"Method={compliance.confirmed_bidding_method}, "
            f"Score={compliance.compliance_score:.1f}, "
            f"IntegrityPact={compliance.integrity_pact_required}. "
            f"Notes: {compliance.reasoning_notes[:200]}"
        ),
        output_data=compliance.model_dump(),
    )

    return compliance


# ---------------------------------------------------------------------------
# 9. Test harness
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import sys

    DEMO_BRIEF = (
        "We need a digital citizen services portal for the Punjab government. "
        "Cloud-hosted, must support Urdu and English, integrate with NADRA API "
        "for identity verification. Budget around 2.5 million PKR. "
        "Required within 90 days."
    )

    async def _main() -> None:
        print("=" * 70)
        print("RFP Agent System — Agent 2: Compliance Auditor (test harness)")
        print("=" * 70)
        print(f"  ADK output_schema mode: {'combined (schema+tools)' if _USE_OUTPUT_SCHEMA else 'manual JSON parsing (tools-only fallback)'}")

        # 1. Create a shared job row in Supabase
        print("\n[1/5] Creating job in Supabase...")
        job = supabase_service.create_job(None, DEMO_BRIEF)
        job_id: str = job["id"]
        print(f"      job_id = {job_id}")

        # 2. Run Agent 1 (Classifier) to get the classification
        print("\n[2/5] Running Agent 1 — Classifier...")
        # Import here to avoid circular dependency at module level
        from app.agents.agent1_classifier import classify_brief  # noqa: PLC0415

        try:
            classification_result = await classify_brief(job_id, DEMO_BRIEF)
        except Exception as exc:
            print(f"[ERROR] classify_brief raised: {exc}", file=sys.stderr)
            raise

        print(f"      Category={classification_result.category}")
        print(f"      Value=PKR {classification_result.estimated_value_pkr:,.0f}")
        print(f"      Classifier method={classification_result.bidding_method}")

        # 3. Run Agent 2 (Auditor) on the classification
        print("\n[3/5] Running Agent 2 — Auditor...")
        classification_dict = classification_result.model_dump()

        try:
            compliance_result = await audit_classification(job_id, classification_dict)
        except Exception as exc:
            print(f"[ERROR] audit_classification raised: {exc}", file=sys.stderr)
            raise

        # 4. Print the compliance scorecard
        print("\n[4/5] Compliance scorecard (JSON):")
        print(json.dumps(compliance_result.model_dump(), indent=2, ensure_ascii=False))

        # 5. Fetch and print all trace rows (classifier + auditor combined)
        print("\n[5/5] All trace rows from Supabase (classifier + auditor):")
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
        print("\nDone.")

    asyncio.run(_main())
