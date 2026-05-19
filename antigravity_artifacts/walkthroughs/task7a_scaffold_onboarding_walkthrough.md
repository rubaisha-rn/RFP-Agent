# Walkthrough - Task 7A: Scaffold Flutter App & Onboarding (Auth) Flow

This walkthrough documents the successful initialization, construction, and end-to-end verification of Phase 7A: Scaffolding the Flutter mobile application, building core architecture libraries, and implementing a functional onboarding and authentication flow.

## 🛠️ Work Accomplished

### 1. Flutter Project Initialization & Dependency Configuration
- Initialized a Flutter project under `mobile/` configured for `web` and `android` platforms.
- Modified `pubspec.yaml` to include premium libraries: `http`, `go_router`, `flutter_riverpod`, `shared_preferences`, and `google_fonts`.
- Resolved and downloaded all dependencies successfully.

### 2. Core Architecture Layout Implementation
- **Constants** (`lib/core/constants.dart`): Configured server connectivity pointing to `http://localhost:8000`.
- **Theme** (`lib/core/theme.dart`): Established the design tokens using navy primary (`#0F2A4A`), emerald secondary (`#16A34A`), rounded inputs (12px), rounded buttons (16px), and `google_fonts` (Inter) for a high-fidelity visual aesthetic.
- **API Client** (`lib/core/api_client.dart`): Engineered a thin singleton HTTP wrapper that attaches automated header content-types, outputs request/response logs to the console, handles parsing of FastAPI validation lists/strings, and translates errors into a structured `ApiException` throw.
- **Auth State** (`lib/services/auth_service.dart`): Designed `AuthNotifier` using Riverpod to manage authentication states asynchronously (`signup`, `login`, `logout`) and persistently save authenticated sessions to local `SharedPreferences` storage.
- **RFP Stub** (`lib/services/rfp_service.dart`): Set up placeholder structures to be filled during Task 7B.

### 3. High-Fidelity UI Screens & Reusable Widgets
- **Splash Screen** (`lib/screens/splash_screen.dart`): Beautiful deep blue animated entry with a 1.8-second delay that inspects Riverpod auth state to direct authenticated users to the dashboard and guest users to signup.
- **Signup / Auth Screen** (`lib/screens/onboarding/signup_screen.dart`): Responsive onboarding card centered inside a subtle background card. It allows toggling between signup and login seamlessly, runs inline validation rules (including custom regex parsing supporting `+` sub-addressing), handles API errors gracefully inline, and features beautiful micro-loading indicators.
- **Account Setup Screen** (`lib/screens/onboarding/account_setup_screen.dart`): Two-step questionnaire capturing primary industry (dropdown) and annual budget range (dropdown), with a drag-and-drop simulated PDF upload widget that reacts visually upon a completed mock upload.
- **Primary Button** (`lib/widgets/primary_button.dart`): Reusable elevation-free rounded button displaying text or a circular progress spinner based on loading status.
- **Labeled Field** (`lib/widgets/labeled_field.dart`): Reusable modern text field featuring top labels and custom-designed borders.

### 4. Router Setup & Main Wireframe
- **Router Configuration** (`lib/app.dart`): Wired `GoRouter` containing the onboarding routes, plus beautiful placeholder dashboards for Task 7B (`/rfp/new`, `/rfp/progress/:jobId`, `/rfp/result/:jobId`) equipped with real logout functionality.
- **Root Entry** (`lib/main.dart`): Initialized the root app wrapped inside Riverpod's `ProviderScope`.

---

## 🔍 Verification & Demonstration

We launched the Flutter dev server locally on port 5000 and used an autonomous browser subagent to test the onboarding sequence against the running FastAPI backend and Supabase instance.

### Step-by-Step Flow Captures

````carousel
![1. Signup Form Filled in](file:///e:/rfp-hackathon/rfp-agent-system/antigravity_artifacts/screenshots/31_task7a_signup_screen.png)
<!-- slide -->
![2. Account Setup Screen with Mock File Selected](file:///e:/rfp-hackathon/rfp-agent-system/antigravity_artifacts/screenshots/32_task7a_account_setup.png)
<!-- slide -->
![3. Dashboard Placeholder Redirect](file:///e:/rfp-hackathon/rfp-agent-system/antigravity_artifacts/screenshots/33_task7a_rfp_dashboard.png)
<!-- slide -->
![4. Logged Out Redirect](file:///e:/rfp-hackathon/rfp-agent-system/antigravity_artifacts/screenshots/34_task7a_logged_out.png)
````

### 🎥 Interaction Video Recording
The complete, end-to-end walkthrough video is saved in the repository artifacts:
[Watch Flow Recording (WebP)](file:///e:/rfp-hackathon/rfp-agent-system/antigravity_artifacts/walkthroughs/onboarding_auth_flow.webp)

---

## 💾 Database Verification
To confirm that registration interacts properly with the live backend, we queried the `organizations` database table using the FastAPI configuration after submitting the signup form.

**Verification Log Output:**
```
Backend path: e:\rfp-hackathon\rfp-agent-system\backend
Query results:
ID: 177df57b-02d8-4690-be24-0e3d16dd965d, Name: Acme Procure Task7A, Email: testtask7a@example.com
```

The database row successfully saved and returned the auto-generated UUID organization ID!

---

## 🐞 Fixes Applied
During testing, our browser subagent ran into an inline validator rejection when attempting to register using the email format `test+task7a_unique1@example.com`. 
- **Root Cause:** The default RegExp validator in `signup_screen.dart` strictly filtered out `+` characters.
- **Resolution:** Updated the regular expression pattern to `r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$'` in `signup_screen.dart:214` to natively allow standard sub-addressing in email configurations, bringing the client completely in sync with the FastAPI backend's Pydantic `EmailStr` format.
