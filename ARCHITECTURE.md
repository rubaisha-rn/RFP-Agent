# 🏛️ RFP Agent System Architecture

## Overview
The RFP Agent System is a full-stack, multi-agent application designed to automate the generation of Public Procurement Regulatory Authority (PPRA) compliant Request-for-Proposal (RFP) documents. The architecture leverages a micro-agent approach, with a FastAPI backend orchestrating the agent pipeline and a Flutter frontend providing a seamless user experience across Web and Mobile.

## 🏗️ System Components

### 1. Frontend (Flutter Mobile & Web)
- **Framework**: Flutter 3.41+
- **State Management**: Riverpod 2.5
- **Routing**: GoRouter 14.2
- **Key Features**:
  - Multi-platform support (Web primary, Android APK secondary).
  - Live stream-based polling (`Timer.periodic` + `StreamController`) to `/rfp/status` every 2 seconds.
  - Real-time agent progress UI with a climbing reasoning trace count.
  - Results dashboard with a 4-dot agent timeline, compliance scorecard, and vendor shortlist.

### 2. Backend (FastAPI + Google ADK)
- **Framework**: FastAPI (Python 3.11)
- **Agent Framework**: Google Agent Development Kit (ADK) 1.34
- **LLM**: Google Gemini 2.5 Flash
- **Execution**: 
  - Async orchestrator leveraging `asyncio.create_task` for background pipeline execution.
  - Pydantic v2 for structured outputs and schema validation.
  - State propagation (`.model_dump()`) between agents to decouple schemas.

### 3. Database (Supabase Postgres)
- **Role**: Persistent state, audit logs, and configuration.
- **Key Tables**:
  - `organizations` and `vendors`: Seed data for vendor intelligence.
  - `rfp_jobs`: Tracks pipeline status.
  - `agent_traces`: Stores granular reasoning steps (`function_call` + `function_response`).
  - `generated_documents`, `sent_emails`, `calendar_events`, `portal_postings`: Records output artifacts and actions.
  - `ppra_rules`: Used by the Compliance Auditor for dynamic rule lookups.

## 🤖 Agent Pipeline
The system utilizes 4 distinct ADK agents executing sequentially. Each agent is responsible for a specific domain of the RFP generation process.

1. **Agent 1 — Classifier**
   - **Role**: Extracts category, value, timeline, and key requirements from a natural language brief.
   - **Method**: LLM reasoning + structured Pydantic output.
   
2. **Agent 2 — Compliance Auditor**
   - **Role**: Selects the correct PPRA bidding method and computes a compliance score.
   - **Tools**: `lookup_ppra_rules`
   
3. **Agent 3 — Vendor Intelligence**
   - **Role**: Ranks vendors, predicts bid ranges, filters blacklisted vendors, and flags conflicts of interest.
   - **Tools**: `query_vendors`, `run_conflict_check`, `predict_bid_range`
   
4. **Agent 4 — Drafter & Executor**
   - **Role**: Synthesises the RFP body, generates a PDF (via `reportlab`), dispatches emails, creates calendar events, and posts to the portal.
   - **Tools**: `generate_rfp_pdf`, `send_invitation_email`, `create_calendar_event`, `post_to_portal`

## 🔄 Data Flow
1. **Initiation**: User submits a 4-sentence brief via the Flutter app to `POST /rfp/generate`.
2. **Background Execution**: FastAPI returns a `job_id` immediately and starts the pipeline via `asyncio.create_task`.
3. **Orchestration**: The `run_pipeline` function executes the 4 agents sequentially.
4. **Persistence**: At each step, agents write reasoning traces to the `agent_traces` table.
5. **Polling**: The Flutter app polls `GET /rfp/status/{job_id}` to update the UI.
6. **Completion**: Final artifacts (PDF, emails, events) are generated, and the job status is set to `completed`.
7. **Delivery**: The app downloads the resulting PDF and displays the full audit dashboard.
