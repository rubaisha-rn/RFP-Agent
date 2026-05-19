"""Agent 4 — Drafter & Executor.

Receives all three previous outputs and must:
1. Synthesize a complete RFP document.
2. Generate a real PDF.
3. Send invitation emails to shortlisted vendors.
4. Create calendar events.
5. Post the RFP to the PPRA portal.

Pipeline position:

    Classifier → Auditor → Vendor Intel → **Drafter**

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
from app.agents.schemas.final_rfp import FinalRFPOutput
from app.services.supabase_client import supabase_service
from app.tools.pdf_generator import generate_rfp_pdf, save_document_record
from app.tools.email_sender import send_invitation_email
from app.tools.calendar_creator import create_calendar_event
from app.tools.portal_poster import post_to_portal

# ---------------------------------------------------------------------------
# 4. Load the system prompt verbatim from the markdown file (once at import)
# ---------------------------------------------------------------------------
_PROMPT_PATH = Path(__file__).parent / "prompts" / "drafter.md"
DRAFTER_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 5. Strict JSON instruction appended when output_schema cannot be used
# ---------------------------------------------------------------------------
_JSON_INSTRUCTION = """

---
CRITICAL OUTPUT RULE:
You MUST output ONLY valid JSON matching the FinalRFPOutput schema.
No prose, no markdown fences, no explanation — just the raw JSON object.

Schema:
{
  "final_rfp": {
    "title": "...",
    "scope_of_work": "...",
    "eligibility_criteria": ["..."],
    "evaluation_criteria": ["..."],
    "mandatory_clauses": ["..."],
    "submission_deadline_iso": "...",
    "opening_date_iso": "...",
    "contact_info": {
      "name": "...",
      "email": "...",
      "phone": "...",
      "organization": "..."
    }
  },
  "executed_actions": {
    "document_id": "uuid",
    "pdf_path": "...",
    "emails_sent": [
      {"vendor_name": "...", "email_id": "uuid"}
    ],
    "calendar_events_created": [
      {"title": "...", "event_id": "uuid"}
    ],
    "portal_posting": {
      "reference_id": "...",
      "posting_id": "uuid",
      "posted_url": "..."
    }
  },
  "reasoning_notes": "..."
}
"""

# ---------------------------------------------------------------------------
# 6. Define the ADK Agent
# ---------------------------------------------------------------------------
_USE_OUTPUT_SCHEMA = False

drafter_agent = Agent(
    name="drafter",
    model="gemini-2.5-flash",
    description=(
        "Synthesizes the RFP and executes actions to post it and notify vendors."
    ),
    instruction=DRAFTER_PROMPT + _JSON_INSTRUCTION,
    output_key="final_rfp_output",
    tools=[generate_rfp_pdf, save_document_record, send_invitation_email, create_calendar_event, post_to_portal],
)

# ---------------------------------------------------------------------------
# 7. Module-level Runner
# ---------------------------------------------------------------------------
_APP_NAME = "rfp_drafter"
_session_service = InMemorySessionService()
_runner = Runner(
    agent=drafter_agent,
    app_name=_APP_NAME,
    session_service=_session_service,
)


# ---------------------------------------------------------------------------
# 8. async helper: draft_and_execute
# ---------------------------------------------------------------------------

async def draft_and_execute(
    job_id: str,
    classification: dict,
    compliance: dict,
    vendor_intel: dict,
    issuing_organization: str = "Government of Punjab",
    procurement_officer: dict | None = None
) -> FinalRFPOutput:
    """Run the Drafter & Executor agent.
    
    Args:
        job_id: UUID of the rfp_jobs row.
        classification: Output of the Classifier agent.
        compliance: Output of the Auditor agent.
        vendor_intel: Output of the Vendor Intel agent.
        issuing_organization: Name of the procuring organization.
        procurement_officer: Dict with name, email, phone.
    """
    if procurement_officer is None:
        procurement_officer = {
            "name": "Procurement Officer",
            "email": "proc@punjab.gov.pk",
            "phone": "+92-42-9920-0000",
            "organization": "Government of Punjab"
        }

    # -- trace: started -------------------------------------------------------
    current_step = 1
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="drafter",
        step_number=current_step,
        reasoning="Drafter started; received classification, compliance, and vendor intel",
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
        "job_id": job_id,
        "issuing_organization": issuing_organization,
        "procurement_officer": procurement_officer,
        "classification": classification,
        "compliance": compliance,
        "vendor_intel": vendor_intel
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
                            agent_name="drafter",
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
                            
                        # Truncate tool_output for specific traces
                        if part.function_response.name == "save_document_record":
                            trace_output = {"document_id": raw_resp.get("document_id")}
                        elif part.function_response.name == "send_invitation_email":
                            trace_output = {
                                "email_id": raw_resp.get("email_id"),
                                "to_email": raw_resp.get("to_email"),
                                "subject": raw_resp.get("subject"),
                            }
                        else:
                            trace_output = raw_resp

                        supabase_service.write_trace(
                            job_id=job_id,
                            agent_name="drafter",
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
            agent_name="drafter",
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
        state_val = session.state.get("final_rfp_output") if session else None

        if isinstance(state_val, dict):
            final_output = FinalRFPOutput.model_validate(state_val)
        elif isinstance(state_val, FinalRFPOutput):
            final_output = state_val
        elif final_response_text:
            clean_text = final_response_text.strip()
            if clean_text.startswith("```"):
                lines = clean_text.splitlines()
                inner = [l for l in lines[1:] if l.strip() != "```"]
                clean_text = "\n".join(inner)
            final_output = FinalRFPOutput.model_validate_json(clean_text)
        else:
            raise ValueError(
                "No final_rfp_output found in session state or response text."
            )

    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="drafter",
            step_number=current_step,
            reasoning=f"Output parsing failed: {exc}",
        )
        raise

    # -- trace: completed -----------------------------------------------------
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="drafter",
        step_number=current_step,
        reasoning=(
            f"Drafter completed. "
            f"Notes: {final_output.reasoning_notes[:200]}"
        ),
        output_data=final_output.model_dump(),
    )

    return final_output


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
        print("RFP Agent System — Agent 4: Drafter & Executor (test harness)")
        print("=" * 70)
        print("  Waiting 60 seconds before starting to clear rate limits...")
        await asyncio.sleep(60)
        print("  ADK output_schema mode: {'combined (schema+tools)' if _USE_OUTPUT_SCHEMA else 'manual JSON parsing (tools-only fallback)'}")

        # 1. Create a shared job row in Supabase
        print("\n[1/6] Creating job in Supabase...")
        job = supabase_service.create_job(None, DEMO_BRIEF)
        job_id: str = job["id"]
        print(f"      job_id = {job_id}")

        # 2. Run Agent 1 (Classifier)
        print("\n[2/6] Running Agent 1 — Classifier...")
        from app.agents.agent1_classifier import classify_brief  # noqa: PLC0415
        
        for attempt in range(5):
            try:
                classification_result = await classify_brief(job_id, DEMO_BRIEF)
                break
            except Exception as exc:
                if "429" in str(exc) or "RESOURCE_EXHAUSTED" in str(exc):
                    print(f"  [Rate Limit] Caught 429 in Agent 1. Sleeping 65s before retry {attempt+1}/5...")
                    await asyncio.sleep(65)
                else:
                    print(f"[ERROR] classify_brief raised: {exc}", file=sys.stderr)
                    raise
        else:
            raise RuntimeError("Failed to run Agent 1 after 5 attempts due to rate limits.")
            
        print("  Sleeping for 60s to avoid rate limits...")
        await asyncio.sleep(60)

        # 3. Run Agent 2 (Auditor)
        print("\n[3/6] Running Agent 2 — Auditor...")
        from app.agents.agent2_auditor import audit_classification # noqa: PLC0415
        classification_dict = classification_result.model_dump()

        for attempt in range(5):
            try:
                compliance_result = await audit_classification(job_id, classification_dict)
                break
            except Exception as exc:
                if "429" in str(exc) or "RESOURCE_EXHAUSTED" in str(exc):
                    print(f"  [Rate Limit] Caught 429 in Agent 2. Sleeping 65s before retry {attempt+1}/5...")
                    await asyncio.sleep(65)
                else:
                    print(f"[ERROR] audit_classification raised: {exc}", file=sys.stderr)
                    raise
        else:
            raise RuntimeError("Failed to run Agent 2 after 5 attempts due to rate limits.")
            
        compliance_dict = compliance_result.model_dump()

        print("  Sleeping for 60s to avoid rate limits...")
        await asyncio.sleep(60)

        # 4. Run Agent 3 (Vendor Intel)
        print("\n[4/6] Running Agent 3 — Vendor Intel...")
        from app.agents.agent3_vendor_intel import rank_vendors # noqa: PLC0415
        for attempt in range(5):
            try:
                vendor_intel_result = await rank_vendors(job_id, classification_dict, compliance_dict)
                break
            except Exception as exc:
                if "429" in str(exc) or "RESOURCE_EXHAUSTED" in str(exc):
                    print(f"  [Rate Limit] Caught 429 in Agent 3. Sleeping 65s before retry {attempt+1}/5...")
                    await asyncio.sleep(65)
                else:
                    print(f"[ERROR] rank_vendors raised: {exc}", file=sys.stderr)
                    raise
        else:
            raise RuntimeError("Failed to run Agent 3 after 5 attempts due to rate limits.")
            
        vendor_intel_dict = vendor_intel_result.model_dump()

        print("  Sleeping for 60s to avoid rate limits...")
        await asyncio.sleep(60)

        # 5. Run Agent 4 (Drafter & Executor)
        print("\n[5/6] Running Agent 4 — Drafter & Executor...")
        for attempt in range(5):
            try:
                drafter_result = await draft_and_execute(
                    job_id,
                    classification_dict,
                    compliance_dict,
                    vendor_intel_dict
                )
                break
            except Exception as exc:
                if "429" in str(exc) or "RESOURCE_EXHAUSTED" in str(exc):
                    print(f"  [Rate Limit] Caught 429 in Agent 4. Sleeping 65s before retry {attempt+1}/5...")
                    await asyncio.sleep(65)
                else:
                    print(f"[ERROR] draft_and_execute raised: {exc}", file=sys.stderr)
                    raise
        else:
            raise RuntimeError("Failed to run Agent 4 after 5 attempts due to rate limits.")

        print("\nFinal Output:")
        print(f"  RFP Title: {drafter_result.final_rfp.title}")
        print(f"  Reference ID: {drafter_result.executed_actions.portal_posting.reference_id}")
        print(f"  PDF Path: {drafter_result.executed_actions.pdf_path}")
        print(f"  Emails Sent: {len(drafter_result.executed_actions.emails_sent)}")
        print(f"  Calendar Events Created: {len(drafter_result.executed_actions.calendar_events_created)}")

        # 6. Fetch and print all trace rows + table counts
        print("\n[6/6] Fetching traces and verifying DB tables...")
        traces = supabase_service.list_traces(job_id)
        
        # We need to query table counts for this job_id
        # We can do this manually using the client
        docs_res = supabase_service.client.table("generated_documents").select("*", count="exact").eq("job_id", job_id).execute()
        emails_res = supabase_service.client.table("sent_emails").select("*", count="exact").eq("job_id", job_id).execute()
        events_res = supabase_service.client.table("calendar_events").select("*", count="exact").eq("job_id", job_id).execute()
        portal_res = supabase_service.client.table("portal_postings").select("*", count="exact").eq("job_id", job_id).execute()

        print(f"  Total agent_traces rows: {len(traces)}")
        print(f"  generated_documents rows: {docs_res.count}")
        print(f"  sent_emails rows: {emails_res.count}")
        print(f"  calendar_events rows: {events_res.count}")
        print(f"  portal_postings rows: {portal_res.count}")
        
        supabase_service.update_job_status(job_id, "completed")
        print("\nDone.")

    asyncio.run(_main())
