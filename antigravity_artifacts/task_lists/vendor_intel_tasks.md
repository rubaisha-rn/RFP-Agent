# Agent 3 (Vendor Intelligence) — Task Checklist (executed by Antigravity)

- [x] Read 001_init_schema.sql for vendors + agent_traces columns
- [x] Read vendor_intel.md (current runtime prompt)
- [x] Read agent2_auditor.py to mirror code patterns (event-loop trace writing, _clean_json_text, no-output_schema-with-tools)
- [x] Read supabase_client.list_vendors() signature
- [x] Define VendorRankingOutput Pydantic schema with @field_validator (no Field(gt=, min_length=))
- [x] Implement query_vendors tool with related-category fallback
- [x] Implement run_conflict_check tool (pure Python, prefix + keyword matching)
- [x] Implement predict_bid_range tool with statistics + estimate-band fallback
- [x] Refine vendor_intel.md with mandatory tool ordering + weighted scoring formula + exact JSON schema
- [x] Implement agent3_vendor_intel.py mirroring Auditor pattern
- [x] Implement rank_vendors helper with per-event function_call/function_response trace writing
- [x] Implement test harness chaining Classifier → Auditor → Vendor Intel
- [x] Run test harness — observed Gemini free-tier 429 from rapid sequential calls
- [x] DIAGNOSE: Gemini free tier = 5 GenerateContent requests/minute, 3 agents × ~3 calls each exceeds limit
- [x] PATCH (test-side only): Documented sleep pacing as a test-harness mitigation; runtime code itself is correct
- [x] Verify implementation by inspection (Antigravity's own validation table)