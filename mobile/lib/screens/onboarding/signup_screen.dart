import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final bool isLogin;

  const SignupScreen({
    Key? key,
    this.isLogin = false,
  }) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _companyNameController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Entrance animations only
  late AnimationController _entranceController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController =
        AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 850,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();

    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isLogin) {
        await ref
            .read(authProvider.notifier)
            .login(
              email: _emailController.text
                  .trim(),
              password:
                  _passwordController.text,
            );

        if (mounted) {
          context.go('/rfp/new');
        }
      } else {
        await ref
            .read(authProvider.notifier)
            .signup(
              email: _emailController.text
                  .trim(),
              password:
                  _passwordController.text,
              companyName:
                  _companyNameController.text
                      .trim(),
            );

        if (mounted) {
          context.go('/account-setup');
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'An unexpected error occurred';
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
    final title = widget.isLogin
        ? 'Welcome back'
        : 'Create your account';

    final subtitle = widget.isLogin
        ? 'Sign in to manage procurement workflows and vendor operations.'
        : 'Automate compliance, procurement, and vendor management with AI-powered workflows.';

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF172554),
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
          ),

          // Ambient glows
          Positioned(
            top: -90,
            left: -50,
            child: _buildGlow(
              size: 240,
              color: Colors.blue
                  .withOpacity(0.18),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -50,
            child: _buildGlow(
              size: 280,
              color: Colors.indigo
                  .withOpacity(0.14),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 430,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                                  32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 16,
                              sigmaY: 16,
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .all(30),
                              decoration:
                                  BoxDecoration(
                                color: Colors.white
                                    .withOpacity(
                                        0.08),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            32),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(
                                          0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(
                                            0.18),
                                    blurRadius: 40,
                                    offset:
                                        const Offset(
                                      0,
                                      20,
                                    ),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    // Logo
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration:
                                              BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    18),
                                            gradient:
                                                const LinearGradient(
                                              colors: [
                                                Color(
                                                    0xFF2563EB),
                                                Color(
                                                    0xFF1D4ED8),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                        0xFF2563EB)
                                                    .withOpacity(
                                                        0.35),
                                                blurRadius:
                                                    24,
                                                offset:
                                                    const Offset(
                                                  0,
                                                  12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child:
                                              const Icon(
                                            Icons
                                                .auto_awesome_rounded,
                                            color: Colors
                                                .white,
                                            size: 28,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                14),

                                        const Text(
                                          'RFP Agent',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                22,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color: Colors
                                                .white,
                                            letterSpacing:
                                                -0.4,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height: 36),

                                    // Heading
                                    Text(
                                      title,
                                      style:
                                          const TextStyle(
                                        fontSize: 34,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: Colors
                                            .white,
                                        height: 1.05,
                                        letterSpacing:
                                            -1,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 12),

                                    Text(
                                      subtitle,
                                      style:
                                          TextStyle(
                                        fontSize: 15,
                                        color: Colors
                                            .white
                                            .withOpacity(
                                                0.72),
                                        height: 1.6,
                                        letterSpacing:
                                            0.2,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 30),

                                    // Error
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            220,
                                      ),
                                      child: _errorMessage ==
                                              null
                                          ? const SizedBox
                                              .shrink()
                                          : Container(
                                              width: double
                                                  .infinity,
                                              margin:
                                                  const EdgeInsets
                                                      .only(
                                                bottom:
                                                    24,
                                              ),
                                              padding:
                                                  const EdgeInsets
                                                      .all(
                                                          16),
                                              decoration:
                                                  BoxDecoration(
                                                color: const Color(
                                                        0xFF7F1D1D)
                                                    .withOpacity(
                                                        0.28),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        18),
                                                border:
                                                    Border.all(
                                                  color: Colors
                                                      .red
                                                      .withOpacity(
                                                          0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .error_outline_rounded,
                                                    color:
                                                        Colors.white,
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          12),
                                                  Expanded(
                                                    child:
                                                        Text(
                                                      _errorMessage!,
                                                      style:
                                                          const TextStyle(
                                                        color:
                                                            Colors.white,
                                                        fontSize:
                                                            14,
                                                        height:
                                                            1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),

                                    // Company Name
                                    if (!widget
                                        .isLogin) ...[
                                      _buildLabel(
                                        'Company Name',
                                      ),

                                      const SizedBox(
                                          height:
                                              10),

                                      LabeledField(
                                        label: '',
                                        hintText:
                                            'Acme Procurement Ltd.',
                                        controller:
                                            _companyNameController,
                                        validator:
                                            (val) {
                                          if (val ==
                                                  null ||
                                              val.trim()
                                                  .isEmpty) {
                                            return 'Company name is required';
                                          }

                                          return null;
                                        },
                                      ),

                                      const SizedBox(
                                          height:
                                              22),
                                    ],

                                    // Email
                                    _buildLabel(
                                      'Company Email',
                                    ),

                                    const SizedBox(
                                        height: 10),

                                    LabeledField(
                                      label: '',
                                      hintText:
                                          'you@company.com',
                                      controller:
                                          _emailController,
                                      keyboardType:
                                          TextInputType
                                              .emailAddress,
                                      validator:
                                          (val) {
                                        if (val ==
                                                null ||
                                            val.trim()
                                                .isEmpty) {
                                          return 'Company email is required';
                                        }

                                        if (!RegExp(
                                          r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(
                                            val.trim())) {
                                          return 'Please enter a valid email';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                        height: 22),

                                    // Password
                                    _buildLabel(
                                      'Password',
                                    ),

                                    const SizedBox(
                                        height: 10),

                                    LabeledField(
                                      label: '',
                                      hintText:
                                          '••••••••',
                                      controller:
                                          _passwordController,
                                      obscureText:
                                          true,
                                      validator:
                                          (val) {
                                        if (val ==
                                                null ||
                                            val.isEmpty) {
                                          return 'Password is required';
                                        }

                                        if (val.length <
                                            6) {
                                          return 'Password must be at least 6 characters';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                        height: 34),

                                    // CTA
                                    PrimaryButton(
                                      text: widget
                                              .isLogin
                                          ? 'Sign In'
                                          : 'Create Account',
                                      onPressed:
                                          _submit,
                                      isLoading:
                                          _isLoading,
                                    ),

                                    const SizedBox(
                                        height: 22),

                                    // Toggle auth
                                    Center(
                                      child:
                                          TextButton(
                                        onPressed:
                                            () {
                                          setState(
                                            () {
                                              _errorMessage =
                                                  null;
                                            },
                                          );

                                          if (widget
                                              .isLogin) {
                                            context.go(
                                              '/signup',
                                            );
                                          } else {
                                            context.go(
                                              '/login',
                                            );
                                          }
                                        },
                                        child:
                                            RichText(
                                          text:
                                              TextSpan(
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  14,
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                      0.65),
                                            ),
                                            children: [
                                              TextSpan(
                                                text: widget.isLogin
                                                    ? "Don't have an account? "
                                                    : "Already have an account? ",
                                              ),
                                              const TextSpan(
                                                text:
                                                    'Continue',
                                                style:
                                                    TextStyle(
                                                  color: Colors
                                                      .white,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                            ],
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(
          0.92,
        ),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 80,
          sigmaY: 80,
        ),
        child: const SizedBox(),
      ),
    );
  }
}