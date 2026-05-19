# Implementation Plan - Task 7B: RFP Generation Flow

We need to implement the full end-to-end RFP generation flow in the Flutter mobile app:
`Brief Input` ➔ `Live Agent Progress Polling` ➔ `RFP Preview & PDF Download` ➔ `Vendor Shortlist Selection` ➔ `Confirm & Send` ➔ `Success Metrics Screen`.

We will build clean, premium-looking models, services, and screens mirroring the existing dark/navy visual style and theme tokens defined in `account_setup_screen.dart` and `theme.dart`.

---

## Proposed Changes

### Part A: Models (`mobile/lib/models/`)

We will create/update the models to parse the backend JSON structures robustly and support graceful null handling (highly critical since fields are null during pipeline runs).

#### 1. [MODIFY] [job_status.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/models/job_status.dart)
Extend the existing model to:
- Capture new fields: `brief`, `createdAt`, `completedAt`.
- Implement getters: `isComplete` (status == 'completed'), `isFailed` (status == 'failed'), `isRunning` (status == 'running' || status == 'pending').
- Implement `agentDisplayName` helper:
  - `classifier` ➔ `"Requirements Classifier"`
  - `auditor` ➔ `"Compliance Auditor"`
  - `vendor_intel` ➔ `"Vendor Intelligence"`
  - `drafter` ➔ `"Drafter & Executor"`
  - Default/null ➔ `"Initializing Pipeline..."`

#### 2. [NEW] [vendor.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/models/vendor.dart)
A data model for listed active vendors:
- `id`, `name`, `email`, `category`, `pastPerformanceScore`.
- Aligns with the `/contacts` API return payload.

#### 3. [NEW] [rfp_result.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/models/rfp_result.dart)
Full results data model with deeply nested robust parsing:
- `RfpResult` contains top-level properties: `job`, `traces`, `document`, `emails`, `calendarEvents`, `portalPosting`, `classification`, `compliance`, `vendorIntel`, `finalRfp`.
- **Bulletproof Parser**: Since the backend returns raw traces containing agent output in the `output_data` field, our `RfpResult.fromJson` will first check if `job['classification']`, etc. exists; if not, it will automatically extract `classification`, `compliance`, `vendorIntel`, and `finalRfp` by searching through the `traces` list for corresponding `agent_name` entries where `output_data != null`. This guarantees zero null-pointer crashes!
- Sub-models to implement:
  - `Classification` (category, estimated value, urgency, bidding method, certifications, timeline, requirements, notes)
  - `ComplianceScorecard` (rule codes, confirmed bidding method, mandatory clauses, score, advertisement requirements, validity, integrity pact, issues, notes)
  - `VendorIntel` & `ShortlistEntry` & `BidRange` (shortlisted vendors, predicted range, conflict flags, notes)
  - `FinalRfp` & `RfpBody` & `ExecutedActions` (title, scope, eligibility, evaluation, deadines, contacts, sent emails/events/portal postings)

---

### Part B: Service (`mobile/lib/services/rfp_service.dart`)

We will flesh out `RfpService` as a Riverpod-managed service using the global `ApiClient` singleton.

#### 4. [MODIFY] [rfp_service.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/services/rfp_service.dart)
- `Future<String> generateRfp({required String brief, required String organizationId})`: POSTs to `/rfp/generate` and returns `job_id`.
- `Stream<JobStatus> watchJobStatus(String jobId)`: Polls `/rfp/status/{jobId}` every 2 seconds. Uses a `StreamController` and a `Timer.periodic`. Yields fresh `JobStatus` values, and automatically stops (closes) when the status becomes `'completed'` or `'failed'`.
- `Future<RfpResult> getResult(String jobId)`: GETs `/rfp/result/{jobId}` and parses the unified `RfpResult`.
- `Future<List<Vendor>> listContacts({String? category})`: GETs `/contacts` with optional `category` parameter and parses the vendor list.

All network errors will be naturally wrapped in `ApiException`.

---

### Part C: Screens (`mobile/lib/screens/rfp/`)

We will implement all six screens using premium, highly aesthetic modern UI components, smooth micro-animations (like custom progress circles or status checks), and elegant styling mirroring `account_setup_screen.dart`.

#### 5. [NEW] [brief_input_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/brief_input_screen.dart) ➔ `/rfp/new`
- Large 8-row modern `TextField` for procurement brief with dynamic character counter.
- Autofill chips for 3 pre-configured sample briefs, including the target Punjab Citizen services portal demo brief.
- Disabled "Generate RFP" button until length is 20+ characters. Shows a premium spinning progress indicator inside the button when clicked.
- Catch errors inline with an warning banner above the button.

#### 6. [NEW] [progress_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/progress_screen.dart) ➔ `/rfp/progress/:jobId`
- A visual progress ring with live changing `progress_pct`.
- Live Agent pipeline listing with state icons:
  - `✓ completed` (Emerald green check)
  - `⏳ running` (Orange rotating spinner)
  - `◯ pending` (Quiet grey circle)
- Live climbing reasoning steps counter (updates dynamically from `traceCount`).
- Automatically routes to `/rfp/preview/:jobId` after a 1-second delay upon successful pipeline completion.
- Interactive debug box "View Raw Status JSON" for testing.
- Block pop scopes so users don't accidentally disrupt pipeline runs.

#### 7. [NEW] [preview_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/preview_screen.dart) ➔ `/rfp/preview/:jobId`
- Organized sections using modern `ExpansionTile` widgets:
  - Document Title & Scope of Work
  - Compliance Scorecard & PPRA Rules
  - Eligibility & Evaluation Criteria (weighted)
  - Mandatory Clauses & Integrity Pact
  - Key Dates & Deadlines (submission, opening)
  - Selected shortlists (quick visual check)
- Bottom sticky bar: "Download PDF" (uses direct tab navigation via `html.window.open` on web, fully documented) and primary "Select Contacts ➔" button.

#### 8. [NEW] [contacts_select_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/contacts_select_screen.dart) ➔ `/rfp/contacts/:jobId`
- Lists all active vendors retrieved from the backend.
- Pre-checks checkboxes for vendors shortlisted by the Vendor Intel agent.
- Simple interactive category search/filter chips at the top.
- Sticky action bar with total selected count: "Send to N Vendors". Passes the selection via GoRouter extra parameters.

#### 9. [NEW] [confirm_send_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/confirm_send_screen.dart) ➔ `/rfp/confirm/:jobId`
- Summary box detailing the reference ID, number of target vendors, and the default dispatch method (Email).
- Modern interactive vertical timeline showing what the backend agent already executed (Emails sent, portal postings created).
- Full-screen loading overlay "Dispatching Invitations..." when clicking "Send RFP" for 2 seconds (purely visual confirm to match the backend's completed tasks).

#### 10. [NEW] [success_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/success_screen.dart) ➔ `/rfp/success/:jobId`
- Full-screen celebrating victory screen with a large glowing emerald check badge.
- Interactive summary card summarizing the outcome (emails, portal postings, calendar events, steps).
- Primary buttons to go back to the new RFP form or proceed to results dashboard.

---

### Part D: Routing & Guards (`mobile/lib/app.dart`)

#### 11. [MODIFY] [app.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/app.dart)
- Replace all raw GoRoute builders with the newly created screens.
- Extract `jobId` parameter cleanly from routes and pass down.
- Maintain existing session organization redirects for robustness.

---

## Verification Plan

### Manual Verification Flow
We will execute the complete flow on the browser (running at `http://localhost:5000` via Chrome):
1. **Signup/Login**: Access app, complete onboarding setup, land on `/rfp/new`.
2. **Draft Submission**: Click the "Punjab Citizen Services Portal" chip to auto-populate the brief. Verify button becomes active, and click "Generate RFP".
3. **Pipeline Watch**: Land on `/rfp/progress/{id}`. Watch the trace counter increment and agents transition from pending ➔ running ➔ done.
4. **Preview**: Verify automatic redirection to `/rfp/preview/{id}`. Verify all PPRA rules, compliance scores, and final body text are parsed correctly and rendered in expandable tiles. Click "Download PDF".
5. **Contact Filtering**: Proceed to `/rfp/contacts/{id}`. Verify shortlisted vendors are prechecked, filter by category, check another vendor, and click "Send".
6. **Confirm & Success**: Tap "Send RFP", view "Dispatching..." loader overlay, and landing on successful page showing dynamic dispatch stats.
7. Capture 3-5 screenshots during the verification flow to prove success.
