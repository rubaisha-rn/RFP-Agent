# RFP Agent System

> Multi-agent AI procurement automation — generating PPRA-compliant Request for Proposal documents from a 4-sentence brief in under 3 minutes.

[![Live App](https://img.shields.io/badge/Live%20App-Netlify-00C7B7?style=flat&logo=netlify)](https://rfp-agent-system.netlify.app)
[![Backend API](https://img.shields.io/badge/API%20Docs-Swagger-85EA2D?style=flat&logo=swagger)](https://rfp-agent-system-production.up.railway.app/docs)
[![Android APK](https://img.shields.io/badge/Android%20APK-v2.0.0-3DDC84?style=flat&logo=android)](https://github.com/rubaisha-rn/RFP-Agent/releases/tag/v2.0.0)

---

## Overview

Government procurement in Pakistan is slow, manual, and compliance-heavy. Every Request for Proposal must conform to PPRA (Pakistan Public Procurement Regulatory Authority) regulations — covering bidding methods, advertisement thresholds, vendor eligibility, and mandatory integrity clauses. A single compliant RFP takes a procurement officer 4–8 hours to draft. Inconsistent rule application leads to procedural rejections and audit failures.

RFP Agent System solves this with a four-agent sequential AI pipeline. A procurement officer writes four sentences describing their need. Four specialised Gemini 2.5 Flash agents — a Requirements Classifier, a Compliance Auditor, a Vendor Intelligence engine, and a Drafter & Executor — work sequentially through classification, compliance verification, vendor shortlisting, and document drafting. The output is a complete, PPRA-compliant RFP package dispatched directly to verified vendors, with every agent reasoning step and tool call persisted to a database as a fully auditable trail.

The system serves two user types — procurement officers and vendors — through role-based mobile and web interfaces built in Flutter and React respectively.

---

## Features

**Procurement Officer**
- Write a 4-sentence procurement brief; the system handles everything else
- Live agent progress display — see each agent's status in real time as the pipeline runs
- Preview the generated RFP before dispatch — full document with scope, eligibility criteria, evaluation criteria, and mandatory PPRA clauses
- Download as PDF or dispatch directly to selected vendors
- Complete reasoning audit trail — every agent decision, tool call, and output logged and viewable

**Vendor**
- Browse all active RFPs matching your registration category
- View and download full RFP documents
- Submit bids with bid amount and technical summary
- Track bid status across all active procurements

---

## Architecture

### The 4-Agent Pipeline

Agents execute sequentially — each agent's output is the next agent's input. No agent begins until the previous one completes.

| Agent | Role | Tools |
|---|---|---|
| **Requirements Classifier** | Extracts procurement category, value tier, timeline, and key requirements from the brief | LLM reasoning + structured Pydantic output |
| **Compliance Auditor** | Selects the correct PPRA bidding method; computes a compliance score against regulatory rules | `lookup_ppra_rules` |
| **Vendor Intelligence** | Ranks eligible vendors by past performance and eligibility; predicts bid range; filters blacklisted companies | `query_vendors`, `run_conflict_check`, `predict_bid_range` |
| **Drafter & Executor** | Synthesises the complete RFP document, generates PDF, dispatches emails, schedules deadlines, posts to procurement portal | `generate_rfp_pdf`, `send_invitation_email`, `create_calendar_event`, `post_to_portal` |

All agents run on **Google Gemini 2.5 Flash** via Google ADK. Every `function_call` and `function_response` event is persisted to Supabase as a structured trace record, enabling full post-run auditability.

A single successful run produces:
- 1 generated PDF document
- ~5 vendor invitation emails sent
- ~3 calendar events scheduled (submission deadline, opening date, evaluation date)
- 1 portal posting published
- ~50 agent trace records across 4 agents

### System Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter · Dart · Riverpod · GoRouter |
| Web frontend | React · Vite · Netlify |
| Backend | FastAPI · Python · Google ADK · Google Gemini 2.5 Flash |
| Database & auth | Supabase · PostgreSQL |
| Deployment | Railway (backend) · Netlify (web) |

### Repository Structure

```
RFP-agent/
├── backend/
│   ├── app/
│   │   ├── agents/          # 4 Gemini 2.5 Flash ADK agents
│   │   ├── api/             # REST endpoints
│   │   ├── services/        # Supabase & job handlers
│   │   ├── tools/           # Tool definitions for each agent
│   │   └── config.py        # Environment configuration
│   ├── supabase/
│   │   └── migrations/      # Schema SQL + seed data
│   └── requirements.txt
│
├── mobile/
│   ├── lib/
│   │   ├── core/            # Constants, theme, API client
│   │   ├── models/          # Dart data models
│   │   ├── screens/         # Onboarding, dashboard, RFP generation flow
│   │   ├── services/        # Auth and business logic
│   │   └── widgets/         # Reusable components
│   └── pubspec.yaml
│
├── ARCHITECTURE.md
└── README.md
```

---

## Getting Started

### Option 1 — Live Web App (Recommended)

The fastest way to see the system in action:

1. Visit [rfp-agent-system.netlify.app](https://rfp-agent-system.netlify.app)
2. Sign up with any email address
3. Select the **Procurement Officer** role
4. Use the **Demo Brief** autofill to populate a sample procurement need
5. Tap **Generate RFP** to watch the multi-agent pipeline run live

### Option 2 — Android APK

To run the app natively on an Android device:

1. Download the APK from the [v2.0.0 release](https://github.com/rubaisha-rn/RFP-Agent/releases/tag/v2.0.0)
2. Transfer to your Android device and install (enable *Install from Unknown Sources* if prompted)
3. Launch **RFP Agent** and follow the same steps above

### Option 3 — Run Locally

**Prerequisites:** Python 3.11+, a Supabase project (free tier), a Google AI Studio API key, a Resend API key.

**1. Clone and set up the backend:**

```bash
git clone https://github.com/rubaisha-rn/RFP-Agent.git
cd RFP-agent/backend
python -m venv .venv

# Windows
.venv\Scripts\Activate.ps1

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
```

**2. Create a `.env` file in the `backend/` directory:**

```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GOOGLE_API_KEY=your-gemini-api-key
RESEND_API_KEY=your-resend-api-key
APP_SECRET=any-random-32-character-string
```

**3. Initialise the database:**

Run both SQL files in `backend/supabase/migrations/` in your Supabase SQL Editor in order. This creates the 9-table schema and seeds the vendor and PPRA rules data.

**4. Start the server:**

```bash
python -m uvicorn app.main:app --reload --port 8000
```

Swagger API documentation is available at [http://localhost:8000/docs](http://localhost:8000/docs).

**5. Connect the Android app to your local backend (optional):**

If running the Flutter app against your local backend:

```bash
# Forward the backend port to the Android emulator or device
$env:Path += ";$HOME\AppData\Local\Android\Sdk\platform-tools"
adb reverse tcp:8000 tcp:8000
```

The app will connect to `http://localhost:8000`.

---

## Design Decisions

**Sequential over parallel agent execution**
Each agent's output is structurally required by the next — the Compliance Auditor cannot select a PPRA bidding method until the Classifier has determined the procurement category and value. Parallel execution would require each agent to operate on incomplete information. Sequential chaining is the correct architecture for this problem.

**Transparent AI pipeline UI**
The generation screen shows each agent's live status (Done / Running / Pending) and a running count of logged reasoning steps rather than a generic loading indicator. Government procurement requires trust — a black box that produces a document is not sufficient. A visible pipeline that shows its work is.

**Dual colour systems for dual roles**
Procurement officers see navy and blue throughout. Vendors see green. The distinction is immediate, persistent, and appears from the first screen after login. In a two-sided platform where the wrong action by the wrong role carries legal consequences, visual role clarity is a functional requirement, not an aesthetic choice.

**Regulatory constraints as UI constraints**
PPRA regulations make bids irrevocable once submitted. The bid submission interface states this explicitly before the action is taken — not in terms and conditions, but in the UI itself, adjacent to the submit button. The legal constraint becomes an interaction design constraint.

**Full auditability as a core feature**
The reasoning trace audit — per-agent tabs showing every tool call and decision step — is not supplementary logging. It is a product requirement. Government procurement decisions must be explainable and reviewable. The audit trail makes this possible without any additional tooling.

---

## Contributors

Built by Noor Fatime, [Dina Khan](https://github.com/dina-khan), and [Rubaisha Nadeem](https://github.com/rubaisha-rn).
