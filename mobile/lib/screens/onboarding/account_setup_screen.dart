import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/primary_button.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({Key? key}) : super(key: key);

  @override
  State<AccountSetupScreen> createState() =>
      _AccountSetupScreenState();
}

class _AccountSetupScreenState
    extends State<AccountSetupScreen>
    with TickerProviderStateMixin {
  String? _selectedIndustry;
  String? _selectedBudget;
  String? _uploadedFileName;

  bool _isUploading = false;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _industries = [
    'Government',
    'IT',
    'Healthcare',
    'Construction',
    'Other',
  ];

  final List<String> _budgets = [
    'Under \$100k',
    '\$100k - \$500k',
    '\$500k - \$2M',
    '\$2M+',
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    super.dispose();
  }

  void _simulateUpload() async {
    setState(() {
      _isUploading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    setState(() {
      _uploadedFileName =
          'procurement_policy_v2.pdf (1.8 MB)';
      _isUploading = false;
    });
  }

  void _complete() {
    context.go('/rfp/new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
            left: -40,
            child: _buildGlow(
              size: 240,
              color: Colors.blue.withOpacity(0.16),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -60,
            child: _buildGlow(
              size: 280,
              color: Colors.indigo.withOpacity(0.14),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
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
                          maxWidth: 440,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 16,
                              sigmaY: 16,
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(
                                        32),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.18),
                                    blurRadius: 40,
                                    offset:
                                        const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  // Step badge
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                              0xFF16A34A)
                                          .withOpacity(
                                              0.18),
                                      borderRadius:
                                          BorderRadius
                                              .circular(30),
                                      border: Border.all(
                                        color: const Color(
                                                0xFF22C55E)
                                            .withOpacity(
                                                0.28),
                                      ),
                                    ),
                                    child: const Text(
                                      'STEP 2 OF 2',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: Color(
                                            0xFFBBF7D0),
                                        letterSpacing:
                                            1,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 28),

                                  // Heading
                                  const Text(
                                    'Tell us about your organization',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          Colors.white,
                                      letterSpacing:
                                          -1,
                                      height: 1.08,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 12),

                                  Text(
                                    'This helps our AI agents tailor procurement workflows, compliance auditing, and RFP generation to your organization.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white
                                          .withOpacity(
                                              0.72),
                                      height: 1.6,
                                      letterSpacing:
                                          0.2,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 34),

                                  // Industry
                                  _buildLabel(
                                    'Primary Industry',
                                  ),

                                  const SizedBox(
                                      height: 10),

                                  _buildDropdown(
                                    value:
                                        _selectedIndustry,
                                    hint:
                                        'Select your industry',
                                    items:
                                        _industries,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedIndustry =
                                            val;
                                      });
                                    },
                                  ),

                                  const SizedBox(
                                      height: 22),

                                  // Budget
                                  _buildLabel(
                                    'Annual Procurement Budget',
                                  ),

                                  const SizedBox(
                                      height: 10),

                                  _buildDropdown(
                                    value:
                                        _selectedBudget,
                                    hint:
                                        'Select procurement budget range',
                                    items:
                                        _budgets,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedBudget =
                                            val;
                                      });
                                    },
                                  ),

                                  const SizedBox(
                                      height: 28),

                                  // Upload
                                  _buildLabel(
                                    'Compliance Policy (Optional)',
                                  ),

                                  const SizedBox(
                                      height: 10),

                                  GestureDetector(
                                    onTap:
                                        _isUploading
                                            ? null
                                            : _simulateUpload,
                                    child:
                                        AnimatedContainer(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            220,
                                      ),
                                      width:
                                          double.infinity,
                                      padding:
                                          const EdgeInsets
                                              .all(24),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                                0.05),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    24),
                                        border:
                                            Border.all(
                                          color: _uploadedFileName !=
                                                  null
                                              ? const Color(
                                                      0xFF22C55E)
                                                  .withOpacity(
                                                      0.5)
                                              : Colors
                                                  .white
                                                  .withOpacity(
                                                      0.10),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration:
                                                const Duration(
                                              milliseconds:
                                                  220,
                                            ),
                                            width: 64,
                                            height: 64,
                                            decoration:
                                                BoxDecoration(
                                              shape: BoxShape
                                                  .circle,
                                              gradient:
                                                  LinearGradient(
                                                colors:
                                                    _uploadedFileName !=
                                                            null
                                                        ? [
                                                            const Color(
                                                                0xFF16A34A),
                                                            const Color(
                                                                0xFF22C55E),
                                                          ]
                                                        : [
                                                            const Color(
                                                                0xFF2563EB),
                                                            const Color(
                                                                0xFF1D4ED8),
                                                          ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (_uploadedFileName !=
                                                              null
                                                          ? const Color(
                                                              0xFF22C55E)
                                                          : const Color(
                                                              0xFF2563EB))
                                                      .withOpacity(
                                                          0.28),
                                                  blurRadius:
                                                      24,
                                                  offset:
                                                      const Offset(
                                                          0,
                                                          12),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _uploadedFileName !=
                                                      null
                                                  ? Icons
                                                      .check_rounded
                                                  : Icons
                                                      .cloud_upload_rounded,
                                              color: Colors
                                                  .white,
                                              size: 30,
                                            ),
                                          ),

                                          const SizedBox(
                                              height:
                                                  18),

                                          Text(
                                            _uploadedFileName ??
                                                'Upload procurement policy (.pdf)',
                                            textAlign:
                                                TextAlign
                                                    .center,
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  15,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              color: Colors
                                                  .white,
                                            ),
                                          ),

                                          const SizedBox(
                                              height:
                                                  8),

                                          Text(
                                            _uploadedFileName !=
                                                    null
                                                ? 'File uploaded successfully'
                                                : 'Used by the Auditor Agent to enforce custom procurement rules.',
                                            textAlign:
                                                TextAlign
                                                    .center,
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  13,
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                      0.62),
                                              height:
                                                  1.5,
                                            ),
                                          ),

                                          if (_isUploading) ...[
                                            const SizedBox(
                                                height:
                                                    18),
                                            SizedBox(
                                              width: 22,
                                              height:
                                                  22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors
                                                      .white
                                                      .withOpacity(
                                                          0.9),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 36),

                                  // CTA
                                  PrimaryButton(
                                    text:
                                        'Continue',
                                    onPressed:
                                        _complete,
                                  ),

                                  const SizedBox(
                                      height: 14),

                                  // Skip
                                  SizedBox(
                                    width:
                                        double.infinity,
                                    child: TextButton(
                                      onPressed:
                                          _complete,
                                      child: Text(
                                        'Skip for now',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                                  0.68),
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          fontSize:
                                              14,
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
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF172554),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      hint: Text(
        hint,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 14,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        filled: true,
        fillColor:
            Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color:
            Colors.white.withOpacity(0.92),
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