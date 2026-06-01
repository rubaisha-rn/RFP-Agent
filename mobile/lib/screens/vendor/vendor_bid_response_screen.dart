import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/api_client.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/shared_ui.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _bidController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid response submitted successfully')),
        );
        context.go('/vendor/inbox/$vendorId');
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('already submitted')
            ? 'You have already submitted a response to this RFP.'
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
    final charCount = _summaryController.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2918),
      body: Column(
        children: [

          // ── Vendor branded header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 20,
              left: 20, right: 20, bottom: 24,
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
                    AppIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Vendor Portal',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Submit bid response',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your bid amount and technical proposal summary.',
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
                padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 17),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Enter your final bid amount and a technical summary of your proposal. Once submitted you cannot edit your response.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF15803D), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

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

                      // Bid amount
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8EDF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Bid amount',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                            LabeledField(
                              label: '',
                              hintText: 'e.g. 1500000',
                              controller: _bidController,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final numValue = num.tryParse(v);
                                if (numValue == null) return 'Must be a number';
                                if (numValue <= 0) return 'Must be greater than 0';
                                return null;
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FB),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                                border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
                              ),
                              child: const Text(
                                'Enter the amount in PKR without commas or symbols',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Technical summary
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8EDF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Technical summary',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                            TextFormField(
                              controller: _summaryController,
                              maxLines: 8,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.5),
                              decoration: const InputDecoration(
                                hintText: 'Describe your technical approach, team, past experience, and delivery plan...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
                                contentPadding: EdgeInsets.all(16),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 50) return 'Minimum 50 characters';
                                if (v.length > 2000) return 'Maximum 2000 characters';
                                return null;
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FB),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                                border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    charCount >= 50 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    size: 13,
                                    color: charCount >= 50
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    charCount < 50
                                        ? '${50 - charCount} more characters required'
                                        : 'Looks good',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: charCount >= 50
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$charCount / 2000',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: charCount > 2000
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      VendorPrimaryButton(
                        text: 'Submit bid',
                        isLoading: _isLoading,
                        onTap: _submit,
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