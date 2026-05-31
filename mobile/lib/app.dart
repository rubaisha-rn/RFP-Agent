import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/signup_screen.dart';
import 'screens/onboarding/account_setup_screen.dart';
import 'screens/rfp/brief_input_screen.dart';
import 'screens/rfp/progress_screen.dart';
import 'screens/rfp/preview_screen.dart';
import 'screens/rfp/contacts_select_screen.dart';
import 'screens/rfp/confirm_send_screen.dart';
import 'screens/rfp/success_screen.dart';
import 'screens/rfp/result_dashboard_screen.dart';
import 'models/vendor.dart';
import 'services/auth_service.dart';

class RfpAgentApp extends ConsumerWidget {
  const RfpAgentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic redirect guard based on Auth Status
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final org = ref.watch(authProvider);
        final loc = state.matchedLocation;
        final isSplash = loc == '/';
        final isAuth = loc == '/signup' || loc == '/login';
        final isOnboarding = loc == '/account-setup';

        if (org == null) {
          // If not logged in and not on splash or auth pages, redirect to signup
          if (!isSplash && !isAuth) {
            return '/signup';
          }
        } else {
          // If logged in and not onboarded
          if (!org.isOnboarded && !isOnboarding) {
            return '/account-setup';
          }

          // If logged in and onboarded
          if (org.isOnboarded && (isSplash || isAuth || isOnboarding)) {
            return '/rfp/new';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(isLogin: false),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SignupScreen(isLogin: true),
        ),
        GoRoute(
          path: '/account-setup',
          builder: (context, state) => const AccountSetupScreen(),
        ),
        GoRoute(
          path: '/rfp/new',
          builder: (context, state) => const BriefInputScreen(),
        ),
        GoRoute(
          path: '/rfp/progress/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return ProgressScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/rfp/preview/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return PreviewScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/rfp/contacts/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return ContactsSelectScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/rfp/confirm/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            final selectedVendors = state.extra as List<Vendor>? ?? [];
            return ConfirmSendScreen(jobId: jobId, selectedVendors: selectedVendors);
          },
        ),
        GoRoute(
          path: '/rfp/success/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return SuccessScreen(jobId: jobId);
          },
        ),
        GoRoute(
          path: '/rfp/result/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return ResultDashboardScreen(jobId: jobId);
          },
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        title: 'RFP Agent',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
