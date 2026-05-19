# API Smoke Test Plan

This document provides realistic `curl` examples to verify the end-to-end functionality of the RFP Agent API.

## 1. Health Check
```bash
curl -X GET http://localhost:8000/health
```
**Expected Response:**
```json
{"status": "ok"}
```

## 2. List Contacts (Vendors)
```bash
curl -X GET http://localhost:8000/contacts
```
**Expected Response:** A JSON object with `count: 11` and a `vendors` array.

## 3. Organization Signup
```bash
curl -X POST http://localhost:8000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"company_name": "Demo Corp", "company_email": "demo@example.com", "password": "password123"}'
```
**Expected Response:**
```json
{
  "organization_id": "<uuid>",
  "company_name": "Demo Corp",
  "company_email": "demo@example.com"
}
```

## 4. Organization Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"company_email": "demo@example.com", "password": "password123"}'
```
**Expected Response:**
```json
{
  "organization_id": "<uuid>",
  "company_name": "Demo Corp",
  "company_email": "demo@example.com"
}
```

## 5. Generate RFP (Kickoff Pipeline)
```bash
curl -X POST http://localhost:8000/rfp/generate \
  -H "Content-Type: application/json" \
  -d '{"brief": "We need a digital citizen services portal for the Punjab government. Cloud-hosted, must support Urdu and English, integrate with NADRA API for identity verification. Budget around 2.5 million PKR. Required within 90 days."}'
```
**Expected Response:** Returns immediately (within ~1-2 seconds) without waiting for pipeline completion.
```json
{
  "job_id": "<uuid>",
  "status": "pending",
  "message": "Pipeline kicked off; poll /rfp/status/{job_id} for progress."
}
```
*Note: Save the `job_id` from this response for the next steps.*

## 6. Poll Status
Replace `<job_id>` with the UUID from step 5.
```bash
curl -X GET http://localhost:8000/rfp/status/<job_id>
```
**Expected Response:**
```json
{
  "job_id": "<uuid>",
  "status": "running",
  "current_agent": "classifier",
  "brief": "...",
  "created_at": "...",
  "completed_at": null,
  "progress_pct": 25,
  "trace_count": 2
}
```
*Note: Status will progress from `pending` -> `running` (with different `current_agent` values) -> `completed`.*

## 7. Get Full Result
Replace `<job_id>` with the UUID from step 5.
```bash
curl -X GET http://localhost:8000/rfp/result/<job_id>
```
**Expected Response:** A large JSON object containing the `job` details, list of `traces`, `document` record, `emails` sent, `calendar_events` created, and `portal_posting`.
