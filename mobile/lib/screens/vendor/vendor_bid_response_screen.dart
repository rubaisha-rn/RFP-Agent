import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';

class VendorBidResponseScreen extends ConsumerStatefulWidget {
  final String jobId;
  const VendorBidResponseScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<VendorBidResponseScreen> createState() => _VendorBidResponseScreenState();
}

class _VendorBidResponseScreenState extends ConsumerState<VendorBidResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidController = TextEditingController();
  final _summaryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bidController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final vendorId = ref.read(vendorAuthProvider)?.id;
      if (vendorId == null) throw Exception('Vendor not logged in');

      await ref.read(vendorServiceProvider).submitResponse(
        vendorId: vendorId,
        jobId: widget.jobId,
        bidAmountPkr: num.parse(_bidController.text),
        technicalSummary: _summaryController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid response submitted successfully')));
        context.go('/vendor/inbox/$vendorId');
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message.contains('already submitted')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already submitted a response to this RFP')));
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
        title: const Text('Submit Bid Response'),
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please enter your final bid amount and a technical summary of your proposal.',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Bid Amount (PKR)',
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    hintText: 'e.g. 150000',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final numValue = num.tryParse(v);
                      if (numValue == null) return 'Must be a number';
                      if (numValue <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Technical Summary',
                    controller: _summaryController,
                    maxLines: 8,
                    hintText: 'Provide a brief summary of your technical proposal...',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 50) return 'Minimum 50 characters';
                      if (v.length > 2000) return 'Maximum 2000 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _summaryController,
                    builder: (context, value, child) {
                      return Text(
                        '${value.text.length} / 2000 characters',
                        style: TextStyle(color: value.text.length > 2000 ? Colors.red : Colors.grey, fontSize: 12),
                      );
                    },
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
                          : const Text('Submit Bid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
