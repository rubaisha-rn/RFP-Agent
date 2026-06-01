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

  final List<String> _availableCategories = [
    'goods',
    'services',
    'works',
    'IT_services',
    'consulting',
  ];
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
    if (_selectedRole == UserRole.vendor &&
        !widget.isLogin &&
        _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
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
          if (mounted) context.go('/vendor/inbox/${org.id}');
        }
      }
    } on ApiException catch (e) {
      print('[SignupScreen] ApiException caught: ${e.message}');
      setState(() {
        if (e.message.contains('exists') ||
            e.message.contains('already registered')) {
          _errorMessage =
              'An account with this email already exists. Please sign in instead.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      print('[SignupScreen] Unexpected error caught: $e');
      setState(() => _errorMessage = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.isLogin;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isVendor = _selectedRole == UserRole.vendor;

    String buttonLabel;
    if (isVendor) {
      buttonLabel = isLogin ? 'Sign in as vendor' : 'Create vendor account';
    } else {
      buttonLabel = isLogin ? 'Sign in' : 'Continue';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F2A4A),
      body: Column(
        children: [

          // ── Dark branded header ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF0F2A4A)],
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'RFP Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (!isLogin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'Step 1 of 2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  isLogin ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isLogin
                      ? 'Sign in to your procurement dashboard'
                      : 'Automate compliance, auditing, and vendor selection',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── White form panel ─────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8F9FB),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPadding + 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Role toggle — custom styled ──────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _RoleTab(
                              label: 'Procurement officer',
                              icon: Icons.business_outlined,
                              selected: _selectedRole == UserRole.procurementOfficer,
                              onTap: () => setState(
                                () => _selectedRole = UserRole.procurementOfficer,
                              ),
                            ),
                            _RoleTab(
                              label: 'Vendor',
                              icon: Icons.handshake_outlined,
                              selected: _selectedRole == UserRole.vendor,
                              onTap: () => setState(
                                () => _selectedRole = UserRole.vendor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFE53935),
                                size: 17,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Organisation name
                      if (!isLogin) ...[
                        _FieldLabel(
                          text: isVendor
                              ? 'Company name'
                              : 'Organisation name',
                        ),
                        const SizedBox(height: 6),
                        LabeledField(
                          label: '',
                          hintText: isVendor
                              ? 'TechNova Solutions Pvt Ltd'
                              : 'Punjab Procurement Authority',
                          controller: _companyNameController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Organisation name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      _FieldLabel(text: 'Work email'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: isVendor
                            ? 'bids@yourcompany.pk'
                            : 'you@organisation.gov.pk',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(val.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _FieldLabel(text: 'Password'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password is required';
                          }
                          if (val.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),

                      // Vendor-only fields
                      if (isVendor && !isLogin) ...[
                        const SizedBox(height: 18),
                        _FieldLabel(text: 'NTN number'),
                        const SizedBox(height: 6),
                        LabeledField(
                          label: '',
                          hintText: '1234567',
                          controller: _ntnController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Digits only';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── Category chips — custom styled ───────────
                        Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Service categories',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Select at least 1',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((cat) {
                            final selected = _selectedCategories.contains(cat);
                            return _CategoryChip(
                              label: cat.replaceAll('_', ' '),
                              selected: selected,
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedCategories.remove(cat);
                                } else {
                                  _selectedCategories.add(cat);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 28),

                      _PrimaryActionButton(
                        text: buttonLabel,
                        isLoading: _isLoading,
                        isVendor: isVendor,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: _ToggleAuthButton(
                          isLogin: isLogin,
                          onTap: () {
                            setState(() => _errorMessage = null);
                            if (isVendor) {
                              context.go(isLogin ? '/vendor/signup' : '/vendor/login');
                            } else {
                              context.go(isLogin ? '/signup' : '/login');
                            }
                          },
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

// ── Widgets ─────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 0.1,
      ),
    );
  }
}

// Role toggle tab — replaces SegmentedButton
class _RoleTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RoleTab> createState() => _RoleTabState();
}

class _RoleTabState extends State<_RoleTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white
                : (_pressed ? const Color(0xFFDDE3EC) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.selected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category chip — matches design system
class _CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: widget.selected
              ? (_pressed ? const Color(0xFF0F2A4A) : const Color(0xFF1E3A8A))
              : (_pressed ? const Color(0xFFE8EDF3) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.selected
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFE2E8F0),
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: widget.selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// Primary button — gradient restored, supports vendor accent color
class _PrimaryActionButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final bool isVendor;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.text,
    required this.isLoading,
    required this.isVendor,
    required this.onTap,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Vendor uses accent green gradient, officer uses navy gradient
    final colors = widget.isVendor
        ? [const Color(0xFF16A34A), const Color(0xFF0F6E56)]
        : [const Color(0xFF1E3A8A), const Color(0xFF0F2A4A)];
    final pressedColors = widget.isVendor
        ? [const Color(0xFF0F6E56), const Color(0xFF085041)]
        : [const Color(0xFF0F2A4A), const Color(0xFF0A1E35)];
    final shadowColor = widget.isVendor
        ? const Color(0xFF16A34A)
        : const Color(0xFF1E3A8A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed ? pressedColors : colors,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ToggleAuthButton extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onTap;

  const _ToggleAuthButton({required this.isLogin, required this.onTap});

  @override
  State<_ToggleAuthButton> createState() => _ToggleAuthButtonState();
}

class _ToggleAuthButtonState extends State<_ToggleAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: widget.isLogin
                      ? "Don't have an account?  "
                      : "Already have an account?  ",
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
                TextSpan(
                  text: widget.isLogin ? 'Sign up' : 'Sign in',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}