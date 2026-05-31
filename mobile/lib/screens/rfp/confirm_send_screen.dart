import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vendor.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

class ConfirmSendScreen extends ConsumerStatefulWidget {
  final String jobId;
  final List<Vendor> selectedVendors;
  const ConfirmSendScreen({Key? key, required this.jobId, required this.selectedVendors}) : super(key: key);

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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ref.read(rfpServiceProvider).getResult(widget.jobId);
      setState(() { _result = res; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _triggerDispatch() async {
    setState(() => _isDispatching = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isDispatching = false);
      context.go('/rfp/success/${widget.jobId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingScaffold(message: 'Preparing confirmation...');
    if (_errorMessage != null) {
      return ErrorScaffold(title: 'Confirm & Send', message: _errorMessage!, onRetry: _loadResult);
    }

    final res = _result!;
    final portal = res.portalPosting;
    final rfpBody = res.finalRfp?.rfpBody;
    final referenceId = portal?.referenceId ??
        'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';
    final vendorCount = widget.selectedVendors.length;
    final closingDate = rfpBody?.submissionDeadlineIso.split('T')[0] ?? 'TBD';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: StyledAppBar(title: 'Confirm & send'),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Summary card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.summarize_outlined, size: 15, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Dispatch summary',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE8EDF3)),
                      _SummaryRow(icon: Icons.tag_rounded, label: 'Reference ID', value: referenceId),
                      _SummaryRow(icon: Icons.business_outlined, label: 'Vendors selected', value: '$vendorCount'),
                      _SummaryRow(icon: Icons.mail_outline_rounded, label: 'Dispatch method', value: 'Secure email'),
                      _SummaryRow(icon: Icons.event_outlined, label: 'Submission closing', value: closingDate, isLast: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Vendor list
                const SectionHeader(icon: Icons.groups_outlined, text: 'Selected vendors'),
                const SizedBox(height: 10),
                ...widget.selectedVendors.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_outlined, size: 14, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            Text(v.email, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                    ],
                  ),
                )),

                const SizedBox(height: 20),

                // What happens next
                const SectionHeader(icon: Icons.bolt_outlined, text: 'What happens next'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Column(
                    children: [
                      _TimelineStep(
                        icon: Icons.mail_outline_rounded,
                        color: const Color(0xFF3B82F6),
                        title: 'Invitations dispatched',
                        subtitle: 'Custom emails sent to $vendorCount selected vendors.',
                        isLast: false,
                      ),
                      _TimelineStep(
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFFD97706),
                        title: 'Calendar events created',
                        subtitle: 'Pre-bid, submission, and opening dates scheduled.',
                        isLast: false,
                      ),
                      _TimelineStep(
                        icon: Icons.public_outlined,
                        color: const Color(0xFF16A34A),
                        title: 'Posted to PPRA portal',
                        subtitle: 'Published under reference $referenceId.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
            ),
            child: PrimaryActionButton(
              text: 'Send RFP',
              isLoading: false,
              enabled: true,
              onTap: _triggerDispatch,
              icon: Icons.send_rounded,
            ),
          ),
        ),

        // Dispatching overlay
        if (_isDispatching)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Dispatching...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Broadcasting emails and scheduling events',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
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
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3))),
            ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3))),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
        ],
      ),
    );
  }
}