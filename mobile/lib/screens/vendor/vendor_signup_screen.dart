import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';

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
  
  final List<String> _availableCategories = ['goods', 'services', 'works', 'IT_services', 'consulting'];
  final Set<String> _selectedCategories = {};

  bool _isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one category')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final org = await ref.read(vendorAuthProvider.notifier).signup(
        companyName: _companyController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        ntnNumber: _ntnController.text.trim(),
        categories: _selectedCategories.toList(),
      );
      if (mounted) {
        context.go('/vendor/inbox/${org.id}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message.contains('exists')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An account with this email already exists. Please sign in instead.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Registration'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('VENDOR PORTAL', style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register your company to receive and respond to RFP invitations from government procurement agencies.',
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Company Name',
                    controller: _companyController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Vendor Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/vendor/login'),
                      child: const Text("Already registered? Sign in", style: TextStyle(color: AppTheme.primaryColor)),
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
