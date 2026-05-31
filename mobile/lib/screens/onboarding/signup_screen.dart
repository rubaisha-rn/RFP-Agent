import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../widgets/labeled_field.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

enum UserRole { procurementOfficer, vendor }

class SignupScreen extends ConsumerStatefulWidget {
  final bool isLogin;
  final UserRole initialRole;
  const SignupScreen({
    Key? key,
    this.isLogin = false,
    this.initialRole = UserRole.procurementOfficer,
  }) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _ntnController = TextEditingController();
  
  final List<String> _availableCategories = ['goods', 'services', 'works', 'IT_services', 'consulting'];
  final Set<String> _selectedCategories = {};

  late UserRole _selectedRole = widget.initialRole;
  String? _returnTo;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _returnTo = GoRouterState.of(context).uri.queryParameters['return_to'];
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _ntnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == UserRole.vendor && !widget.isLogin && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one category')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedRole == UserRole.procurementOfficer) {
        if (widget.isLogin) {
          await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await ref.read(authProvider.notifier).signup(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            companyName: _companyNameController.text.trim(),
          );
        }
        if (mounted) context.go('/rfp/new');
      } else {
        // Vendor flow
        if (widget.isLogin) {
          final org = await ref.read(vendorAuthProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            if (_returnTo != null && _returnTo!.isNotEmpty) {
              GoRouter.of(context).pushReplacement(_returnTo!);
            } else {
              GoRouter.of(context).pushReplacement('/vendor/inbox/${org.id}');
            }
          }
        } else {
          final org = await ref.read(vendorAuthProvider.notifier).signup(
            companyName: _companyNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            ntnNumber: _ntnController.text.trim(),
            categories: _selectedCategories.toList(),
          );
          
          if (mounted) {
            context.go('/vendor/inbox/${org.id}');
          }
        }
      }
    } on ApiException catch (e) {
      print('[SignupScreen] ApiException caught: ${e.message}');
      setState(() {
        if (e.message.contains('exists')) {
           _errorMessage = 'An account with this email already exists. Please sign in instead.';
        } else {
           _errorMessage = e.message;
        }
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
    final title = widget.isLogin ? 'Welcome back' : 'Create your account';
    final subtitle = widget.isLogin 
        ? 'Sign in to manage your procurement pipeline' 
        : 'Automate compliance, auditing, and vendor selection';

    final buttonColor = _selectedRole == UserRole.procurementOfficer
        ? AppTheme.primaryColor
        : AppTheme.accentColor;

    String buttonLabel;
    if (_selectedRole == UserRole.procurementOfficer) {
      buttonLabel = widget.isLogin ? "Sign In" : "Create Account";
    } else {
      buttonLabel = widget.isLogin ? "Sign In as Vendor" : "Create Vendor Account";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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

                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.procurementOfficer, 
                        label: Text('Procurement Officer'),
                        icon: Icon(Icons.business),
                      ),
                      ButtonSegment(
                        value: UserRole.vendor,
                        label: Text('Vendor'),
                        icon: Icon(Icons.handshake),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (Set<UserRole> newSelection) {
                      setState(() => _selectedRole = newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return _selectedRole == UserRole.procurementOfficer
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : AppTheme.accentColor.withOpacity(0.1);
                          }
                          return Colors.transparent;
                        },
                      ),
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
                    label: _selectedRole == UserRole.procurementOfficer ? 'Company Email' : 'Email',
                    hintText: 'you@company.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
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
                  const SizedBox(height: 20),

                  if (_selectedRole == UserRole.vendor && !widget.isLogin) ...[
                    LabeledField(
                      label: 'NTN Number',
                      controller: _ntnController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Categories (Select at least 1)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCategories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat.replaceAll('_', ' ')),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        if (_selectedRole == UserRole.procurementOfficer) {
                          if (widget.isLogin) {
                            context.go('/signup');
                          } else {
                            context.go('/login');
                          }
                        } else {
                          if (widget.isLogin) {
                            context.go('/vendor/signup');
                          } else {
                            context.go('/vendor/login');
                          }
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
