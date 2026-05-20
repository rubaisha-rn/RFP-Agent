"""Agent 1 — Requirements Classifier.

Parses a free-form procurement brief into a PPRA-aligned structured JSON
classification. This is the first agent in the pipeline:

    Classifier → Auditor → Vendor Intel → Drafter

The classifier_agent object is imported by the orchestrator and wired into
a SequentialAgent. The classify_brief() helper is used for standalone testing
and by the FastAPI route layer.
"""

from __future__ import annotations

import asyncio
import json
import os
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# 1. Ensure GOOGLE_API_KEY is exported to the environment BEFORE any ADK
#    import that triggers model construction.  config.py reads from .env, so
#    importing Settings first is sufficient.
# ---------------------------------------------------------------------------
from app.config import settings

os.environ.setdefault("GOOGLE_API_KEY", settings.google_api_key)

# ---------------------------------------------------------------------------
# 2. ADK imports (after the env-var is set)
# ---------------------------------------------------------------------------
from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.models import Gemini
from google.genai import types

# ---------------------------------------------------------------------------
# 3. Project imports
# ---------------------------------------------------------------------------
from app.agents.schemas.classification import ClassificationOutput
from app.services.supabase_client import supabase_service

# ---------------------------------------------------------------------------
# 4. Load the system prompt verbatim from the markdown file (once at import)
# ---------------------------------------------------------------------------
_PROMPT_PATH = Path(__file__).parent / "prompts" / "classifier.md"
CLASSIFIER_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 5. Define the ADK Agent
# ---------------------------------------------------------------------------
classifier_agent = Agent(
    name="requirements_classifier",
    model=Gemini(
        model=settings.model_classifier,
        retry_options=types.HttpRetryOptions(
            attempts=6,
            initial_delay=3.0,
            max_delay=60.0,
            http_status_codes=[408, 429, 500, 503, 504]
        )
    ),
    description="Parses a procurement brief into a structured PPRA-aligned classification.",
    instruction=CLASSIFIER_PROMPT,
    output_schema=ClassificationOutput,
    output_key="classification",        # downstream agents read state["classification"]
    generate_content_config=types.GenerateContentConfig(temperature=0.0),
)

# ---------------------------------------------------------------------------
# 6. Module-level Runner (shared across calls; each call gets its own session)
# ---------------------------------------------------------------------------
_APP_NAME = "rfp_classifier"
_session_service = InMemorySessionService()
_runner = Runner(
    agent=classifier_agent,
    app_name=_APP_NAME,
    session_service=_session_service,
)

# ---------------------------------------------------------------------------
# 7. async helper: classify_brief
# ---------------------------------------------------------------------------

async def classify_brief(job_id: str, brief: str) -> ClassificationOutput:
    """Run the classifier agent against *brief* and return structured output.

    Side-effects:
    - Writes a "started" trace row (step 1) to Supabase before invocation.
    - Writes a "completed" trace row (step 2) with full output_data on success.
    - Writes a "failed" trace row (step 2) on error, then re-raises.

    Args:
        job_id: UUID of the rfp_jobs row (used as the foreign key in traces).
        brief:  The raw procurement brief text from the officer.

    Returns:
        A validated ClassificationOutput instance.
    """
    # -- trace: started -------------------------------------------------------
    brief_preview = brief[:120] + ("..." if len(brief) > 120 else "")
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="classifier",
        step_number=1,
        reasoning=f"Agent started; received brief: {brief_preview}",
    )

    # -- create a fresh session per invocation --------------------------------
    user_id = "system"
    session_id = str(uuid.uuid4())

    await _session_service.create_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session_id,
    )

    # -- build the user Content message ---------------------------------------
    user_message = types.Content(
        role="user",
        parts=[types.Part(text=brief)],
    )

    # -- run the agent, collect events ----------------------------------------
    final_response_text: str | None = None
    try:
        async for event in _runner.run_async(
            user_id=user_id,
            session_id=session_id,
            new_message=user_message,
        ):
            if event.is_final_response():
                if event.content and event.content.parts:
                    final_response_text = event.content.parts[0].text
    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="classifier",
            step_number=2,
            reasoning=f"Agent failed with error: {exc}",
        )
        raise

    # -- parse output ---------------------------------------------------------
    # When output_schema is set the ADK serialises the model to JSON in the
    # final response text.  We also check the session state["classification"].
    try:
        session = await _session_service.get_session(
            app_name=_APP_NAME,
            user_id=user_id,
            session_id=session_id,
        )
        state_val = session.state.get("classification") if session else None

        if isinstance(state_val, dict):
            classification = ClassificationOutput.model_validate(state_val)
        elif isinstance(state_val, ClassificationOutput):
            classification = state_val
        elif final_response_text:
            # Fallback: parse the raw JSON text
            classification = ClassificationOutput.model_validate_json(final_response_text)
        else:
            raise ValueError("No classification output found in session state or response text.")

    except Exception as exc:
        supabase_service.write_trace(
            job_id=job_id,
            agent_name="classifier",
            step_number=2,
            reasoning=f"Output parsing failed: {exc}",
        )
        raise

    # -- trace: completed -----------------------------------------------------
    supabase_service.write_trace(
        job_id=job_id,
        agent_name="classifier",
        step_number=2,
        reasoning=(
            f"Agent completed. Category={classification.category}, "
            f"Value=PKR {classification.estimated_value_pkr:,.0f}, "
            f"Bidding={classification.bidding_method}. "
            f"Notes: {classification.reasoning_notes[:200]}"
        ),
        output_data=classification.model_dump(),
    )

    return classification


# ---------------------------------------------------------------------------
# 8. Test harness
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
        print("RFP Agent System — Agent 1: Requirements Classifier (test harness)")
        print("=" * 70)

        # 1. Create a job row in Supabase
        print("\n[1/4] Creating job in Supabase...")
        job = supabase_service.create_job(None, DEMO_BRIEF)
        job_id: str = job["id"]
        print(f"      job_id = {job_id}")

        # 2. Run the classifier
        print("\n[2/4] Running classify_brief()...")
        try:
            result = await classify_brief(job_id, DEMO_BRIEF)
        except Exception as exc:
            print(f"[ERROR] classify_brief raised: {exc}", file=sys.stderr)
            raise

        # 3. Print structured output
        print("\n[3/4] Structured output (JSON):")
        print(json.dumps(result.model_dump(), indent=2, ensure_ascii=False))

        # 4. Fetch and print trace rows
        print("\n[4/4] Trace rows from Supabase:")
        traces = supabase_service.list_traces(job_id)
        for t in traces:
            print(
                f"  step={t['step_number']}  agent={t['agent_name']}  "
                f"reasoning={t['reasoning'][:120]!r}"
            )
        print(f"\n  Total traces: {len(traces)}")
        print("\nDone.")

    asyncio.run(_main())
