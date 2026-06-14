# Architecture

The RFP Agent System is a full-stack, multi-agent application that automates the generation of PPRA-compliant Request for Proposal documents. A FastAPI backend orchestrates a four-agent pipeline built on Google ADK and Gemini 2.5 Flash. A Flutter frontend provides real-time pipeline visibility across web and mobile.

---

## System Components

### Frontend — Flutter

| | |
|---|---|
| **Framework** | Flutter 3.41+ |
| **State management** | Riverpod 2.5 |
| **Routing** | GoRouter 14.2 |
| **Platforms** | Android APK (primary) · Web (secondary) |

The frontend polls the backend every 2 seconds via `Timer.periodic` + `StreamController` against `/rfp/status/{job_id}`, updating the agent progress UI in real time. Each agent's status (pending / running / done) and a climbing reasoning trace count are surfaced directly — no generic loading state.

The results screen renders a four-agent timeline, a PPRA compliance scorecard, a vendor shortlist, and the full audit trail with per-agent reasoning tabs. The audit trail is not a log view appended after completion — it is hydrated progressively as the pipeline runs.

---

### Backend — FastAPI + Google ADK

| | |
|---|---|
| **Framework** | FastAPI · Python 3.11 |
| **Agent framework** | Google Agent Development Kit (ADK) 1.34 |
| **LLM** | Google Gemini 2.5 Flash |
| **Validation** | Pydantic v2 |

The backend receives a procurement brief at `POST /rfp/generate`, immediately returns a `job_id`, and launches the four-agent pipeline as a background task via `asyncio.create_task`. This non-blocking pattern keeps the API responsive while the pipeline — which typically takes 2–3 minutes — executes asynchronously.

Agents are chained sequentially. Each agent's output is serialised via `.model_dump()` before being passed to the next, decoupling Pydantic schemas across agents and avoiding version coupling issues between structured outputs.

Every `function_call` and `function_response` event emitted by the ADK runtime is captured and written to the `agent_traces` table as it occurs — not batched at the end. This gives the polling frontend access to live reasoning steps mid-execution.

---

### Database — Supabase PostgreSQL

| | |
|---|---|
| **Provider** | Supabase (managed PostgreSQL) |
| **Role** | Persistent state · audit trail · seed data · configuration |

**Schema overview:**

| Table | Purpose |
|---|---|
| `rfp_jobs` | Tracks pipeline lifecycle — status, job ID, timestamps, final output references |
| `agent_traces` | One row per `function_call` + `function_response` event; tagged with agent name and step index |
| `generated_documents` | References to completed PDF artifacts |
| `sent_emails` | Record of each vendor invitation dispatched |
| `calendar_events` | Scheduled submission, opening, and evaluation dates |
| `portal_postings` | Tender publication records |
| `ppra_rules` | Regulatory lookup table consumed by the Compliance Auditor at runtime |
| `organizations` | Procurement officer organisations |
| `vendors` | Vendor registry with category tags, past performance scores, and blacklist status |

The `ppra_rules` table is the compliance backbone of the system — it is not hardcoded logic. The Compliance Auditor queries it at runtime via the `lookup_ppra_rules` tool, which means regulatory rules can be updated without touching agent code.

---

## Agent Pipeline

Agents execute strictly sequentially. Each agent's structured output is required input for the next — parallel execution is architecturally incorrect for this problem because the Compliance Auditor cannot determine the correct bidding method until the Classifier has established the procurement category and value tier, and the Drafter cannot synthesise the document until compliance has been confirmed and vendors have been ranked.

---

### Agent 1 — Requirements Classifier

**Input:** Raw 4-sentence procurement brief (natural language)

**Output:** Structured classification — procurement category, value tier, delivery timeline, key technical requirements, applicable PPRA thresholds

**Method:** LLM reasoning with structured Pydantic output schema. No external tool calls — this agent operates entirely on the brief itself.

**Why this runs first:** All downstream agents depend on the classification. The Compliance Auditor needs the category and value to select the correct bidding method. The Vendor Intelligence agent needs the category to query eligible vendors. Getting this right is the foundation of the entire pipeline.

---

### Agent 2 — Compliance Auditor

**Input:** Classifier output

**Output:** PPRA bidding method selection, compliance score (0–100), identified compliance gaps, mandatory clause list

**Tools:**
- `lookup_ppra_rules` — queries the `ppra_rules` table for rules applicable to the classified category and value tier

**Why this runs second:** PPRA compliance is non-negotiable. A procurement document that fails compliance is legally void regardless of its content quality. Running the audit before drafting means the Drafter works from a compliance-confirmed brief, not a post-hoc correction.

---

### Agent 3 — Vendor Intelligence

**Input:** Classifier output + Compliance Auditor output

**Output:** Ranked vendor shortlist (top 5), predicted bid range, conflict of interest flags, blacklist exclusions

**Tools:**
- `query_vendors` — queries the vendor registry filtered by category and eligibility
- `run_conflict_check` — flags vendors with relationships to the procuring organisation
- `predict_bid_range` — estimates expected bid range based on category, value tier, and historical vendor data

**Why this runs third:** Vendor selection is downstream of compliance — the correct vendor pool depends on the PPRA bidding method selected by the Auditor, which determines advertisement thresholds and eligible supplier categories.

---

### Agent 4 — Drafter & Executor

**Input:** All previous agent outputs

**Output:** Complete RFP document (PDF), dispatched vendor emails, scheduled calendar events, portal posting

**Tools:**
- `generate_rfp_pdf` — synthesises the full RFP body using all upstream outputs and renders to PDF via `reportlab`
- `send_invitation_email` — dispatches personalised invitation emails to each selected vendor via Resend
- `create_calendar_event` — schedules submission deadline, bid opening date, and evaluation date
- `post_to_portal` — publishes the tender reference to the procurement portal

**Why this runs last:** The Drafter is the integration point for everything upstream. It requires the classification (to determine document structure), the compliance output (to insert mandatory clauses and the correct bidding method), and the vendor list (to address invitations and populate the vendor section). Running it last is the only valid order.

---

## Data Flow

```
User submits brief
        │
        ▼
POST /rfp/generate
        │
        ├── Returns job_id immediately (non-blocking)
        │
        └── asyncio.create_task(run_pipeline)
                    │
                    ▼
            Agent 1: Classifier
            writes traces to agent_traces
                    │
                    ▼
            Agent 2: Compliance Auditor
            queries ppra_rules
            writes traces to agent_traces
                    │
                    ▼
            Agent 3: Vendor Intelligence
            queries vendors table
            writes traces to agent_traces
                    │
                    ▼
            Agent 4: Drafter & Executor
            generates PDF → generated_documents
            sends emails → sent_emails
            creates events → calendar_events
            posts tender → portal_postings
            writes traces to agent_traces
                    │
                    ▼
            rfp_jobs.status = 'completed'

Flutter polls GET /rfp/status/{job_id} every 2 seconds
throughout execution, updating agent status and
reasoning trace count in real time.
```

---

## Error Handling

Any unhandled exception within an agent writes a terminal trace record to `agent_traces` with the error payload, sets `rfp_jobs.status` to `'failed'`, and surfaces a structured error response to the polling frontend. The frontend displays a user-facing error state with the failure point identified — which agent failed and at which step — rather than a generic error screen.

This design ensures the audit trail is complete even for failed runs, which is a PPRA compliance requirement: procurement decisions — including failed automated attempts — must be auditable.

---

## Deployment

| Component | Platform |
|---|---|
| Backend (FastAPI) | Railway |
| Web frontend | Netlify |
| Database | Supabase (managed) |
| Mobile | Android APK — [v2.0.0 release](https://github.com/rubaisha-rn/RFP-Agent/releases/tag/v2.0.0) |
