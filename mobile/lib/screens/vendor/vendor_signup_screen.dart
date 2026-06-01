// DEPRECATED: Use SignupScreen with initialRole: UserRole.vendor instead.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/shared_ui.dart';

class VendorSignupScreen extends ConsumerStatefulWidget {
  const VendorSignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends ConsumerState<VendorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ntnController = TextEditingController();

  final List<String> _availableCategories = [
    'goods', 'services', 'works', 'IT_services', 'consulting',
  ];
  final Set<String> _selectedCategories = {};

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ntnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one category.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final org = await ref.read(vendorAuthProvider.notifier).signup(
        companyName: _companyController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        ntnNumber: _ntnController.text.trim(),
        categories: _selectedCategories.toList(),
      );
      if (mounted) context.go('/vendor/inbox/${org.id}');
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('exists')
            ? 'An account with this email already exists. Please sign in instead.'
            : e.message;
      });
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
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'Step 1 of 1',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Register your company',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Receive and respond to RFP invitations from government procurement agencies.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55), height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
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

                      const VFieldLabel(text: 'Company name'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: 'TechNova Solutions Pvt Ltd',
                        controller: _companyController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),

                      const VFieldLabel(text: 'Work email'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: 'bids@yourcompany.pk',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      const VFieldLabel(text: 'Password'),
                      const SizedBox(height: 6),
                      LabeledField(
                        label: '',
                        hintText: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 18),

                      const VFieldLabel(text: 'NTN number'),
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
                      const SizedBox(height: 20),

                      // Category chips
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          const Text(
                            'Service categories',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Select at least 1',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
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
                          return VendorCategoryChip(
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
                      const SizedBox(height: 28),

                      VendorPrimaryButton(
                        text: 'Create vendor account',
                        isLoading: _isLoading,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: VToggleAuthButton(
                          message: 'Already registered? ',
                          action: 'Sign in',
                          onTap: () => context.go('/vendor/login'),
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