# RFP Agent System — File Structure

This document defines the canonical project layout. Antigravity agents must respect this structure.

\\\
rfp-agent-system/
├── README.md
├── ARCHITECTURE.md
├── ANTIGRAVITY_USAGE.md
├── .env.example
├── .gitignore
│
├── antigravity_artifacts/        # 25% rubric deliverable
│   ├── workplans/                # exported plans from Antigravity Manager
│   ├── task_lists/               # per-agent task artifacts
│   ├── reasoning_traces/         # decision flow logs
│   ├── screenshots/              # IDE screenshots
│   └── walkthroughs/             # recorded agent verifications
│
├── backend/                      # FastAPI + Google ADK
│   ├── requirements.txt
│   ├── .env
│   ├── app/
│   │   ├── main.py               # FastAPI entry
│   │   ├── config.py
│   │   ├── api/                  # REST routes
│   │   │   ├── auth.py           # POST /signup, /login
│   │   │   ├── rfp.py            # POST /rfp/generate, GET /rfp/status/{job_id}
│   │   │   ├── contacts.py       # GET /contacts
│   │   │   └── documents.py      # GET /documents/{id}
│   │   ├── agents/               # 4 runtime agents
│   │   │   ├── orchestrator.py
│   │   │   ├── agent1_classifier.py
│   │   │   ├── agent2_auditor.py
│   │   │   ├── agent3_vendor_intel.py
│   │   │   ├── agent4_drafter.py
│   │   │   ├── prompts/          # markdown system prompts
│   │   │   └── schemas/          # pydantic models
│   │   ├── tools/                # tools agents call
│   │   │   ├── ppra_rules.py
│   │   │   ├── vendor_db.py
│   │   │   ├── conflict_check.py
│   │   │   ├── bid_predictor.py
│   │   │   ├── pdf_generator.py
│   │   │   ├── email_sender.py
│   │   │   ├── calendar_creator.py
│   │   │   └── portal_poster.py
│   │   ├── services/
│   │   │   ├── supabase_client.py
│   │   │   └── job_manager.py
│   │   ├── data/
│   │   │   ├── ppra_rules.json
│   │   │   └── rfp_template.html
│   │   └── utils/
│   │       ├── logger.py
│   │       └── trace_writer.py
│   └── tests/
│
├── mobile/                       # Flutter app
│   └── lib/screens/...
│
└── demo/
    └── demo_script.md
\\\

## Agent pipeline (in order)
1. **Agent 1 — Requirements Classifier**: parses brief into structured JSON (category, value, bidding method).
2. **Agent 2 — Compliance Auditor**: consults PPRA rules, builds compliance scorecard.
3. **Agent 3 — Vendor Intelligence**: queries vendor DB, runs conflict check, predicts bid range, ranks top 5.
4. **Agent 4 — Drafter & Executor**: generates PDF, sends invites, creates calendar events, posts to portal — all writing to Supabase.

## Tech stack
- **Antigravity** — IDE for building and orchestrating the 4 build-time agents.
- **Google ADK (Agent Development Kit)** — runtime framework for the 4 agents in production.
- **FastAPI** — backend API.
- **Supabase** — Postgres DB + auth + realtime.
- **Flutter** — mobile app.
- **Gemini API (free tier)** — LLM powering the 4 agents.
