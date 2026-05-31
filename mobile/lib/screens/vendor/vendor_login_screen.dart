import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final org = await ref.read(vendorAuthProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      print('[VENDOR LOGIN] org.id = "${org.id}"');
      print('[VENDOR LOGIN] returnTo = "${widget.returnTo}"');
      print('[VENDOR LOGIN] mounted = $mounted');
      print('[VENDOR LOGIN] About to navigate to /vendor/inbox/${org.id}');

      await Future.delayed(const Duration(milliseconds: 200)); // fix race condition

      if (mounted) {
        if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
          GoRouter.of(context).pushReplacement(widget.returnTo!);
        } else {
          GoRouter.of(context).pushReplacement('/vendor/inbox/${org.id}');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        title: const Text('Vendor Login'),
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
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LabeledField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'vendor@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: '••••••••',
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
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
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/vendor/signup'),
                    child: const Text("Don't have an account? Sign up", style: TextStyle(color: AppTheme.primaryColor)),
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
