import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final bool isLogin;
  const SignupScreen({Key? key, this.isLogin = false}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isLogin) {
        await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          print('[SignupScreen] Login successful. Redirecting to /rfp/new.');
          context.go('/rfp/new');
        }
      } else {
        await ref.read(authProvider.notifier).signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          companyName: _companyNameController.text.trim(),
        );
        if (mounted) {
          print('[SignupScreen] Signup successful. Redirecting to /account-setup.');
          context.go('/account-setup');
        }
      }
    } on ApiException catch (e) {
      print('[SignupScreen] ApiException caught: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('[SignupScreen] Unexpected error caught: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isLogin ? 'Welcome back' : 'Create your account';
    final subtitle = widget.isLogin 
        ? 'Sign in to manage your procurement pipeline' 
        : 'Automate compliance, auditing, and vendor selection';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32.0),
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
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Icon / Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2A4A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF0F2A4A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'RFP Agent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2A4A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Form header
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (!widget.isLogin) ...[
                    LabeledField(
                      label: 'Company Name',
                      hintText: 'Acme Procurement Ltd.',
                      controller: _companyNameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Company name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  LabeledField(
                    label: 'Company Email',
                    hintText: 'you@company.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Company email is required';
                      }
                      if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  LabeledField(
                    label: 'Password',
                    hintText: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password is required';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: widget.isLogin ? 'Sign In' : 'Create Account',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        if (widget.isLogin) {
                          context.go('/signup');
                        } else {
                          context.go('/login');
                        }
                      },
                      child: Text(
                        widget.isLogin
                            ? "Don't have an account? Sign up"
                            : "Already have an account? Log in",
                        style: const TextStyle(
                          color: Color(0xFF0F2A4A),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/vendor/signup'),
                      child: const Text('I am a Vendor →', 
                        style: TextStyle(color: AppTheme.accentColor)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
