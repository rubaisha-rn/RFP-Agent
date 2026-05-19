# Task 7 (Orchestrator + FastAPI) — Task Checklist

## Plan phase
- [x] Read agent4_drafter.py to mirror the test harness chaining pattern
- [x] Read supabase_client.py for create_job / update_job_status signatures
- [x] Read 001_init_schema.sql for rfp_jobs + action tables column names
- [x] Decide async pattern: BackgroundTasks vs asyncio.create_task — chose create_task with user approval

## Implementation phase
- [x] Implement run_pipeline (orchestrator.py) chaining 4 agents with PIPELINE_PACING_SECONDS=60 pacing
- [x] Implement kick_off_pipeline returning job_id immediately
- [x] Implement get_job_status with progress_pct derived from current_agent
- [x] Implement get_job_full aggregating job + traces + 4 action tables
- [x] Implement FastAPI main.py with lifespan + CORS + 4 routers
- [x] Implement auth.py with /signup + /login (bcrypt password hash)
- [x] Implement rfp.py with /generate (asyncio.create_task scheduling), /status, /result
- [x] Implement contacts.py with /contacts vendor listing
- [x] Implement documents.py with /{document_id}/download FileResponse
- [x] Write api_smoke_test.md with curl examples + expected responses

## Verification phase (executed by Antigravity)
- [x] Start uvicorn — server launches without errors
- [x] /health returns {"status":"ok"}
- [x] /contacts returns 11 vendors
- [x] /auth/signup creates an organization row
- [x] /auth/login round-trips with same credentials
- [x] /rfp/generate returns job_id in <2 seconds (proves background scheduling works)
- [x] /rfp/status/{job_id} returns structured progress JSON
- [x] /rfp/result/{job_id} returns full results JSON (with failed status surfaced cleanly)
- [x] Orchestrator's error handler caught Gemini 429 and wrote it to agent_traces — proves fail-soft behaviour

## Polish pass (second Files Modified panel)
- [x] Refined job_manager.py for accurate column ordering
- [x] Added test_db.py for any database-level smoke checks