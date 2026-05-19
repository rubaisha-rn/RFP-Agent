# Task 7A — Flutter Scaffold + Onboarding Flow

**Date:** 2026-05-19
**Workspace:** rfp-agent-system
**Build agent:** Gemini 3 Flash inside Antigravity
**Mode:** Plan ON
**Conversation:** "Scaffolding Flutter Mobile App"
**Duration:** ~30 minutes (plan, execute, autonomous browser verification, autonomous regex bug fix)

## Goal
Initialize the Flutter web mobile app, build the core architecture (API client, theme, state management, routing), and implement the onboarding flow (splash → signup → account setup) that talks end-to-end to the live FastAPI backend.

## Files Created (16)
- **Project foundation:** `mobile/pubspec.yaml` with http, go_router, flutter_riverpod, shared_preferences, google_fonts
- **Core utilities:** `lib/core/constants.dart` (API_BASE_URL), `lib/core/theme.dart` (navy #0F2A4A primary, emerald #16A34A accent, Inter font), `lib/core/api_client.dart` (singleton with typed ApiException + FastAPI detail parsing + request logging)
- **Services:** `lib/services/auth_service.dart` (Riverpod auth provider + SharedPreferences session persistence), `lib/services/rfp_service.dart` (stub placeholder for Task 7B)
- **Models:** `lib/models/organization.dart`, `lib/models/rfp_brief.dart`, `lib/models/job_status.dart`
- **Screens:** `lib/screens/splash_screen.dart` (animated brand entry with auth-state routing), `lib/screens/onboarding/signup_screen.dart` (responsive form with inline validation, login/signup toggle, error messages), `lib/screens/onboarding/account_setup_screen.dart` (Industry + Budget dropdowns + simulated policy upload widget)
- **Widgets:** `lib/widgets/primary_button.dart`, `lib/widgets/labeled_field.dart`
- **App wiring:** `lib/app.dart` (GoRouter with /, /signup, /login, /account-setup, /rfp/new placeholder, /rfp/progress/:jobId placeholder, /rfp/result/:jobId placeholder), `lib/main.dart` (ProviderScope root)

## Autonomous Browser Verification
Antigravity drove a real Chrome browser via its built-in browser tool to verify the entire onboarding flow:
- Splash screen 1.8-second auto-redirect to /signup ✅
- Signup form filled with `testtask7a@example.com` ✅
- POST /auth/signup returned 200 OK with organization_id `177df57b-02d8-4690-be24-0e3d16dd965d` ✅
- Database row written to Supabase organizations table (Name: Acme Procure Task7A) ✅
- Account Setup screen rendered with Industry + Budget dropdowns + simulated policy upload UI ✅
- File upload simulation showed `procurement_policy_v2.pdf (1.8 MB)` ✅
- Continue button redirected to /rfp/new placeholder ✅
- Logout flow returned to /signup ✅

## Autonomous Bug Fix
During the browser test, Antigravity discovered a regex validation mismatch in `signup_screen.dart:214` that rejected email addresses containing the `+` character (sub-addressing format used by `testtask7a+task7a_unique1@example.com`). Antigravity fixed the regex to natively allow `+` and re-ran the test successfully. No human intervention required.

## Architecture Highlights
- **State management:** Riverpod 2.5 with StateNotifierProvider — clean, no boilerplate, supports persistence.
- **Routing:** GoRouter 14.2 for declarative URL-driven routing — works correctly with browser back/forward and deep linking.
- **Error handling:** ApiException carries `(statusCode, message)` from FastAPI's `detail` field — enables specific UX (e.g., 409 → "Email already registered" vs generic 500 → "Server error, try again").
- **Session persistence:** SharedPreferences saves `organization_id` so F5 reloads don't bump users back to signup.
- **Theme:** Navy + emerald palette, Material 3 base, Inter via google_fonts. Professional procurement aesthetic, not generic Flutter blue.

## Rubric Mapping
- **Use of Antigravity (25%) — peak evidence:** Agent drove its own browser to verify its work, found a regex bug it had written, fixed it, re-ran the test, and produced a `.webp` recording of the entire session as a deliverable artifact. This is the strongest single piece of Antigravity-usage evidence in the entire project.
- **Technical Implementation (10%):** Clean separation by concern (core/services/models/screens/widgets). Typed error handling with status-code switching. Session persistence. CORS-compatible cross-origin requests from web Flutter to FastAPI.
- **Innovation & UX (10%):** Modern Material 3 theme with custom palette. Animated splash. Inline form validation. Login/signup toggle in one screen. Simulated file upload with realistic UI feedback.
- **Agentic Reasoning (20%):** Antigravity decided when to write code vs. when to verify, when to drive a browser vs. when to inspect terminal output, and when to debug its own output vs. ask the user — all autonomously.

## Artifacts Produced by Antigravity (auto-generated)
- `task7a_scaffold_onboarding_tasks.md` (checklist)
- `task7a_scaffold_onboarding_walkthrough.md` (narrative walkthrough)
- `onboarding_auth_flow.webp` (browser session recording, ~1 min)
- 4 screenshots: signup, account setup, rfp dashboard placeholder, logged out