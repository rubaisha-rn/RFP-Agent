# Agent 2 (Auditor) — Task Checklist (executed by Antigravity)

- [x] Read 001_init_schema.sql for ppra_rules + agent_traces columns
- [x] Read auditor.md (runtime prompt)
- [x] Read agent1_classifier.py to mirror code patterns
- [x] Read existing supabase_client.get_ppra_rules() signature
- [x] Define ComplianceOutput Pydantic schema with @field_validator (no Field(gt=, min_length=))
- [x] Implement lookup_ppra_rules tool function (filters by category + threshold range)
- [x] Define ADK Agent with tools=[lookup_ppra_rules]
- [x] Implement audit_classification helper with per-event trace writing (function_call + function_response = 2 trace rows per tool invocation)
- [x] Implement test harness chaining Classifier -> Auditor
- [x] Run test harness — observed advertisement_requirements type mismatch
- [x] DIAGNOSE: prompt example showed field as string, not dict
- [x] PATCH: add @field_validator coercer + update auditor.md
- [x] Re-run — discovered non-canonical keys (`media`, `website`)
- [x] DIAGNOSE: prompt referenced outdated field names (rule_codes, mandatory_bidding_method)
- [x] PATCH: sync prompt with current schema, harden validator to drop non-canonical keys
- [x] Verify final JSON parses, bidding_method corrected, 8 trace rows in Supabase
- [x] Note: final re-verification run hit Gemini transient 503 + free-tier quota exhaustion; prior pass run had already validated correctness.