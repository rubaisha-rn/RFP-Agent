import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/job_status.dart';
import '../../services/rfp_service.dart';

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
        setState(() {
          _currentStatus = status;
        });

        if (status.isFailed) {
          setState(() {
            _hasError = true;
            _errorMsg = "Pipeline failed at agent: ${status.agentDisplayName}";
          });
          _subscription?.cancel();
        } else if (status.isComplete) {
          _subscription?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go('/rfp/preview/${widget.jobId}');
            }
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

  // Determine stage states
  // Returns: 'done', 'running', 'pending'
  String _getStageState(String stage) {
    if (_currentStatus == null) return 'pending';
    if (_currentStatus!.isComplete) return 'done';
    if (_currentStatus!.isFailed) {
      // If it failed and this is the failed agent, show failed or pending
      if (_currentStatus!.currentAgent == stage) return 'failed';
    }

    final current = _currentStatus!.currentAgent;
    final pct = _currentStatus!.progressPct;

    switch (stage) {
      case 'classifier':
        if (pct > 25 || current == 'auditor' || current == 'vendor_intel' || current == 'drafter') {
          return 'done';
        }
        return (current == 'classifier') ? 'running' : 'pending';
      case 'auditor':
        if (pct > 50 || current == 'vendor_intel' || current == 'drafter') {
          return 'done';
        }
        return (current == 'auditor') ? 'running' : 'pending';
      case 'vendor_intel':
        if (pct > 75 || current == 'drafter') {
          return 'done';
        }
        return (current == 'vendor_intel') ? 'running' : 'pending';
      case 'drafter':
        return (current == 'drafter') ? 'running' : 'pending';
      default:
        return 'pending';
    }
  }

  Widget _buildAgentRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required String state,
  }) {
    Color iconColor = const Color(0xFF9CA3AF);
    Widget badge = const SizedBox();

    if (state == 'done') {
      iconColor = AppTheme.accentColor;
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
          ],
        ),
      );
    } else if (state == 'running') {
      iconColor = const Color(0xFFF59E0B);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB45309))),
            ),
            SizedBox(width: 6),
            Text(
              'Running',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    } else if (state == 'failed') {
      iconColor = const Color(0xFFEF4444);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 12, color: Color(0xFFB91C1C)),
            SizedBox(width: 4),
            Text(
              'Failed',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
      );
    } else {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state == 'running'
                  ? const Color(0xFFFEF3C7)
                  : state == 'done'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: state == 'pending' ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          badge,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusVal = _currentStatus;
    final progressPct = statusVal?.progressPct ?? 0;
    final traceCount = statusVal?.traceCount ?? 0;

    return PopScope(
      canPop: false, // User cannot swipe or click back button to interrupt pipeline
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text(
            'Generating RFP',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          automaticallyImplyLeading: false, // Disable leading back arrow
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Climbing trace count chip
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.psychology, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '$traceCount reasoning steps logged',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_hasError) ...[
                    // Circular Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: progressPct / 100,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$progressPct%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'RFP Agent Pipeline Active',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusVal == null 
                          ? 'Starting agent tasks...'
                          : 'Currently: ${statusVal.agentDisplayName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),

                    // 4 Agent steps
                    _buildAgentRow(
                      title: 'Requirements Classifier',
                      subtitle: 'Extracts category, bidding method & certifications',
                      icon: Icons.search,
                      state: _getStageState('classifier'),
                    ),
                    _buildAgentRow(
                      title: 'Compliance Auditor',
                      subtitle: 'Validates against PPRA regulations scorecard',
                      icon: Icons.gavel,
                      state: _getStageState('auditor'),
                    ),
                    _buildAgentRow(
                      title: 'Vendor Intelligence',
                      subtitle: 'Finds top vendors & handles conflicts of interest',
                      icon: Icons.people,
                      state: _getStageState('vendor_intel'),
                    ),
                    _buildAgentRow(
                      title: 'Drafter & Executor',
                      subtitle: 'Generates document PDF & schedules actions',
                      icon: Icons.description,
                      state: _getStageState('drafter'),
                    ),
                  ] else ...[
                    // Failed Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF4444),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pipeline Execution Interrupted',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMsg ?? 'An unexpected network error occurred.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F1D1D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.go('/rfp/new');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Back to Home', style: TextStyle(color: Color(0xFF374151))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _startListening,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Retry Connection'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Debug view raw status JSON
                  ExpansionTile(
                    title: const Text(
                      'View raw progress logs',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            statusVal != null
                                ? const JsonEncoder.withIndent('  ').convert(statusVal.toJson())
                                : 'No log data fetched yet.',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ],
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
