# RFP Agent System

> A multi-agent procurement automation system for the Government of Pakistan, generating PPRA-compliant Request-for-Proposal documents from a 4-sentence brief in under 3 minutes.

**Hackathon Submission — May 2026**

---

## 🔗 Submission Links

| What | Link |
|---|---|
| 🌐 Live Mobile App (Flutter Web) | https://rfp-agent-system.netlify.app |
| ⚙️ Live Backend API (Swagger) | https://rfp-agent-system-production.up.railway.app/docs |
| 📦 Source Code (GitHub) | https://github.com/dina-khan/rfp-agent-system |
| 📱 Android APK | `releases/rfp_agent_app.apk` (in this repo) |
| 🎥 Demo Video (3-5 min) | _(YouTube link added in submission form)_ |
| 🤖 Antigravity Usage Video (2-3 min) | _(YouTube link added in submission form)_ |
| 📁 Antigravity Build Artifacts | `antigravity_artifacts/`  |

---

## 🎯 The Problem

Pakistan's Public Procurement Regulatory Authority (PPRA) mandates that every government RFP comply with detailed rules covering bidding methods (Rule 36), advertisement thresholds (Rule 4), and integrity pacts for high-value procurements (Rule 33). Procurement officers spend **4-8 hours** drafting a single compliant RFP, and inconsistent rule application leads to procedural rejections and audit findings.

## 💡 The Solution

A multi-agent system that takes a procurement officer's 4-sentence brief and produces a complete, compliant RFP package in ~3 minutes. Four AI agents work sequentially through reasoning, compliance audit, vendor selection, and document drafting — with every reasoning step and every tool call persisted to a database as an auditable trail.

| Agent | Role | Tools |
|---|---|---|
| **Classifier** | Extracts category, value, timeline, key requirements from brief | LLM reasoning + structured output |
| **Compliance Auditor** | Selects correct PPRA bidding method; computes compliance score | `lookup_ppra_rules` |
| **Vendor Intelligence** | Ranks 5 vendors; predicts bid range; filters blacklisted; flags conflicts | `query_vendors`, `run_conflict_check`, `predict_bid_range` |
| **Drafter & Executor** | Synthesises RFP, generates PDF, sends emails, schedules deadlines, posts to portal | `generate_rfp_pdf`, `send_invitation_email`, `create_calendar_event`, `post_to_portal` |

---

## 🏛️ Architecture
┌─────────────────────────────────────────┐<br>
  &nbsp; <b>Flutter Mobile App (Web + APK)</b><br>
  &nbsp; Splash → Signup → Brief Input →       <br>
  &nbsp; Live Progress → Preview → Vendor      <br>
  &nbsp; Select → Send → Success → Dashboard  <br>
└──────────────────┬──────────────────────┘<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nb&nbsp;sp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│ HTTPS REST<br>
┌──────────────────▼──────────────────────┐<br>
&nbsp;<b>FastAPI Backend </b>                       <br>
&nbsp;/auth /rfp /contacts /documents        <br>
&nbsp;Async orchestrator (asyncio.create_task)<br>
└──────────────────┬──────────────────────┘<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│<br>
┌──────────────────▼──────────────────────┐<br>
&nbsp;  Google ADK Multi-Agent Pipeline        <br>
&nbsp;  Classifier → Auditor → Vendor → Drafter<br>
&nbsp;  Model: gemini-2.5-flash                <br>
└──────────────────┬──────────────────────┘<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│<br>
┌──────────────────▼──────────────────────┐<br>
&nbsp;  Supabase Postgres (9 tables)           <br>
&nbsp;  organizations · vendors · rfp_jobs ·   <br>
&nbsp;  agent_traces · generated_documents ·   <br>
&nbsp;  sent_emails · calendar_events ·        <br>
&nbsp;  portal_postings · ppra_rules           <br>
└─────────────────────────────────────────┘<br>
### Stack

- **Backend:** Python 3.11, FastAPI, Google ADK 1.34, Pydantic v2, Supabase SDK, reportlab (PDF), bcrypt
- **Frontend:** Flutter 3.41 (Web + Android), Riverpod 2.5 (state), GoRouter 14.2 (routing), Google Fonts
- **Database:** Supabase Postgres
- **LLM:** Google Gemini 2.5 Flash via Google ADK
- **Build IDE:** Google Antigravity (the project was built end-to-end inside Antigravity — see `antigravity_artifacts/`)
- **Hosting:** Railway (backend), Netlify (frontend web)

---

## 🛠️ Build Phases - Task-by-Task Breakdown

The project was built as a sequence of tasks inside Google Antigravity. Each task produced a workplan, reasoning trace, task checklist, and screenshots — all saved under `antigravity_artifacts/`.

### Task 1 — First Antigravity Run
Verified the IDE-as-agent workflow with a small initial test (parse a brief, return JSON). Established the artifact-saving discipline used in every subsequent task.
- `antigravity_artifacts/workplans/00_first_test_run.md`

### Task 2 — Backend Scaffold + Supabase
Set up the `backend/` directory, FastAPI base modules, requirements, env templates. Designed and applied the 9-table Supabase schema with seed data (12 vendors — including 1 blacklisted and 1 soft-flagged — and 10 PPRA rules covering all bidding-method thresholds). Fixed a column-name bug autonomously (`is_blacklisted` → `blacklisted`).
- `antigravity_artifacts/workplans/01_scaffold_backend_plan.md`
- `antigravity_artifacts/workplans/02_supabase_and_prompts_plan.md`
- `antigravity_artifacts/screenshots/02_backend_scaffold_complete.png`, `03_task2_supabase_prompts.png`, `04_task2_bugfix_diff.png`

### Task 3 — Agent 1: Classifier
Built the first ADK runtime agent. Extracts category, value, timeline, key requirements from a free-text brief. Antigravity autonomously fixed a Pydantic-vs-Gemini schema validator mismatch (`Field(gt=...)` → `@field_validator`).
- `antigravity_artifacts/workplans/03_agent1_classifier_plan.md`
- `antigravity_artifacts/reasoning_traces/01_agent1_classifier_trace.md`
- `antigravity_artifacts/screenshots/05_classifier_output.png`, `06_task3_autonomous_bugfix.png`, `07_task3_supabase_traces_rows.png`

### Task 4 — Agent 2: Compliance Auditor
The hardest debugging task in the build. Antigravity discovered that ADK's `output_schema + tools` combination silently disables tool invocation. **Resolved in 3 autonomous closed-loop cycles** — Antigravity diagnosed, patched, re-tested without further prompting from the user.
- `antigravity_artifacts/workplans/04_agent2_auditor_plan.md`
- `antigravity_artifacts/reasoning_traces/02_agent2_compliance_trace.md`
- `antigravity_artifacts/task_lists/auditor_agent_tasks.md`
- `antigravity_artifacts/screenshots/09_task4_initial_diagnosis.png` through `15_task4_supabase_auditor_tool_traces.png`

### Task 5 — Agent 3: Vendor Intelligence
Ranks vendors, predicts bid range, filters blacklisted, flags soft conflicts. Antigravity reused the Auditor's lesson autonomously — no re-prompting needed. 9 tool calls per run with related-category fallback logic for sparse vendor categories.
- `antigravity_artifacts/workplans/05_agent3_vendor_intel_plan.md`
- `antigravity_artifacts/reasoning_traces/03_agent3_vendor_trace.md`
- `antigravity_artifacts/task_lists/vendor_intel_tasks.md`
- `antigravity_artifacts/screenshots/16_task5_files_implemented.png`, `17_task5_execution_results.png`, `18_task5_supabase_traces_single_job.png`, `19_task5_terminal_vendor_shortlist.png`

### Task 6 — Agent 4: Drafter & Executor
The final runtime agent. Synthesises the full RFP body, generates a real PDF via reportlab (A4, 6 sections), dispatches 5 invitation emails, creates 3 calendar events, posts to PPRA portal with auto-generated reference (`PPRA-YYYY-MMDD-XXXXX`). **One successful run produces 10 rows across 4 Supabase action tables.**
- `antigravity_artifacts/workplans/06_agent4_drafter_plan.md`
- `antigravity_artifacts/reasoning_traces/04_agent4_drafter_trace.md`
- `antigravity_artifacts/task_lists/drafter_executor_tasks.md`
- `antigravity_artifacts/screenshots/20_task6_initial_implementation.png` through `24d_task6_supabase_sent_emails.png`

### Task 7 — Orchestrator + FastAPI
Wires the 4 agents into a single async `run_pipeline()` function with 60-second pacing between agents. Exposes `POST /rfp/generate` (returns job_id in <2 sec, runs pipeline as background task via `asyncio.create_task`), `GET /rfp/status/{job_id}`, `GET /rfp/result/{job_id}`, `GET /contacts`, `POST /auth/signup` + `/auth/login` (bcrypt), `GET /documents/{id}/download` (PDF stream).

**Architectural decision captured by Antigravity:** during planning, Antigravity surfaced the `BackgroundTasks` vs `asyncio.create_task` tradeoff and asked for approval before implementing — documented in `reasoning_traces/05_task6_orchestrator_decisions.md`.
- `antigravity_artifacts/workplans/07_orchestrator_fastapi_plan.md`
- `antigravity_artifacts/reasoning_traces/05_task6_orchestrator_decisions.md`
- `antigravity_artifacts/task_lists/orchestrator_fastapi_tasks.md`
- `antigravity_artifacts/screenshots/25_task7_swagger_ui.png`, `26_task7_uvicorn_running.png`, `27_task7_swagger_live_request.png`

### Task 7A — Flutter Scaffold + Onboarding
Initialized the Flutter Web + Android app. Built Splash, Signup, and Account Setup screens with Riverpod state management and GoRouter routing. Antigravity used its **built-in browser tool** to drive a real Chrome instance through the onboarding flow, found a regex bug it had written for email `+` sub-addressing, fixed it autonomously, and produced a `.webp` recording of the session.
- `antigravity_artifacts/workplans/08_task7a_flutter_scaffolding_onboarding_plan.md`
- `antigravity_artifacts/task_lists/task7a_scaffold_onboarding_tasks.md`
- `antigravity_artifacts/walkthroughs/task7a_scaffold_onboarding_walkthrough.md`
- `antigravity_artifacts/walkthroughs/onboarding_auth_flow.webp`
- `antigravity_artifacts/screenshots/31_task7a_flutter_scaffolding_onboarding_implementation.png` through `37_task7a_supabase_signed_up_organization_rows.png`

### Task 7B — RFP Generation Flow
Built the 6-screen RFP user flow: Brief Input, Progress, Preview, Contacts Select, Confirm Send, Success. Stream-based polling via `Timer.periodic` + `StreamController` polls `/rfp/status` every 2 seconds and closes on terminal status. Live agent-by-agent progress with climbing trace count.
- `antigravity_artifacts/workplans/09_task7b_rfp_flow_plan.md`
- `antigravity_artifacts/task_lists/task7b_rfp_flow_tasks.md`
- `antigravity_artifacts/walkthroughs/task7b_rfp_flow_walkthrough.md`
- `antigravity_artifacts/screenshots/38_task7b_rfp_flow_implementation_plan.png` through `47_task7b_rfp_sent_success.png`

### Task 7C — Results Dashboard
Built the post-pipeline read-only dashboard with 5 cards: Reference Header (with 4-dot agent timeline), Compliance Scorecard, Vendor Shortlist, Actions Executed Timeline, Reasoning Audit Trail (~54 rows with per-agent colour-coded badges). PDF download via web-native `dart:html` `window.open`.

**Autonomous debugging during this task:** Antigravity identified that port 5000 was occupied by a stale Flutter process from a previous test, ran `Get-NetTCPConnection -LocalPort 5000` → `Get-Process -Id (...)` → `Stop-Process -Id 32932 -Force` to clean up, then re-launched Flutter and fixed a null-safety bug at the exact line via grep.
- `antigravity_artifacts/workplans/10_task7c_results_dashboard_plan.md`
- `antigravity_artifacts/task_lists/task7c_results_dashboard_tasks.md`
- `antigravity_artifacts/screenshots/48_task7c_rfp_vendor_results_dashboard_implementation.png` through `53_task7c_rfp_results_dashboard_agent_reasoning_aud.png`

### Final — Deployment
Railway (backend) + Netlify (frontend Flutter Web). Cleared multiple deployment-specific issues during this phase (missing Procfile, missing `email-validator`, malformed `requirements.txt`, Python version, port binding) before the backend went live.


---

## 📁 Repository Structure
rfp-agent-system/<br>
├── backend/                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>*FastAPI + Google ADK*</b><br>
│   ├── app/<br>
│   │   ├── agents/                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# 4 ADK agents + orchestrator<br>
│   │   │   ├── agent1_classifier.py<br>
│   │   │   ├── agent2_auditor.py<br>
│   │   │   ├── agent3_vendor_intel.py<br>
│   │   │   ├── agent4_drafter.py<br>
│   │   │   ├── orchestrator.py       &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# run_pipeline + kick_off_pipeline<br>
│   │   │   ├── prompts/              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# runtime prompts (.md)<br>
│   │   │   └── schemas/              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Pydantic schemas<br>
│   │   ├── api/                      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# /auth /rfp /contacts /documents<br>
│   │   ├── services/                 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# supabase_client, job_manager<br>
│   │   ├── tools/                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# PDF, email, calendar, portal, vendor_db, conflict_check, bid_predictor, ppra_rules<br>
│   │   ├── config.py<br>
│   │   └── main.py<br>
│   ├── supabase/migrations/          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# 001_init_schema.sql, 002_seed_data.sql<br>
│   ├── output/rfp_pdfs/              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# generated PDFs (gitignored except samples)<br>
│   ├── requirements.txt<br>
│   ├── Procfile                      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Railway start command<br>
│   └── .env.example<br>
│<br>
├── mobile/                           &nbsp;&nbsp;&nbsp;&nbsp; <b>*Flutter app*</b> <br>
│   ├── lib/<br>
│   │   ├── core/                     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# ApiClient, theme, constants<br>
│   │   ├── models/                   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Organization, RfpResult, JobStatus, Vendor<br>
│   │   ├── services/                 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# auth_service, rfp_service (Riverpod)<br>
│   │   ├── screens/<br>
│   │   │   ├── splash_screen.dart<br>
│   │   │   ├── onboarding/           &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# signup, account_setup<br>
│   │   │   └── rfp/                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# brief_input, progress, preview,<br>
│   │   │                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# contacts_select, confirm_send, success,<br>
│   │   │                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# result_dashboard<br>
│   │   ├── widgets/                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# primary_button, labeled_field<br>
│   │   ├── app.dart                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# GoRouter<br>
│   │   └── main.dart<br>
│   ├── android/                      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Android build config<br>
│   ├── web/                          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Web build config<br>
│   └── pubspec.yaml<br>
│<br>
├── antigravity_artifacts/           &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b> *Build evidence for rubric (100+ files)*</b><br>
│   ├── workplans/                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# task plans<br>
│   ├── reasoning_traces/             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# how Antigravity reasoned about decisions<br>
│   ├── task_lists/                   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# per-task checklists<br>
│   ├── walkthroughs/                 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# narrative .md + browser session .webp<br>
│   └── screenshots/                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# 50+ PNGs across all tasks<br>
│<br>
├── releases/<br>
│   └── rfp_agent_app.apk             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Android build<br>
│<br>
├── .gitignore<br>
└── README.md<br>

---

## 🚀 Running Locally

You will need **3 terminal windows** open simultaneously.

### Prerequisites
- Python 3.11.9
- Flutter 3.41+ with Chrome dev tools enabled (`flutter config --enable-web`)
- Node.js LTS
- Git
- A Supabase project (free tier is fine)
- A Google AI Studio API key (Google Gemini)

### Step 1 — Clone the repo

```bash
git clone https://github.com/dina-khan/rfp-agent-system.git
cd rfp-agent-system
```

### Step 2 — Set up the database

1. Create a Supabase project at https://supabase.com
2. Open the project's SQL Editor
3. Open `backend/supabase/migrations/001_init_schema.sql` from this repo, copy the contents, paste into Supabase SQL editor, run
4. Repeat for `backend/supabase/migrations/002_seed_data.sql`
5. From the Supabase project dashboard, copy your project URL and the **service_role** key (Settings → API)

### Step 3 — Backend setup

In **Terminal #1**:

```bash
cd backend
python -m venv .venv

# Activate venv
.venv\Scripts\Activate.ps1     # Windows PowerShell
# source .venv/bin/activate    # macOS / Linux

pip install -r requirements.txt
```

Create `backend/.env` (copy from `.env.example` as a template):
```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
GOOGLE_API_KEY=your-google-ai-studio-key-here
APP_SECRET=any-random-32-character-string
```

Start the FastAPI server (still in Terminal #1):

```bash
python -m uvicorn app.main:app --reload --port 8000
```

You should see:
```bash
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

**Verify backend:** open http://localhost:8000/health in your browser — should return `{"status":"ok"}`. Then http://localhost:8000/docs shows the Swagger UI.

**Leave Terminal #1 running.** Don't close it.

### Step 4 — Mobile app setup (Flutter Web)

Open **Terminal #2**:

```bash
cd mobile
flutter pub get
```

Confirm `mobile/lib/core/constants.dart` points to your local backend:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
}
```

Run the app:

```bash
flutter run -d chrome --web-port 5000
```

Chrome opens at http://localhost:5000. You should see the splash screen → signup screen.

**Leave Terminal #2 running.**

### Step 5 — End-to-end test

In the Chrome window:

1. Sign up with a test email (e.g., `test@example.com`)
2. Complete account setup → land on RFP brief input screen
3. Tap the "Punjab Citizen Portal (Demo)" example brief to autofill
4. Tap **Generate RFP**
5. Watch the progress screen poll the backend every 2 seconds; agents complete sequentially
6. After ~3 minutes (depending on Gemini API responsiveness), preview screen shows the generated RFP
7. Click through Vendor Select → Confirm → Success
8. From the success screen, "View Results Dashboard" shows full audit trail

**Verify in Supabase:** the `rfp_jobs`, `agent_traces`, `generated_documents`, `sent_emails`, `calendar_events`, and `portal_postings` tables all have new rows for your run.


### Building the Android APK

```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

This is a completed run from the project's test history (reference `PPRA-2026-0519-2277F5`) — all 5 dashboard cards render with real Supabase data.

### Building the Android APK

```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## 📊 Rubric Mapping

### Use of Antigravity (25%)

The entire project was built inside Google Antigravity IDE. The `antigravity_artifacts/` folder contains workplans, reasoning traces, task checklists, walkthrough recordings, and screenshots for every task from initial setup through Task 7C.

**Strongest autonomous behaviour examples:**
1. **3-cycle autonomous debug of the Compliance Auditor** (Task 4) — Antigravity diagnosed the ADK `output_schema + tools` constraint, patched, re-tested, all without re-prompting. The same lesson was then reused autonomously in the Drafter task.
2. **Autonomous port-conflict resolution** during Task 7C — Antigravity ran a series of PowerShell diagnostic commands (`Get-NetTCPConnection`, `Get-Process`, `Stop-Process -Id 32932 -Force`) to free port 5000 from a stale Flutter process before continuing.
3. **Browser-driven self-verification** (Task 7A) — Antigravity drove a real Chrome browser through the onboarding flow, found a regex bug it had written for email sub-addressing, fixed it, and produced a `.webp` screen recording of the session as an artifact.

### Agentic Reasoning & Workflow (20%)
- 4 distinct ADK agents with structured Pydantic schemas, deterministic tool ordering, and per-event trace persistence (one row per `function_call` + `function_response`).
- Orchestrator chains agents with state propagation (`.model_dump()` between agents to avoid Pydantic version coupling).
- Failure handling: any agent exception writes a trace with `agent_name`, marks `rfp_jobs.status='failed'`, and surfaces a friendly error UI to the user.

### Insight Quality (20%)
- All outputs grounded in real Supabase data — PPRA rules table feeds compliance decisions, vendor table with past performance scores drives shortlisting.
- The Results Dashboard's reasoning audit trail surfaces every reasoning step with per-agent colour-coded badges — every decision is auditable.

### Action Simulation & Outcome (15%)
- One successful run produces **a real PDF on disk + 10 rows across 4 Supabase action tables** (1 `generated_documents`, 5 `sent_emails`, 3 `calendar_events`, 1 `portal_postings`) plus ~50 `agent_traces`.
- The mobile dashboard's "Actions Executed" timeline surfaces every action with expandable detail and a working PDF download button.

### Technical Implementation (10%)
- Clean architectural separation (agents / tools / services / api in backend; core / models / services / screens / widgets in Flutter).
- Typed Pydantic schemas everywhere; Riverpod for state; GoRouter for declarative routing.
- Live stream-based polling with proper termination on terminal status.
- Deployed to public cloud (Railway + Netlify); APK in `releases/`.

### Innovation & UX (10%)
- Live agent-by-agent progress UI with climbing reasoning trace count.
- 4-dot agent timeline + colour-coded trace audit trail visually communicate the agentic architecture.
- PPRA-specific defaults — Pakistani vendor names, PKR currency, Urdu-language considerations in scope synthesis.

---

## 📱 Notes on the App Target

This project ships as both a **Flutter Web build** (the primary submission link, hosted on Netlify) and an **Android APK** (`releases/rfp_agent_app.apk`). Both come from the same Dart codebase under `mobile/`. Web was chosen as the primary submission target for instant judge access — no APK install or device setup required. The Android target was built via `flutter build apk --release` and verified.

## ⚠️ Notes on Live Pipeline Runs

The runtime pipeline calls Google Gemini 2.5 Flash via Google ADK. Gemini's free and Tier-1 APIs return transient 503 ("model overloaded") errors during global high-traffic windows. The orchestrator handles these gracefully — any failed agent marks `rfp_jobs.status='failed'` and writes a trace row, and the frontend renders a friendly error card.

For demo purposes, a known-good completed job exists at:
- **Reference:** `PPRA-2026-0519-2277F5`
- **Job ID:** `9ef366ca-153f-4cd3-8139-6576a8b59ff3`
- **Direct URL on live app:** https://rfp-agent-system.netlify.app/#/rfp/result/9ef366ca-153f-4cd3-8139-6576a8b59ff3

This job has all 4 action tables populated and ~54 agent traces; the dashboard renders the full results.

---

## 👥 Team & Acknowledgments

Built for the hackathon by **Noor Fatima, Dina Khan, and Rubaisha Nadeem** in Islamabad, Pakistan, over 3 days.

Special thanks to the Google ADK and Antigravity teams for the tooling that made this build possible at this pace.

---
