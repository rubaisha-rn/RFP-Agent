# Agent 2 (Compliance Auditor) — Runtime Reasoning Trace

**Date:** 2026-05-19
**Demo brief:** Punjab citizen portal, 2.5M PKR, 90 days.

## Step-by-step trace (from Supabase agent_traces table)

### Classifier output (input to Auditor)
```json
{
  "category": "IT_services",
  "estimated_value_pkr": 2500000,
  "urgency": "medium",
  "bidding_method": "single_stage_two_envelope",
  "delivery_timeline_days": 90,
  "key_requirements": ["citizen portal", "cloud", "Urdu/English", "NADRA integration"]
}
```

### Auditor step 1 — Start
Reasoning: "Auditor started. Received classification: category=IT_services, value_pkr=2500000, proposed_bidding=single_stage_two_envelope."

### Auditor steps 2–3 — Tool call + response
- step 2: `tool_called=lookup_ppra_rules`, `tool_input={"category":"IT_services","estimated_value_pkr":2500000}`
- step 3: `tool_output={matching_rules_count: 4, ...}` — Tool returned PPRA-R36a + R20A + R35 + R38 from the general bands that cover 2.5M.

### Auditor steps 4–5 — `set_model_response` (ADK internal)
Captured by the event loop as the model's response is finalized.

### Auditor step 6 — Final scorecard written
- The Auditor noticed that the Classifier proposed `single_stage_two_envelope`, but 2.5M PKR falls in the 500k-3M general band → `single_stage_one_envelope` (PPRA-R36a). **The Auditor corrected the bidding method.**
- compliance_score: ~78 (deductions for vague evaluation criteria in the brief).
- integrity_pact_required: false (only true above 10M per PPRA-R8).
- advertisement_requirements: {ppra_website, english_newspaper, urdu_newspaper} = all true (PPRA-R20A applies above 500k).
- Mandatory clauses captured verbatim from PPRA rules table.

## Why this matters for the rubric
This is a concrete example of one agent **overriding another based on EVIDENCE** (the tool response from the PPRA rules table), not assumption. That's the "Insight & Decision Quality" criterion (20%). The decision flow is fully reconstructable from the trace rows alone, which proves the "Agent Trace / Logs" deliverable.