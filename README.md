# RFP Agent System

> PPRA-compliant procurement automation for the Government of Pakistan, built as a multi-agent Google ADK pipeline with a Flutter mobile frontend.

**Hackathon Submission • May 2026**

---

## Demo Links

- **🌐 Live Mobile App (Flutter Web):** (https://rfp-agent-system.netlify.app/)
- **⚙️ Live Backend API:** (https://rfp-agent-system-production.up.railway.app/docs/)
- **📦 Source Repository:** (https://github.com/dina-khan/rfp-agent-system)
- **📱 Android APK Download:** `releases/rfp_agent_app.apk` (in this repo)
- **🎥 Demo Video (3-5 min):** 
- **🤖 Antigravity Usage Video (2-3 min):** 

---

## The Problem

Pakistan's Public Procurement Regulatory Authority (PPRA) requires every government RFP to comply with PPRA Rule 36 (Single Stage, Two-Envelope, etc.), Rule 4 (advertisement thresholds), and Rule 33 (integrity pacts for high-value procurements). Procurement officers spend **4-8 hours** drafting a single compliant RFP, and inconsistent rule application leads to procedural rejections and audit findings.

## The Solution

RFP Agent reduces RFP drafting from hours to **~3 minutes** through four autonomous AI agents working in sequence:

| Agent | Role | Tools Used |
|---|---|---|
| **Classifier** | Extracts procurement category, value, timeline, and key requirements from a 4-sentence brief | LLM reasoning + structured output |
| **Compliance Auditor** | Determines correct PPRA bidding method, validates integrity pact + advertisement requirements, computes compliance score | `lookup_ppra_rules` tool → live Supabase query |
| **Vendor Intelligence** | Ranks 5 best vendors from the database, predicts bid range, filters blacklisted vendors, flags soft conflicts | `query_vendors`, `run_conflict_check`, `predict_bid_range` |
| **Drafter & Executor** | Synthesises final RFP body, generates PDF, dispatches invitation emails, schedules deadlines, posts to PPRA portal | `generate_rfp_pdf`, `send_invitation_email`, `create_calendar_event`, `post_to_portal` |

Every reasoning step + every tool call is persisted to Supabase as an audit trail.

---

## Architecture
┌─────────────────────────────┐
│  Flutter Mobile (web + APK) │
│  • Splash → Signup → Brief  │
│  • Live progress (polling)  │
│  • Preview → Vendors → Send │
│  • Results dashboard        │
└──────────────┬──────────────┘
│ HTTPS
┌──────────────▼──────────────┐
│  FastAPI Backend (Railway)  │
│  • /auth /rfp /contacts     │
│  • Async orchestrator       │
│  • CORS-enabled             │
└──────────────┬──────────────┘
│
┌──────────────▼─────────────────────────────────┐
│  Google ADK Multi-Agent Pipeline               │
│  Classifier → Auditor → Vendor Intel → Drafter │
│  Model: gemini-2.5-flash (paid tier)           │
└──────────────┬─────────────────────────────────┘
│
┌──────────────▼──────────────────────────────────┐
│  Supabase (Postgres)                            │
│  9 tables: organizations, vendors, rfp_jobs,    │
│  agent_traces, generated_documents, sent_emails,│
│  calendar_events, portal_postings, ppra_rules   │
└─────────────────────────────────────────────────┘

### Tech Stack

- **Backend:** Python 3.11, FastAPI, Google ADK 1.34, Pydantic v2, Supabase Python SDK, reportlab (PDF), bcrypt (auth)
- **Frontend:** Flutter 3.41 (web + Android targets), Riverpod 2.5, GoRouter 14.2, Google Fonts (Inter)
- **Database:** Supabase Postgres with Row-Level Security
- **LLM:** Google Gemini 2.5 Flash via Google ADK
- **Build IDE:** Google Antigravity (autonomous coding agent — see `antigravity_artifacts/`)
- **Hosting:** Railway (backend), Netlify (frontend)

---

## How It Works — One Example

**Input** (4 sentences from a procurement officer):

> "We need a digital citizen services portal for the Punjab government, with cloud hosting, Urdu and English support, NADRA integration. Budget around 2.5 million PKR, 90 day timeline."

**What happens in ~3 minutes:**

1. **Classifier** extracts: `category=IT_services`, `value=2,500,000 PKR`, `timeline=90 days`, 4 key requirements.
2. **Auditor** consults `ppra_rules` table → corrects bidding method to `single_stage_one_envelope` per PPRA-R36(a), sets integrity pact = false (under 10M threshold), compliance score = 85.
3. **Vendor Intel** ranks 5 top vendors (TechNova 4.85, Innovate Systems 4.57, Apex Tech 4.50, Digital Sphere 4.47, Quantum IT 4.44 with soft flag for pending litigation), predicts bid range PKR 1.9M–3.0M (median 2.4M).
4. **Drafter** synthesises a complete RFP (scope, eligibility, evaluation criteria with 60/30/10 weights, mandatory PPRA clauses, dates, contact info), generates a real PDF, sends 5 vendor invitation emails, creates 3 calendar events (pre-bid + submission + opening), posts to PPRA portal with reference `PPRA-2026-0519-2277F5`.

**Output:** Real PDF on disk + 10 database rows across 4 action tables + 54 reasoning trace rows.

---

## Repository Structure
rfp-agent-system/
├── backend/                       FastAPI + Google ADK pipeline
│   ├── app/
│   │   ├── agents/                # 4 ADK agents + orchestrator
│   │   ├── api/                   # /auth /rfp /contacts /documents
│   │   ├── services/              # supabase_client, job_manager
│   │   └── tools/                 # PDF, email, calendar, portal, vendor_db
│   ├── supabase/migrations/       # schema + seed data
│   ├── output/rfp_pdfs/           # generated PDFs
│   ├── requirements.txt
│   └── Procfile
│
├── mobile/                        Flutter mobile app
│   ├── lib/
│   │   ├── core/                  # ApiClient, theme, constants
│   │   ├── models/                # Organization, RfpResult, JobStatus, Vendor
│   │   ├── services/              # auth_service, rfp_service (Riverpod)
│   │   ├── screens/
│   │   │   ├── onboarding/        # signup, account setup
│   │   │   └── rfp/               # 6-screen RFP flow + dashboard
│   │   ├── widgets/               # primary_button, labeled_field
│   │   └── app.dart               # GoRouter
│   └── pubspec.yaml
│
├── antigravity_artifacts/         Build evidence for rubric
│   ├── workplans/                 # 10 task plans (one per build task)
│   ├── reasoning_traces/          # how Antigravity reasoned
│   ├── task_lists/                # per-task checklists
│   ├── walkthroughs/              # narrative walkthroughs + .webp recordings
│   └── screenshots/               # 45+ screenshots
│
├── releases/
│   └── rfp_agent_app.apk          # Android build
│
└── README.md

---

## Running Locally

### Prerequisites
- Python 3.11.9, Node.js LTS, Flutter 3.41+, Git
- A Supabase project (free tier)
- A Google AI Studio API key (free tier or Tier 1 paid for stable runs)

### Backend setup

```bash
git clone https://github.com/dina-khan/rfp-agent-system.git
cd rfp-agent-system/backend
python -m venv .venv
.venv\Scripts\Activate.ps1   # Windows
# source .venv/bin/activate  # macOS/Linux
pip install -r requirements.txt
```

Create `backend/.env` (see `.env.example` for the template):
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
GOOGLE_API_KEY=...
APP_SECRET=any-random-32-chars

Run database migrations and seeds:
```bash
# In Supabase SQL editor, run files in:
# backend/supabase/migrations/001_init_schema.sql
# backend/supabase/migrations/002_seed_data.sql
```

Start the server:
```bash
python -m uvicorn app.main:app --reload --port 8000
```

Visit: `http://localhost:8000/docs` for Swagger UI.

### Mobile setup

```bash
cd mobile
flutter pub get
```

Edit `lib/core/constants.dart` if your backend isn't on `localhost:8000`.

Run for web:
```bash
flutter run -d chrome --web-port 5000
```

Run for Android (emulator or USB-connected device):
```bash
flutter run -d <device_id>
```

Build Android APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Rubric Mapping

This project was built end-to-end inside Google Antigravity IDE — the `antigravity_artifacts/` folder contains workplans, reasoning traces, task lists, and walkthroughs covering each build phase. Highlights:

### Use of Antigravity (25%)
- **10 task-by-task build sessions** in Antigravity, each with a workplan + reasoning trace + checklist artifact.
- **Autonomous debugging cycles**: e.g., the Compliance Auditor needed 3 closed-loop cycles to fix an ADK `output_schema + tools` constraint without re-prompting; the Drafter agent reused that same insight autonomously. The Results Dashboard task included autonomous PowerShell port-conflict resolution (`Stop-Process -Id 32932`) before applying a null-safety fix at the exact code line.
- **Browser-driven verification**: Antigravity used its built-in browser tool to drive a real Chrome instance through the onboarding flow, fix a regex bug it found during testing, and produce a `.webp` recording of the session.

### Agentic Reasoning & Workflow (20%)
- 4 distinct ADK agents with structured Pydantic schemas, deterministic tool ordering, and per-event trace persistence.
- The orchestrator chains agents via `asyncio.create_task` (architectural decision documented in `antigravity_artifacts/reasoning_traces/orchestrator_decisions.md` — Antigravity surfaced the `BackgroundTasks` vs `create_task` tradeoff and asked for approval before implementing).
- Failure handling: any agent exception writes a trace with `agent_name` and marks `rfp_jobs.status='failed'`, surfaced to the UI as a friendly error card.

### Insight Quality (20%)
- Outputs grounded in real Supabase data: PPRA rules table feeds compliance decisions, vendor database with past performance scores drives shortlisting.
- The mobile dashboard surfaces the full 54-row reasoning audit trail with per-agent colour-coded badges — every decision is auditable.

### Action Simulation & Outcome (15%)
- One successful run produces **a real PDF on disk + 10 rows across 4 action tables** (1 generated_documents, 5 sent_emails, 3 calendar_events, 1 portal_postings) plus ~50 agent_traces.
- The mobile app's Results Dashboard surfaces each action with expandable detail and a working PDF download button.

### Technical Implementation (10%)
- Clean architectural separation (agents / tools / services / api in backend; core / models / services / screens / widgets in Flutter).
- Typed Pydantic schemas everywhere; Riverpod for state on the frontend.
- Live polling via stream controllers with proper termination.
- Deployed to public cloud (Railway + Netlify); Android APK in `releases/`.

### Innovation & UX (10%)
- Live agent-by-agent progress UI with a climbing reasoning trace count — judges see the system "think" in real time.
- The 4-dot agent timeline + colour-coded trace audit trail visually communicate the agentic architecture in a way that's uncommon for procurement software.
- PPRA-specific defaults (Pakistani vendors, PKR currency, Urdu-language considerations in scope synthesis).

---

## Notes on the App Target

This project ships as both a **Flutter Web build** (the live demo URL above, what judges will click first) and an **Android APK** (`releases/rfp_agent_app.apk`, what proves the mobile claim is real). Both come from the same Dart codebase under `mobile/`. Web was chosen as the primary submission link for instant judge access (no APK install / device setup). The Android app was tested on ...

## Notes on Live Pipeline Runs

The pipeline calls Google Gemini 2.5 Flash, which is on a paid Tier-1 quota for stable runs but occasionally returns transient 503s during global high-traffic windows. The orchestrator handles these gracefully (`rfp_jobs.status='failed'` + trace row). For the demo, a known-good completed job exists at reference `PPRA-2026-0519-2277F5` (job_id `9ef366ca-153f-4cd3-8139-6576a8b59ff3`) with all 4 action tables populated — accessible from the live app's Results Dashboard.

---

## Acknowledgments

Built for the hackathon by Noor Fatima, Dina Khan, and Rubaisha Nadeem in Islamabad, Pakistan. Special thanks to the Google ADK and Antigravity teams for the tooling that made this possible in 3 days.

---