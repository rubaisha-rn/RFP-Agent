import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  final String jobId;
  const SuccessScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  RfpResult? _result;
  bool _isLoading = true;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingScaffold(message: 'Compiling summary...');
    if (_errorMessage != null) {
      return ErrorScaffold(title: 'RFP Dispatched', message: _errorMessage!, onRetry: _loadResult);
    }

    final res = _result!;
    final portal = res.portalPosting;
    final referenceId = portal?.referenceId ??
        'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [

          // Dark header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RFP dispatched',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    referenceId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Metrics
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 24),
              child: Column(
                children: [
                  _MetricCard(
                    icon: Icons.mail_outline_rounded,
                    value: '${res.emails.length} emails sent',
                    subtitle: 'Invitations delivered to selected vendors',
                    color: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.calendar_month_outlined,
                    value: '${res.calendarEvents.length} events scheduled',
                    subtitle: 'Pre-bid, submission and opening dates set',
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.public_outlined,
                    value: portal != null ? '1 portal posting' : 'Posting pending',
                    subtitle: 'Tender published under PPRA regulations',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.psychology_outlined,
                    value: '${res.traces.length} reasoning steps',
                    subtitle: 'Full AI audit trail stored in database',
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 28),

                  PrimaryActionButton(
                    text: 'View results dashboard',
                    isLoading: false,
                    enabled: true,
                    onTap: () => context.go('/rfp/result/${widget.jobId}'),
                  ),
                  const SizedBox(height: 12),
                  SecondaryActionButton(
                    text: 'Start new RFP',
                    onTap: () => context.go('/rfp/new'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}