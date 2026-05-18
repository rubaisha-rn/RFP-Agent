# Agent 1 (Classifier) — Task Checklist (executed by Antigravity)

- [x] Read STRUCTURE.md
- [x] Read 001_init_schema.sql (verify column names: agent_traces.reasoning, .output_data, .tool_called, .tool_input, .tool_output)
- [x] Read classifier.md (load runtime prompt)
- [x] Read existing supabase_client.py (find `write_trace` signature)
- [x] Implement classification.py Pydantic schema (8 fields)
- [x] Implement agent1_classifier.py with ADK Agent + Runner + classify_brief() helper
- [x] Add list_traces(job_id) method to supabase_client.py
- [x] Add `if __name__ == "__main__"` test harness using a Punjab demo brief
- [x] Run test harness — observed Gemini schema rejection
- [x] DIAGNOSE: Pydantic `Field(gt=, min_length=)` emit unsupported JSON Schema keywords
- [x] PATCH: Move constraints to @field_validator methods
- [x] Re-run test harness — passed
- [x] Verify Supabase agent_traces rows written (step 1 + step 2)
- [x] Report results back to user with full JSON + trace table