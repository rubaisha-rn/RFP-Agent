# Agent 1 (Classifier) — Build-Time Reasoning Trace

**Date:** 2026-05-19
**Build agent:** Claude Sonnet 4.6 (Thinking) inside Antigravity
**Target:** Implement Agent 1 using Google ADK, verified via test harness against Gemini + Supabase.

## Build-time reasoning steps observed

### Step 1 — Read source-of-truth files
- `STRUCTURE.md` (project layout)
- `backend/supabase/migrations/001_init_schema.sql` (column names — `agent_traces.reasoning`, `agent_traces.output_data`, etc.)
- `backend/app/agents/prompts/classifier.md` (verbatim prompt for the runtime agent)
- `backend/app/services/supabase_client.py` (singleton + helper signatures)

### Step 2 — Define Pydantic schema (first attempt)
Used standard Pydantic v2 idioms:
```python
estimated_value_pkr: float = Field(gt=0, ...)
key_requirements: list[str] = Field(min_length=1, ...)
```

### Step 3 — Build ADK Agent + Runner
- `Agent(name=..., model="gemini-2.5-flash", instruction=CLASSIFIER_PROMPT, output_schema=ClassificationOutput, output_key="classification")`
- Wrapped in `Runner` with `InMemorySessionService`
- Created an `async def classify_brief(job_id, brief)` helper that writes a "start" trace, runs the agent, parses the structured output, writes a "complete" trace.

### Step 4 — First test run failed
Gemini API rejected the JSON schema:
google.api_core.exceptions.InvalidArgument: 400
Extra inputs are not permitted (exclusiveMinimum, minItems)

### Step 5 — Diagnosis
Antigravity recognised that:
- `Field(gt=0)` → JSON Schema → `"exclusiveMinimum": 0`
- `Field(min_length=1)` → JSON Schema → `"minItems": 1`
- Gemini's structured-output validator does NOT accept these keywords (it follows a strict subset of JSON Schema).

### Step 6 — Patch
Removed the `Field(gt=, min_length=)` constraints from field declarations and re-implemented them as `@field_validator` methods in Python. The JSON schema sent to Gemini now contains only the basic types; validation happens after the model responds.

### Step 7 — Second test run succeeded
- Structured JSON output received from Gemini
- Pydantic validation passed (constraints enforced in Python)
- Trace rows written to Supabase
- Total round-trip latency: ~3-5 seconds for the Gemini call

## Why this is rubric-worthy
This is **multi-step autonomous reasoning**:
1. Hypothesis (use Pydantic constraints natively)
2. Observe failure
3. Trace error to root cause
4. Propose patch (move constraints to validators)
5. Re-run
6. Verify

No human intervention between steps 4 and 6. This is the exact pattern the "Agentic Reasoning & Workflow" criterion (20%) evaluates.

## Lesson learned (for downstream tasks)
For Tasks 4-6 (Auditor, Vendor Intel, Drafter), use `@field_validator` for any cross-field or value constraints on Pydantic schemas that will be passed to Gemini as `output_schema`. Do NOT use `Field(gt=, min_length=, max_length=, pattern=, ...)` for these models.