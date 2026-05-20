import '../../utils/platform_utils.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';

class ResultDashboardScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ResultDashboardScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<ResultDashboardScreen> createState() => _ResultDashboardScreenState();
}

class _ResultDashboardScreenState extends ConsumerState<ResultDashboardScreen> {
  RfpResult? _result;
  bool _isLoading = true;
  String? _errorMessage;

  // Selected agent filter for reasoning audit trail
  String _selectedAgentFilter = 'All';

  // Set of expanded trace indices
  final Set<int> _expandedTraceIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
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

  void _downloadPdf() {
    final docId = _result?.document?.id;
    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No generated document available to download.')),
      );
      return;
    }

    final downloadUrl = '${ApiConstants.baseUrl}/documents/$docId/download';
    print('[ResultDashboardScreen] Opening download URL: $downloadUrl');

    if (kIsWeb) {
      openInBrowser(downloadUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download URL: $downloadUrl (only open tab on web)')),
      );
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final year = dt.year;
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute';
    } catch (_) {
      if (isoString.length >= 16) {
        return isoString.replaceAll('T', ' ').substring(0, 16);
      }
      return isoString;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)} Crore';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  // Common card wrapper to match preview_screen.dart visual style
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailingHeader,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                if (trailingHeader != null) trailingHeader,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: AppTheme.accentColor),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDot(String label, bool run) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: run ? AppTheme.accentColor.withOpacity(0.15) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            border: Border.all(
              color: run ? AppTheme.accentColor : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              run ? Icons.check : Icons.radio_button_unchecked,
              size: 14,
              color: run ? AppTheme.accentColor : const Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: run ? FontWeight.bold : FontWeight.normal,
            color: run ? AppTheme.primaryColor : const Color(0xFF6B7280),
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
              const SizedBox(height: 16),
              const Text(
                'Loading procurement analysis & audit trail...',
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
        appBar: AppBar(
          title: const Text('RFP Results Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/rfp/new'),
          ),
        ),
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
                  'Job Not Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'The job ID "${widget.jobId}" could not be retrieved from the database.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/rfp/new'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final res = _result!;
    final job = res.job;
    final compliance = res.compliance;
    final vendorIntel = res.vendorIntel;
    final portalPosting = res.portalPosting;
    final document = res.document;
    final tracesList = res.traces;

    // Determine agent timeline progress
    final bool classifierCompleted = tracesList.any((t) => t is Map<String, dynamic> && t['agent_name'] == 'classifier');
    final bool auditorCompleted = tracesList.any((t) => t is Map<String, dynamic> && t['agent_name'] == 'auditor');
    final bool vendorIntelCompleted = tracesList.any((t) => t is Map<String, dynamic> && t['agent_name'] == 'vendor_intel');
    final bool drafterCompleted = tracesList.any((t) => t is Map<String, dynamic> && t['agent_name'] == 'drafter');

    // Status styling
    Color statusBgColor = const Color(0xFFF3F4F6);
    Color statusTextColor = const Color(0xFF4B5563);
    if (job.status == 'completed') {
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
    } else if (job.status == 'failed') {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFEF4444);
    } else if (job.status == 'running' || job.status == 'pending') {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
    }

    // Ref ID
    final refIdStr = portalPosting?.referenceId ?? 'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Results Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/rfp/new'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1. Header Card (RFP Pipeline Summary)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RFP REFERENCE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    refIdStr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: Color(0xFF9CA3AF)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      copyToClipboard(refIdStr);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Reference ID copied to clipboard!')),
                                      );
                                    },
                                    tooltip: 'Copy ID',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Horizontal Agent Pipeline Timeline
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildAgentDot('Classifier', classifierCompleted)),
                            Container(width: 24, height: 2, color: const Color(0xFFE5E7EB)),
                            Expanded(child: _buildAgentDot('Auditor', auditorCompleted)),
                            Container(width: 24, height: 2, color: const Color(0xFFE5E7EB)),
                            Expanded(child: _buildAgentDot('Vendor Intel', vendorIntelCompleted)),
                            Container(width: 24, height: 2, color: const Color(0xFFE5E7EB)),
                            Expanded(child: _buildAgentDot('Drafter', drafterCompleted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${_formatDateTime(job.createdAt)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Completed: ${_formatDateTime(job.completedAt)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.psychology, size: 14, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  '${tracesList.length} reasoning steps',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Compliance Scorecard Card
                _buildCard(
                  title: 'Compliance Scorecard',
                  icon: Icons.gavel,
                  trailingHeader: compliance != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (compliance.complianceScore >= 80)
                                ? const Color(0xFFDCFCE7)
                                : (compliance.complianceScore >= 60)
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${compliance.complianceScore.toStringAsFixed(0)}/100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (compliance.complianceScore >= 80)
                                  ? const Color(0xFF16A34A)
                                  : (compliance.complianceScore >= 60)
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFEF4444),
                            ),
                          ),
                        )
                      : null,
                  children: compliance != null
                      ? [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bidding Method', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      compliance.confirmedBiddingMethod.isNotEmpty
                                          ? compliance.confirmedBiddingMethod
                                          : 'Single Stage One Envelope',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Integrity Pact', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: compliance.integrityPactRequired
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      compliance.integrityPactRequired ? 'Required' : 'Not Required',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: compliance.integrityPactRequired
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          const Text('Advertisement Required', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: compliance.advertisementRequirements.entries.map((entry) {
                              final bool req = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: req ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: req ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      req ? Icons.check_circle : Icons.cancel,
                                      size: 12,
                                      color: req ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      entry.key.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: req ? const Color(0xFF15803D) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          const Text('Mandatory PPRA Clauses Checked', style: TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          if (compliance.mandatoryClauses.isNotEmpty)
                            ...compliance.mandatoryClauses.map((clause) => _buildBulletPoint(clause)).toList()
                          else
                            const Text('No mandatory clauses explicitly generated.', style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ]
                      : [
                          const Center(
                            child: Text(
                              'Compliance Audit Not Executed',
                              style: TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                            ),
                          )
                        ],
                ),

                // 3. Vendor Shortlist Card
                _buildCard(
                  title: 'Vendor Shortlist',
                  icon: Icons.people_outline,
                  trailingHeader: vendorIntel != null
                      ? Text(
                          'Evaluated: ${vendorIntel.totalVendorsEvaluated}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                        )
                      : null,
                  children: vendorIntel != null && vendorIntel.shortlist.isNotEmpty
                      ? [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vendorIntel.shortlist.length,
                            itemBuilder: (context, index) {
                              final vendor = vendorIntel.shortlist[index];
                              final bool hasSoftFlag = vendor.conflictStatus.isNotEmpty &&
                                  vendor.conflictStatus.toLowerCase() != 'none' &&
                                  vendor.conflictStatus.toLowerCase() != 'clear';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Rank Number Badge
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Vendor Name & Bid Range
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  vendor.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      vendor.score.toStringAsFixed(1),
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Predicted Bid: PKR ${_formatCurrency(vendor.predictedBidPkr)}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                                          ),
                                          
                                          if (hasSoftFlag) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFDE68A)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFD97706)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'FLAGGED: ${vendor.conflictStatus}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // General predicted bid range
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.analytics_outlined, size: 18, color: AppTheme.accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Global Bid range: PKR ${_formatCurrency(vendorIntel.predictedBidRangePkr.min)} - ${_formatCurrency(vendorIntel.predictedBidRangePkr.max)} (Median: PKR ${_formatCurrency(vendorIntel.predictedBidRangePkr.median)})',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ]
                      : [
                          const Center(
                            child: Text(
                              'No Shortlisted Vendors Generated',
                              style: TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                            ),
                          )
                        ],
                ),

                // 4. Actions Simulated Card
                _buildCard(
                  title: 'Actions Executed by Drafter Agent',
                  icon: Icons.play_arrow,
                  children: [
                    
                    // Row 1: Document Generated
                    _buildTimelineItem(
                      icon: Icons.description,
                      iconColor: AppTheme.primaryColor,
                      title: 'RFP Document Synthesized',
                      subtitle: document != null
                          ? 'PDF compiled successfully aligned with PPRA rules.'
                          : 'RFP document file not generated.',
                      isLast: false,
                      child: document != null
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      document.filePath.split('/').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: _downloadPdf,
                                    icon: const Icon(Icons.download, size: 14),
                                    label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),

                    // Row 2: Invitation Emails
                    _buildTimelineItem(
                      icon: Icons.mail_outline,
                      iconColor: const Color(0xFF3B82F6),
                      title: '${res.emails.length} Invitation Emails Dispatched',
                      subtitle: 'Direct bidding invites sent electronically with unique RFP reference.',
                      isLast: false,
                      child: res.emails.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ExpansionTile(
                                leading: const Icon(Icons.mail, size: 18, color: Color(0xFF6B7280)),
                                title: const Text(
                                  'Review Dispatched Mail Logs',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                                ),
                                children: res.emails.map((email) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                                      color: Color(0xFFF9FAFB),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'To: ${email.toName} (${email.toEmail})',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                                            ),
                                            const Text('Sent', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Subject: ${email.subject}',
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Color(0xFF4B5563)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                          ),
                                          child: Text(
                                            email.body,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          : null,
                    ),

                    // Row 3: Calendar Events
                    _buildTimelineItem(
                      icon: Icons.calendar_month,
                      iconColor: const Color(0xFFF59E0B),
                      title: '${res.calendarEvents.length} Calendar Events Scheduled',
                      subtitle: 'Milestones mapped dynamically into organizational schedule.',
                      isLast: false,
                      child: res.calendarEvents.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ExpansionTile(
                                leading: const Icon(Icons.event, size: 18, color: Color(0xFF6B7280)),
                                title: const Text(
                                  'Review Organizational Schedules',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                                ),
                                children: res.calendarEvents.map((evt) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                                      color: Color(0xFFF9FAFB),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          evt.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Scheduled: ${evt.eventDate.split("T")[0]}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFD97706)),
                                        ),
                                        if (evt.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            evt.description,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          children: evt.attendees.map((att) => Chip(
                                            label: Text(att, style: const TextStyle(fontSize: 9)),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          )).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          : null,
                    ),

                    // Row 4: Portal Posting
                    _buildTimelineItem(
                      icon: Icons.public,
                      iconColor: AppTheme.accentColor,
                      title: portalPosting != null
                          ? 'Tender Posted to PPRA Portal'
                          : 'Tender Publication Pending',
                      subtitle: portalPosting != null
                          ? 'Official catalog posting cataloged under PPRA rules.'
                          : 'Not posted to portal yet.',
                      isLast: true,
                      child: portalPosting != null
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reference ID: ${portalPosting.referenceId}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      openInBrowser(portalPosting.postedUrl);
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link, size: 14, color: AppTheme.primaryColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            portalPosting.postedUrl,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                              decoration: TextDecoration.underline,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ],
                ),

                // 5. Agent Reasoning Trace Card (The Audit Trail)
                _buildCard(
                  title: 'Agent Reasoning Trace Audit',
                  icon: Icons.search,
                  children: [
                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          'Classifier',
                          'Auditor',
                          'Vendor Intel',
                          'Drafter'
                        ].map((filter) {
                          final isSelected = _selectedAgentFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedAgentFilter = filter;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scrollable List container
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: _buildFilteredTracesList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLast,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Timeline graphics)
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: child != null ? 140 : 45,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 14),
        
        // Right Column (Text contents)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              if (child != null) child,
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredTracesList() {
    final res = _result!;
    final tracesList = res.traces;

    // Filter list
    final List<dynamic> filteredTraces = tracesList.where((trace) {
      if (trace is! Map<String, dynamic>) return false;
      if (_selectedAgentFilter == 'All') return true;
      
      final String agentName = trace['agent_name'] ?? '';
      if (_selectedAgentFilter == 'Classifier' && agentName == 'classifier') return true;
      if (_selectedAgentFilter == 'Auditor' && agentName == 'auditor') return true;
      if (_selectedAgentFilter == 'Vendor Intel' && agentName == 'vendor_intel') return true;
      if (_selectedAgentFilter == 'Drafter' && agentName == 'drafter') return true;

      return false;
    }).toList();

    if (filteredTraces.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No reasoning steps logged for this agent.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filteredTraces.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final trace = filteredTraces[index] as Map<String, dynamic>;
        final String agentName = trace['agent_name'] ?? '';
        final int stepNumber = trace['step_number'] ?? (index + 1);
        final String reasoning = trace['reasoning'] ?? '';
        final bool isExpanded = _expandedTraceIndices.contains(stepNumber);

        // Color & Name configuration
        Color agentColor = Colors.grey;
        String agentLabel = agentName.toUpperCase();
        if (agentName == 'classifier') {
          agentColor = Colors.blue;
          agentLabel = 'Classifier';
        } else if (agentName == 'auditor') {
          agentColor = Colors.purple;
          agentLabel = 'Compliance Auditor';
        } else if (agentName == 'vendor_intel') {
          agentColor = Colors.orange;
          agentLabel = 'Vendor Intel';
        } else if (agentName == 'drafter') {
          agentColor = Colors.green;
          agentLabel = 'Drafter';
        }

        return InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedTraceIndices.remove(stepNumber);
              } else {
                _expandedTraceIndices.add(stepNumber);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent indicator circle
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: agentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: agentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              agentLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: agentColor,
                              ),
                            ),
                          ),
                          Text(
                            'Step #$stepNumber',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reasoning,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
