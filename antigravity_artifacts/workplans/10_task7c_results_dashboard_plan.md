# Implementation Plan - Task 7C: RFP Results Dashboard

This plan outlines the architecture, design, and step-by-step changes to implement the post-pipeline **RFP Results Dashboard** in the Flutter mobile application at `mobile/`. This dashboard is a read-only, premium screen that serves as a highly detailed, professional audit trail of all agent actions, compliance evaluations, vendor rankings, and reasoning traces for a completed procurement job.

---

## User Review Required

> [!IMPORTANT]
> **Design and Navigation Choices**
> 1. **Read-only Screen**: As per requirements, all interactive elements are read-only except outbound actions: Downloading the generated PDF, clicking the PPRA Portal URL, and expanding interactive cards (Emails, Calendar Events, Reasoning traces).
> 2. **Web-Native Download**: We will leverage `dart:html` for PDF downloads on Web target to directly open the download link in a new tab without external library runtime errors.
> 3. **Null-Safety Guarding**: Since the pipeline can sometimes fail halfway, we've designed fallback views and friendly empty-state texts for every single component rather than letting the screen crash.

---

## Open Questions

> [!NOTE]
> There are no open blocking questions. We have confirmed the Supabase database schema for traces, emails, calendar events, documents, and portal postings, and they match the existing `RfpResult` Dart models exactly.

---

## Proposed Changes

We will create a new dashboard screen file and update the routing file.

### Mobile Frontend (`mobile/`)

#### [NEW] [result_dashboard_screen.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/screens/rfp/result_dashboard_screen.dart)
Create a single beautiful `ConsumerStatefulWidget` screen implementing the 5 cards from top to bottom:

1. **Header Card**:
   - Reference ID display (copyable on tap).
   - Dynamic status badge (`completed` green, `failed` red, `running` orange).
   - Agent completion timeline (Classifier ➜ Auditor ➜ Vendor Intel ➜ Drafter) displaying solid colored indicators for completed stages and grey outlines for skipped/pending ones.
   - Timestamps & Reasoning step count metadata.

2. **Compliance Scorecard Card**:
   - Headed by a gavel icon.
   - Big bold circular score or scorecard badge with HSL-based dynamic color coding.
   - Detailed list of Bidding Method, Integrity Pact (Yes/No badge), and Advertisement Required.
   - Expandable bullet list of PPRA mandatory clauses automatically applied by the agent.

3. **Vendor Shortlist Card**:
   - Top 5 vendor list with beautiful ranks.
   - Category tag, score (e.g. `4.8 ★`), predicted bid range, and conflict warning flags (`⚠` icon with tooltip) for soft-flagged vendors.

4. **Actions Simulated Card**:
   - Vertical timeline visualization of actions executed by the Drafter agent.
   - **Document Generated**: Displays PDF filename with a premium "Download PDF" button.
   - **Emails Sent**: Expandable tile displaying the list of dispatched invitation emails (vendor name, subject, body preview).
   - **Calendar Events**: Expandable tile displaying pre-bid, technical, and closing scheduled events.
   - **Portal Posting**: Displays PPRA cataloged reference and clickable published URL.

5. **Agent Reasoning Trace Card (The Audit Trail)**:
   - Filter chips at the top (All, Classifier, Auditor, Vendor Intel, Drafter) to isolate agents.
   - Scrollable nested list of agent reasoning steps.
   - Tap-to-expand details showing full reasoning texts with elegant, smooth transitions.

---

#### [MODIFY] [app.dart](file:///e:/rfp-hackathon/rfp-agent-system/mobile/lib/app.dart)
Replace the placeholder route `/rfp/result/:jobId` to build `ResultDashboardScreen(jobId: state.pathParameters['jobId']!)`.

---

## Verification Plan

### Automated & Manual Verification
1. Run Flutter web locally.
2. Navigate directly to a real completed job: `http://localhost:5000/#/rfp/result/9ef366ca-153f-4cd3-8139-6576a8b59ff3`.
3. Check the rendering of all 5 cards:
   - Verify Header shows 4 solid agent dots, job status "completed", and 54 reasoning steps.
   - Verify Compliance card shows score, bidding method, and PPRA clauses.
   - Verify Vendor Shortlist shows 5 ranked vendors, bid ranges, and conflict warnings if any.
   - Expand Actions Simulated: verify emails, calendar events, and portal posting link are correct.
   - Verify Reasoning Trace shows all 54 traces, filtering by agents works, and tapping a trace expands it.
   - Click "Download PDF" and verify it triggers a download in a new tab.
4. Navigate to a non-existent job: `http://localhost:5000/#/rfp/result/not-a-real-job-id`.
   - Verify the error screen loads gracefully with a "Back to Home" button.
