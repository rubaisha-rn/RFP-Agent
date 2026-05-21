# RFP Agent System

> A multi-agent procurement automation system for the Government of Pakistan, generating PPRA-compliant Request-for-Proposal documents from a 4-sentence brief in under 3 minutes.

**Hackathon Submission — May 2026**

---

## 🔗 Submission Links

| What | Link |
|---|---|
| 🌐 Live Web App (Netlify) | https://rfp-agent-system.netlify.app |
| ⚙️ Live Backend API (Swagger) | https://rfp-agent-system-production.up.railway.app/docs |
| 📦 Source Code (GitHub) | https://github.com/dina-khan/rfp-agent-system |
| 📱 Android APK | | 📱 Android APK | [Download v1.0.0 release](https://github.com/dina-khan/rfp-agent-system/releases/tag/v1.0.0) | |
| 🎥 Demo Video (3-5 min) | [_(YouTube link added in submission form)_](https://drive.google.com/file/d/1puNylBzz8V34rTmtBmM9USeBVLSTenG5/view) |
| 🤖 Antigravity Usage Video | (https://drive.google.com/file/d/1U5-3ag_L_e50FqCmb0HoIpDwSlFaoNd_/view?usp=sharing) |
| 📁 Antigravity Build Artifacts | `antigravity_artifacts/` |

---

## 🎯 The Problem

Pakistan's Public Procurement Regulatory Authority (PPRA) mandates that every government RFP comply with detailed rules covering bidding methods, advertisement thresholds, and integrity pacts for high-value procurements. Procurement officers spend **4-8 hours** drafting a single compliant RFP, and inconsistent rule application leads to procedural rejections and audit findings.

## 💡 The Solution

A multi-agent system that takes a procurement officer's 4-sentence brief and produces a complete, compliant RFP package in ~3 minutes. Four AI agents work sequentially through reasoning, compliance audit, vendor selection, and document drafting — with every reasoning step and every tool call persisted to a database as an auditable trail.

### 🤖 Gemini Models Used in Agents
The entire pipeline runs on **Google Gemini 2.5 Flash**, offering high speed and reasoning capabilities.

| Agent | Model | Role | Tools |
|---|---|---|---|
| **Classifier** | `gemini-2.5-flash` | Extracts category, value, timeline, key requirements from brief | LLM reasoning + structured output |
| **Compliance Auditor** | `gemini-2.5-flash` | Selects correct PPRA bidding method; computes compliance score | `lookup_ppra_rules` |
| **Vendor Intelligence**| `gemini-2.5-flash` | Ranks 5 vendors; predicts bid range; filters blacklisted | `query_vendors`, `run_conflict_check`, `predict_bid_range` |
| **Drafter & Executor** | `gemini-2.5-flash` | Synthesises RFP, generates PDF, sends emails, schedules deadlines | `generate_rfp_pdf`, `send_invitation_email`, `create_calendar_event`, `post_to_portal` |

---

## 🚀 Running Locally & Using the App

### 🌐 Live Web App (Netlify)
The easiest way to test the system is to use our live web application.
**Visit:** [https://rfp-agent-system.netlify.app](https://rfp-agent-system.netlify.app)
1. Sign up with a test email.
2. Complete account setup and tap the "Demo Brief" to autofill.
3. Tap **Generate RFP** to watch the multi-agent pipeline live.

### 📱 Android APK
You can also run the app natively on any Android device.
1. Download [`releases/rfp_agent_system.apk`](https://github.com/dina-khan/rfp-agent-system/releases/tag/v1.0.0) from this repository.
2. Transfer it to your Android device and install it (you may need to allow "Install from Unknown Sources").
3. Launch **RFP Agent** and follow the same steps to generate your RFP.

---

### 💻 Running the Backend Locally
To test the FastAPI backend and see the agents running in your terminal:

**Prerequisites:** Python 3.11+, Supabase (Free Tier), Google AI Studio API Key, Resend API Key.

1. **Clone & Setup:**
```bash
git clone https://github.com/dina-khan/rfp-agent-system.git
cd rfp-agent-system/backend
python -m venv .venv
.venv\Scripts\Activate.ps1   # Windows
# source .venv/bin/activate  # macOS / Linux
pip install -r requirements.txt
```

2. **Environment Variables (`.env`):**
Create a `.env` file in the `backend/` directory:
```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
GOOGLE_API_KEY=your-gemini-api-key-here
RESEND_API_KEY=your-resend-api-key-here  # Required for email tools
APP_SECRET=any-random-32-character-string
```

3. **Supabase Setup:**
Execute the two SQL files located in `backend/supabase/migrations/` in your Supabase SQL Editor to create tables and seed dummy data.

4. **Run Server:**
```bash
python -m uvicorn app.main:app --reload --port 8000
```
Swagger API docs will be available at [http://localhost:8000/docs](http://localhost:8000/docs).

---


## 📱 Android Emulator / APK Connection (Local Backend)

If you are running the Android emulator or APK locally, you must forward the backend port so the app can communicate with your FastAPI server.

### ⚙️ Step 1: Start Backend

Make sure backend is running:

```bash
python -m uvicorn app.main:app --reload --port 8000
```

### 📲 Step 2: Connect Emulator / Device to Backend

Run these in a new terminal:

```bash
$env:Path += ";$HOME\AppData\Local\Android\Sdk\platform-tools"
adb reverse tcp:8000 tcp:8000
```

### 🚀 Step 3: Run the App

Now launch the emulator or install the APK.

The app will successfully connect to:

http://localhost:8000

---

## 📁 Repository Structure

```text
rfp-agent-system/
├── backend/                          # FastAPI + Google ADK
│   ├── app/
│   │   ├── agents/                   # The 4 Gemini 2.5 Flash agents
│   │   ├── api/                      # REST Endpoints
│   │   ├── services/                 # Supabase & Job handlers
│   │   ├── tools/                    # Tool definitions for agents
│   │   └── config.py                 # Environment Config
│   ├── supabase/migrations/          # SQL files for schema & seeds
│   └── requirements.txt
│
├── mobile/                           # Flutter Frontend App
│   ├── lib/
│   │   ├── core/                     # Constants, Theme, API Client
│   │   ├── models/                   # Dart Data Models
│   │   ├── screens/                  # Onboarding, Dashboard, RFP Flow
│   │   ├── services/                 # Auth and Logic
│   │   └── widgets/                  # Reusable components
│   └── pubspec.yaml
│
├── antigravity_artifacts/            # 100+ files of build evidence
│   ├── workplans/
│   ├── reasoning_traces/
│   ├── screenshots/
│   └── walkthroughs/
│
├── releases/
│   └── rfp_agent_app.apk             # Compiled Android App
│
├── ARCHITECTURE.md
├── ANTIGRAVITY_USAGE.md
└── README.md
```

---

## 🛠️ Build Phases - Task-by-Task Breakdown

The project was built sequentially inside Google Antigravity. Artifacts are saved under `antigravity_artifacts/`.

- **Task 1 — First Antigravity Run**: Verified the IDE-as-agent workflow.
- **Task 2 — Backend Scaffold + Supabase**: Set up the FastAPI backend and designed the 9-table schema.
- **Task 3 — Agent 1: Classifier**: Built the first gemini-2.5-flash ADK agent.
- **Task 4 — Agent 2: Compliance Auditor**: Handled deep debugging cycle entirely autonomously.
- **Task 5 — Agent 3: Vendor Intelligence**: Configured 9 tool calls for predicting bid ranges and blacklists.
- **Task 6 — Agent 4: Drafter & Executor**: Implemented PDF synthesis and action executions (emails, calendar).
- **Task 7 — Orchestrator + FastAPI**: Wired the pipeline to an async `create_task` orchestrator.
- **Task 7A — Flutter Scaffold + Onboarding**: Initialized frontend and resolved Riverpod state bugs using the built-in browser.
- **Task 7B — RFP Generation Flow**: Developed the live stream polling UI.
- **Task 7C — Results Dashboard**: Designed the final audit dashboard. Resolved local port conflicts autonomously.

---

## 📊 Rubric Mapping

### Use of Antigravity (25%)

The entire project was built inside Google Antigravity IDE. The `antigravity_artifacts/` folder contains workplans, reasoning traces, task checklists, walkthrough recordings, and screenshots for every task from initial setup through Task 7C.

**Strongest autonomous behaviour examples:**
1. **3-cycle autonomous debug of the Compliance Auditor** (Task 4) — Antigravity diagnosed the ADK `output_schema + tools` constraint, patched, re-tested, all without re-prompting. The same lesson was then reused autonomously in the Drafter task.
2. **Autonomous port-conflict resolution** during Task 7C — Antigravity ran a series of PowerShell diagnostic commands (`Get-NetTCPConnection`, `Get-Process`, `Stop-Process -Id 32932 -Force`) to free port 5000 from a stale Flutter process before continuing.
3. **Browser-driven self-verification** (Task 7A) — Antigravity drove a real Chrome browser through the onboarding flow, found a regex bug it had written for email sub-addressing, fixed it autonomously, and captured screenshots of the verification..

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

## 👥 Team & Acknowledgments

Built for the hackathon by **Noor Fatima, Dina Khan, and Rubaisha Nadeem** in Islamabad, Pakistan, over 3 days.

Special thanks to the Google ADK and Antigravity teams for the tooling that made this build possible at this pace.
