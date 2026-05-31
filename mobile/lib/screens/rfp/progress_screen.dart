import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/job_status.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ProgressScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  StreamSubscription<JobStatus>? _subscription;
  JobStatus? _currentStatus;
  bool _hasError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    setState(() {
      _hasError = false;
      _errorMsg = null;
    });
    _subscription?.cancel();
    _subscription = ref.read(rfpServiceProvider).watchJobStatus(widget.jobId).listen(
      (status) {
        setState(() => _currentStatus = status);
        if (status.isFailed) {
          setState(() {
            _hasError = true;
            _errorMsg = 'Pipeline failed at agent: ${status.agentDisplayName}';
          });
          _subscription?.cancel();
        } else if (status.isComplete) {
          _subscription?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go('/rfp/preview/${widget.jobId}');
          });
        }
      },
      onError: (err) {
        setState(() {
          _hasError = true;
          _errorMsg = err.toString();
        });
        _subscription?.cancel();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _getStageState(String stage) {
    if (_currentStatus == null) return 'pending';
    if (_currentStatus!.isComplete) return 'done';
    if (_currentStatus!.isFailed && _currentStatus!.currentAgent == stage) return 'failed';

    final current = _currentStatus!.currentAgent;
    final pct = _currentStatus!.progressPct;

    switch (stage) {
      case 'classifier':
        if (pct > 25 || current == 'auditor' || current == 'vendor_intel' || current == 'drafter') return 'done';
        return (current == 'classifier') ? 'running' : 'pending';
      case 'auditor':
        if (pct > 50 || current == 'vendor_intel' || current == 'drafter') return 'done';
        return (current == 'auditor') ? 'running' : 'pending';
      case 'vendor_intel':
        if (pct > 75 || current == 'drafter') return 'done';
        return (current == 'vendor_intel') ? 'running' : 'pending';
      case 'drafter':
        return (current == 'drafter') ? 'running' : 'pending';
      default:
        return 'pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusVal = _currentStatus;
    final progressPct = statusVal?.progressPct ?? 0;
    final traceCount = statusVal?.traceCount ?? 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: StyledAppBar(title: 'Generating RFP', showBack: false),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 24),
          child: Column(
            children: [
              if (!_hasError) ...[
                // Progress ring card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Column(
                    children: [
                      // Trace count chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_outlined, size: 14, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 6),
                            Text(
                              '$traceCount reasoning steps logged',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Circular progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: progressPct / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFE8EDF3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$progressPct%',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                'complete',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        statusVal == null
                            ? 'Initialising agent pipeline...'
                            : 'Running: ${statusVal.agentDisplayName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Agent steps card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_tree_outlined,
                                size: 15,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Agent pipeline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE8EDF3)),
                      _AgentStepRow(
                        title: 'Requirements Classifier',
                        subtitle: 'Extracts category, value & bidding method',
                        icon: Icons.manage_search_outlined,
                        state: _getStageState('classifier'),
                        isLast: false,
                      ),
                      _AgentStepRow(
                        title: 'Compliance Auditor',
                        subtitle: 'Validates against PPRA regulations',
                        icon: Icons.gavel_outlined,
                        state: _getStageState('auditor'),
                        isLast: false,
                      ),
                      _AgentStepRow(
                        title: 'Vendor Intelligence',
                        subtitle: 'Ranks vendors and checks conflicts',
                        icon: Icons.groups_outlined,
                        state: _getStageState('vendor_intel'),
                        isLast: false,
                      ),
                      _AgentStepRow(
                        title: 'Drafter & Executor',
                        subtitle: 'Generates PDF and schedules actions',
                        icon: Icons.description_outlined,
                        state: _getStageState('drafter'),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Raw logs
                _RawLogsExpander(statusVal: statusVal),

              ] else ...[

                // Error card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFE53935),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pipeline interrupted',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMsg ?? 'An unexpected error occurred.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryActionButton(
                              text: 'Back',
                              onTap: () => context.go('/rfp/new'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryActionButton(
                              text: 'Retry',
                              isLoading: false,
                              enabled: true,
                              onTap: _startListening,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentStepRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String state;
  final bool isLast;

  const _AgentStepRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconColor;
    Widget badge;

    switch (state) {
      case 'done':
        iconBg = const Color(0xFFF0FDF4);
        iconColor = const Color(0xFF16A34A);
        badge = _Badge(label: 'Done', color: const Color(0xFF16A34A), bg: const Color(0xFFF0FDF4));
        break;
      case 'running':
        iconBg = const Color(0xFFFFFBEB);
        iconColor = const Color(0xFFD97706);
        badge = _RunningBadge();
        break;
      case 'failed':
        iconBg = const Color(0xFFFFF1F1);
        iconColor = const Color(0xFFE53935);
        badge = _Badge(label: 'Failed', color: const Color(0xFFE53935), bg: const Color(0xFFFFF1F1));
        break;
      default:
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF94A3B8);
        badge = _Badge(label: 'Pending', color: const Color(0xFF94A3B8), bg: const Color(0xFFF1F5F9));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3))),
            ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: state == 'pending'
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          badge,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RunningBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 9,
            height: 9,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFFD97706),
            ),
          ),
          SizedBox(width: 5),
          Text(
            'Running',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}

class _RawLogsExpander extends StatelessWidget {
  final dynamic statusVal;
  const _RawLogsExpander({required this.statusVal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.terminal_outlined, size: 16, color: Color(0xFF94A3B8)),
          title: const Text(
            'View raw progress logs',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  statusVal != null
                      ? const JsonEncoder.withIndent('  ').convert(statusVal.toJson())
                      : 'No log data yet.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}