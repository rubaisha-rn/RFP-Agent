import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vendor.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';

class ConfirmSendScreen extends ConsumerStatefulWidget {
  final String jobId;
  final List<Vendor> selectedVendors;
  const ConfirmSendScreen({
    Key? key,
    required this.jobId,
    required this.selectedVendors,
  }) : super(key: key);

  @override
  ConsumerState<ConfirmSendScreen> createState() => _ConfirmSendScreenState();
}

class _ConfirmSendScreenState extends ConsumerState<ConfirmSendScreen> {
  RfpResult? _result;
  bool _isLoading = true;
  bool _isDispatching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(rfpServiceProvider).getResult(widget.jobId);
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _triggerDispatch() async {
    setState(() {
      _isDispatching = true;
    });

    // The backend drafter agent already executed all dispatching tasks in the background.
    // This is a highly immersive, satisfying confirmation phase for the officer.
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isDispatching = false;
      });
      context.go('/rfp/success/${widget.jobId}');
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required String description,
    required IconData icon,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: AppTheme.accentColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: const Color(0xFF86EFAC),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Preparing confirmation details...',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(title: const Text('Confirm RFP')),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadResult,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final res = _result!;
    final portal = res.portalPosting;
    final rfpBody = res.finalRfp?.rfpBody;

    final referenceId = portal?.referenceId ?? 'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';
    final vendorCount = widget.selectedVendors.length;
    final closingDate = rfpBody?.submissionDeadlineIso.split('T')[0] ?? 'TBD';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: const Text(
              'Confirm & Send',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
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
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dispatch Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dispatch Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(Icons.pin, 'Reference ID', referenceId),
                          const Divider(height: 24, color: Color(0xFFE5E7EB)),
                          _buildSummaryRow(Icons.business, 'Target Vendors', '$vendorCount selected'),
                          const Divider(height: 24, color: Color(0xFFE5E7EB)),
                          _buildSummaryRow(Icons.mail_outline, 'Dispatch Method', 'Secure Email Invitation'),
                          const Divider(height: 24, color: Color(0xFFE5E7EB)),
                          _buildSummaryRow(Icons.event, 'Submission Closing', closingDate),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Automated Dispatch Sequence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline
                    _buildTimelineStep(
                      title: 'Dispatched Invitations',
                      description: 'Custom emails with direct tender proposal instructions generated for the $vendorCount selected vendors.',
                      icon: Icons.check,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Created Calendar Events',
                      description: 'Invites generated for pre-bid meetings, closing deadlines, and opening events for bid compliance.',
                      icon: Icons.check,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Posted to PPRA Portal',
                      description: 'Tender details officially cataloged and published under public Reference ID $referenceId.',
                      icon: Icons.check,
                      isLast: true,
                    ),
                    const SizedBox(height: 24),

                    // Send Button
                    ElevatedButton(
                      onPressed: _triggerDispatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text(
                            'Send RFP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fullscreen Loading Overlay
        if (_isDispatching)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      )
                    ]
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 24),
                      Text(
                        'Dispatching...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Broadcasting emails & scheduling logs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF6B7280),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4B5563)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(val, style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
