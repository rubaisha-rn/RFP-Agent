import '../../utils/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

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
  String _selectedAgentFilter = 'All';
  final Set<int> _expandedTraceIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ref.read(rfpServiceProvider).getResult(widget.jobId);
      setState(() { _result = res; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _downloadPdf() {
    final docId = _result?.document?.id;
    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available.')),
      );
      return;
    }
    final downloadUrl = '${ApiConstants.baseUrl}/documents/$docId/download';
    if (kIsWeb) {
      openInBrowser(downloadUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL: $downloadUrl')),
      );
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso.length >= 16 ? iso.replaceAll('T', ' ').substring(0, 16) : iso;
    }
  }

  String _formatCurrency(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingScaffold(message: 'Loading audit trail...');
    if (_errorMessage != null) {
      return ErrorScaffold(title: 'Results', message: _errorMessage!, onRetry: _fetchResult);
    }

    final res = _result!;
    final job = res.job;
    final compliance = res.compliance;
    final vendorIntel = res.vendorIntel;
    final portalPosting = res.portalPosting;
    final document = res.document;
    final tracesList = res.traces;
    final vendorResponses = res.vendorResponses;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final refIdStr = portalPosting?.referenceId ??
        'PPRA-2026-${widget.jobId.substring(0, 8).toUpperCase()}';

    Color statusColor;
    Color statusBg;
    switch (job.status) {
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFF0FDF4);
        break;
      case 'failed':
        statusColor = const Color(0xFFE53935);
        statusBg = const Color(0xFFFFF1F1);
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
    }

    bool agentDone(String name) =>
        tracesList.any((t) => t is Map<String, dynamic> && t['agent_name'] == name);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3))),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  AppIconButton(icon: Icons.home_outlined, onTap: () => context.go('/rfp/new')),
                  const SizedBox(width: 10),
                  const Text(
                    'Results',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.2),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference + agent timeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EDF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RFP REFERENCE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(refIdStr,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                ),
                                AppIconButton(
                                  icon: Icons.copy_rounded,
                                  size: 16,
                                  onTap: () {
                                    copyToClipboard(refIdStr);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _AgentDot(label: 'Classifier', done: agentDone('classifier')),
                      _PipelineLine(done: agentDone('auditor')),
                      _AgentDot(label: 'Auditor', done: agentDone('auditor')),
                      _PipelineLine(done: agentDone('vendor_intel')),
                      _AgentDot(label: 'Vendors', done: agentDone('vendor_intel')),
                      _PipelineLine(done: agentDone('drafter')),
                      _AgentDot(label: 'Drafter', done: agentDone('drafter')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(_formatDateTime(job.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology_outlined, size: 12, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 4),
                            Text('${tracesList.length} steps',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Compliance scorecard
            DashCard(
              title: 'Compliance scorecard',
              icon: Icons.gavel_outlined,
              trailing: compliance != null ? _ScoreBadge(score: compliance.complianceScore) : null,
              children: compliance != null
                  ? [
                      Row(
                        children: [
                          Expanded(
                            child: _LabelValue(
                              label: 'Bidding method',
                              value: compliance.confirmedBiddingMethod.isNotEmpty
                                  ? compliance.confirmedBiddingMethod
                                  : 'Single stage one envelope',
                            ),
                          ),
                          const SizedBox(width: 16),
                          _LabelValue(
                            label: 'Integrity pact',
                            value: compliance.integrityPactRequired ? 'Required' : 'Not required',
                            valueColor: compliance.integrityPactRequired
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('ADVERTISEMENT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: compliance.advertisementRequirements.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.value ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: e.value ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(e.value ? Icons.check_rounded : Icons.close_rounded,
                                    size: 11, color: e.value ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  e.key.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: e.value ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (compliance.mandatoryClauses.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text('MANDATORY CLAUSES',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        ...compliance.mandatoryClauses.map((c) => BulletPoint(text: c)),
                      ],
                    ]
                  : [const Text('Not executed.', style: TextStyle(color: Color(0xFF94A3B8)))],
            ),
            const SizedBox(height: 12),

            // Vendor shortlist
            DashCard(
              title: 'Vendor shortlist',
              icon: Icons.groups_outlined,
              trailing: vendorIntel != null
                  ? Text('Evaluated: ${vendorIntel.totalVendorsEvaluated}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
                  : null,
              children: vendorIntel != null && vendorIntel.shortlist.isNotEmpty
                  ? [
                      ...vendorIntel.shortlist.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        final hasFlag = v.conflictStatus.isNotEmpty &&
                            v.conflictStatus.toLowerCase() != 'none' &&
                            v.conflictStatus.toLowerCase() != 'clear';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8EDF3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(v.name,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                        const SizedBox(width: 2),
                                        Text(v.score.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text('Predicted: PKR ${_formatCurrency(v.predictedBidPkr)}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    if (hasFlag) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFD97706)),
                                            const SizedBox(width: 4),
                                            Text(v.conflictStatus.toUpperCase(),
                                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
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
                      }),
                      if (vendorIntel.predictedBidRangePkr.min > 0)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8EDF3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bid range: PKR ${_formatCurrency(vendorIntel.predictedBidRangePkr.min)} – ${_formatCurrency(vendorIntel.predictedBidRangePkr.max)} (median ${_formatCurrency(vendorIntel.predictedBidRangePkr.median)})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ]
                  : [const Text('No vendors generated.', style: TextStyle(color: Color(0xFF94A3B8)))],
            ),
            const SizedBox(height: 12),

            // Actions executed
            DashCard(
              title: 'Actions executed',
              icon: Icons.bolt_outlined,
              children: [
                _ActionRow(
                  icon: Icons.description_outlined,
                  color: const Color(0xFF1E3A8A),
                  title: 'RFP document',
                  subtitle: document != null ? document.filePath.split('/').last : 'Not generated',
                  action: document != null ? 'Download PDF' : null,
                  onAction: document != null ? _downloadPdf : null,
                ),
                _ActionRow(
                  icon: Icons.mail_outline_rounded,
                  color: const Color(0xFF3B82F6),
                  title: '${res.emails.length} invitation emails',
                  subtitle: 'Sent to selected vendors',
                  isLast: false,
                ),
                _ActionRow(
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFFD97706),
                  title: '${res.calendarEvents.length} calendar events',
                  subtitle: 'Milestones scheduled',
                  isLast: false,
                ),
                _ActionRow(
                  icon: Icons.public_outlined,
                  color: const Color(0xFF16A34A),
                  title: portalPosting != null ? 'RFP posted to portal' : 'Portal posting pending',
                  subtitle: portalPosting?.referenceId ?? 'N/A',
                  isLast: true,
                  action: portalPosting != null ? 'Open' : null,
                  onAction: portalPosting != null ? () => openInBrowser(portalPosting.postedUrl) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vendor responses card (6th card)
            DashCard(
              title: 'Vendor responses',
              icon: Icons.inbox_outlined,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${vendorResponses.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
              children: vendorResponses.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Awaiting vendor responses…',
                          style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ]
                  : _buildVendorResponseContent(vendorResponses),
            ),
            const SizedBox(height: 12),

            // Reasoning trace
            DashCard(
              title: 'Reasoning trace audit',
              icon: Icons.manage_search_outlined,
              children: [
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Classifier', 'Auditor', 'Vendor Intel', 'Drafter']
                        .map((f) => _CategoryChip(
                              label: f,
                              selected: _selectedAgentFilter == f,
                              onTap: () => setState(() => _selectedAgentFilter = f),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 360,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: _TraceList(
                    traces: tracesList,
                    filter: _selectedAgentFilter,
                    expandedIndices: _expandedTraceIndices,
                    onToggleExpand: (idx) {
                      setState(() {
                        if (_expandedTraceIndices.contains(idx)) {
                          _expandedTraceIndices.remove(idx);
                        } else {
                          _expandedTraceIndices.add(idx);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVendorResponseContent(List<dynamic> vendorResponses) {
    final count = vendorResponses.length;
    double sum = 0;
    double minBid = double.infinity;
    double maxBid = 0;
    for (final vr in vendorResponses) {
      final amount = (vr.bidAmountPkr as num).toDouble();
      sum += amount;
      if (amount < minBid) minBid = amount;
      if (amount > maxBid) maxBid = amount;
    }
    final avgBid = sum / count;

    return [
      // Stats row
      Row(
        children: [
          Expanded(
            child: _LabelValue(label: 'Responses', value: '$count'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabelValue(label: 'Avg bid', value: 'PKR ${_formatCurrency(avgBid)}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabelValue(label: 'Range', value: 'PKR ${_formatCurrency(minBid)}–${_formatCurrency(maxBid)}'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      // List of responses
      ...vendorResponses.map<Widget>((vr) {
        final summary = vr.technicalSummary as String;
        final preview = summary.length > 200 ? '${summary.substring(0, 200)}…' : summary;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EDF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vr.vendorName as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(vr.vendorEmail as String,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Text('PKR ${_formatCurrency((vr.bidAmountPkr as num).toDouble())}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              const SizedBox(height: 8),
              Text(preview, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
              const SizedBox(height: 6),
              Text('Submitted ${_formatDateTime(vr.submittedAt as String?)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        );
      }),
    ];
  }
}

class _TraceList extends StatelessWidget {
  final List<dynamic> traces;
  final String filter;
  final Set<int> expandedIndices;
  final void Function(int) onToggleExpand;
  const _TraceList({
    required this.traces,
    required this.filter,
    required this.expandedIndices,
    required this.onToggleExpand,
  });
  @override
  Widget build(BuildContext context) {
    final filtered = traces.where((t) {
      if (t is! Map<String, dynamic>) return false;
      if (filter == 'All') return true;
      final name = t['agent_name'] ?? '';
      if (filter == 'Classifier' && name == 'classifier') return true;
      if (filter == 'Auditor' && name == 'auditor') return true;
      if (filter == 'Vendor Intel' && name == 'vendor_intel') return true;
      if (filter == 'Drafter' && name == 'drafter') return true;
      return false;
    }).toList();
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No steps for this agent.', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8EDF3)),
      itemBuilder: (context, idx) {
        final trace = filtered[idx] as Map<String, dynamic>;
        final agentName = trace['agent_name'] ?? '';
        final step = trace['step_number'] ?? (idx + 1);
        final reasoning = trace['reasoning'] ?? '';
        final expanded = expandedIndices.contains(step);
        Color dot;
        String label;
        switch (agentName) {
          case 'classifier':   dot = const Color(0xFF3B82F6); label = 'Classifier'; break;
          case 'auditor':      dot = const Color(0xFF7C3AED); label = 'Auditor'; break;
          case 'vendor_intel': dot = const Color(0xFFD97706); label = 'Vendor Intel'; break;
          case 'drafter':      dot = const Color(0xFF16A34A); label = 'Drafter'; break;
          default:             dot = const Color(0xFF94A3B8); label = agentName.toString();
        }
        return InkWell(
          onTap: () => onToggleExpand(step),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: dot.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: dot)),
                          ),
                          const Spacer(),
                          Text('#$step', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        reasoning.toString(),
                        maxLines: expanded ? null : 2,
                        overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgentDot extends StatelessWidget {
  final String label;
  final bool done;
  const _AgentDot({required this.label, required this.done});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: done ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Center(
            child: Icon(
              done ? Icons.check_rounded : Icons.circle,
              size: done ? 13 : 6,
              color: done ? Colors.white : const Color(0xFFCBD5E1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: done ? const Color(0xFF1E3A8A) : const Color(0xFF94A3B8))),
      ],
    );
  }
}

class _PipelineLine extends StatelessWidget {
  final bool done;
  const _PipelineLine({required this.done});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: done ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFE2E8F0),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _LabelValue({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF0F172A))),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});
  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? const Color(0xFF16A34A) : score >= 60 ? const Color(0xFFD97706) : const Color(0xFFE53935);
    final bg = score >= 80 ? const Color(0xFFF0FDF4) : score >= 60 ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text('${score.toStringAsFixed(0)}/100',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;
  final String? action;
  final VoidCallback? onAction;
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(action!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.selected
              ? const Color(0xFF1E3A8A)
              : (_pressed ? const Color(0xFFE8EDF3) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.selected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0)),
        ),
        child: Text(widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.selected ? Colors.white : const Color(0xFF475569),
            )),
      ),
    );
  }
}
