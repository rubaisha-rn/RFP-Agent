import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';

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

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                'Compiling success summary...',
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
        appBar: AppBar(title: const Text('RFP Dispatched')),
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
                  'Failed to compile summary',
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
    final referenceId = portal?.referenceId ?? 'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';

    // Metrics extracted dynamically from live records
    final emailCount = res.emails.length;
    final eventCount = res.calendarEvents.length;
    final postingCount = portal != null ? 1 : 0;
    final stepsCount = res.traces.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Emerald check ring
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'RFP Dispatched Successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reference ID: $referenceId',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Metrics List
                _buildMetricTile(
                  icon: Icons.mail_outline,
                  value: '$emailCount Emails Sent',
                  label: 'Secure invitations delivered to selected vendors.',
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                _buildMetricTile(
                  icon: Icons.event,
                  value: '$eventCount Calendar Events',
                  label: 'Pre-bid meeting, technical submission & opening dates scheduled.',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                _buildMetricTile(
                  icon: Icons.public,
                  value: '$postingCount Portal Posting Created',
                  label: 'Tender officially cataloged and published under PPRA regulations.',
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 12),
                _buildMetricTile(
                  icon: Icons.psychology,
                  value: '$stepsCount Reasoning Steps Logged',
                  label: 'AI-agent compliance, conflict & drafting audit records stored.',
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 32),

                // Actions buttons
                ElevatedButton(
                  onPressed: () {
                    context.go('/rfp/result/${widget.jobId}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'View Results Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.go('/rfp/new');
                  },
                  child: const Text(
                    'Start New RFP',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
