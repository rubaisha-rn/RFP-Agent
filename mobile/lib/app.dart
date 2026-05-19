import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/signup_screen.dart';
import 'screens/onboarding/account_setup_screen.dart';
import 'services/auth_service.dart';

class RfpAgentApp extends ConsumerWidget {
  const RfpAgentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
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
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text(
                'RFP Generator Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      context.go('/');
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'RFP Generation',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RFP input screen — coming in Task 7B',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/rfp/progress/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return Scaffold(
              body: Center(
                child: Text('RFP generation progress for job $jobId — coming in Task 7B'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/rfp/result/:jobId',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return Scaffold(
              body: Center(
                child: Text('RFP result for job $jobId — coming in Task 7B'),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'RFP Agent',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
