// DEPRECATED: Use SignupScreen with initialRole: UserRole.vendor instead.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/shared_ui.dart';

class VendorLoginScreen extends ConsumerStatefulWidget {
  final String? returnTo;
  const VendorLoginScreen({Key? key, this.returnTo}) : super(key: key);

  @override
  ConsumerState<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends ConsumerState<VendorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final org = await ref.read(vendorAuthProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      print('[VENDOR LOGIN] org.id = "${org.id}"');
      print('[VENDOR LOGIN] returnTo = "${widget.returnTo}"');

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
          GoRouter.of(context).pushReplacement(widget.returnTo!);
        } else {
          GoRouter.of(context).pushReplacement('/vendor/inbox/${org.id}');
        }
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2918),
      body: Column(
        children: [

          // ── Vendor branded header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 24,
              left: 24, right: 24, bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16A34A), Color(0xFF0A2918)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Vendor Portal',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to view your RFP invitations and submit bids.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55), height: 1.4),
                ),
              ],
            ),
          ),

          // ── Form panel ───────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FB),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPadding + 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 17),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const VFieldLabel(text: 'Work email'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: 'bids@yourcompany.pk',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 18),

                      const VFieldLabel(text: 'Password'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 28),

                      VendorPrimaryButton(
                        text: 'Sign in',
                        isLoading: _isLoading,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: VToggleAuthButton(
                          message: "Don't have an account?  ",
                          action: 'Sign up',
                          onTap: () => context.go('/vendor/signup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}