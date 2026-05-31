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
import 'services/vendor_service.dart';
import 'screens/vendor/vendor_inbox_screen.dart';
import 'screens/vendor/vendor_rfp_view_screen.dart';
import 'screens/vendor/vendor_bid_response_screen.dart';

class RfpAgentApp extends ConsumerWidget {
  const RfpAgentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic redirect guard based on Auth Status
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isVendorRoute = loc.startsWith('/vendor');
        final vendorOrg = ref.read(vendorAuthProvider);
        final procOrg = ref.read(authProvider);

        print('[ROUTER REDIRECT] loc=$loc');
        print('[ROUTER REDIRECT] isVendorRoute=$isVendorRoute');
        print('[ROUTER REDIRECT] vendorOrg=${vendorOrg?.id}');
        print('[ROUTER REDIRECT] procOrg=${procOrg?.id}');

        final isPublicVendorRoute = loc.startsWith('/vendor/rfp/') 
          || loc == '/vendor/login' 
          || loc == '/vendor/signup';
        
        if (isVendorRoute) {
          if (vendorOrg == null && !isPublicVendorRoute) {
            return '/vendor/login';
          }
          return null;
        }

        final isSplash = loc == '/';
        final isAuth = loc == '/signup' || loc == '/login';
        final isOnboarding = loc == '/account-setup';

        if (procOrg == null) {
          // If not logged in and not on splash or auth pages, redirect to signup
          if (!isSplash && !isAuth) {
            return '/signup';
          }
        } else {
          // If logged in and not onboarded
          if (!procOrg.isOnboarded && !isOnboarding) {
            return '/account-setup';
          }

          // If logged in and onboarded
          if (procOrg.isOnboarded && (isSplash || isAuth || isOnboarding)) {
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
          builder: (context, state) => const SignupScreen(
            isLogin: false,
            initialRole: UserRole.procurementOfficer,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SignupScreen(
            isLogin: true,
            initialRole: UserRole.procurementOfficer,
          ),
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
        GoRoute(
          path: '/vendor/signup', 
          builder: (context, state) => const SignupScreen(
            isLogin: false,
            initialRole: UserRole.vendor,
          ),
        ),
        GoRoute(
          path: '/vendor/login', 
          builder: (context, state) => const SignupScreen(
            isLogin: true,
            initialRole: UserRole.vendor,
          ),
        ),
        GoRoute(
          path: '/vendor/inbox/:vendorId', 
          builder: (context, state) => VendorInboxScreen(
            vendorId: state.pathParameters['vendorId']!,
          ),
        ),
        GoRoute(
          path: '/vendor/rfp/:jobId', 
          builder: (context, state) => VendorRfpViewScreen(
            jobId: state.pathParameters['jobId']!,
          ),
        ),
        GoRoute(
          path: '/vendor/respond/:jobId', 
          builder: (context, state) => VendorBidResponseScreen(
            jobId: state.pathParameters['jobId']!,
          ),
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
