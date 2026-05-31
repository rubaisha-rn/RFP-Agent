import '../../utils/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String jobId;
  const PreviewScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  RfpResult? _result;
  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingScaffold(message: 'Fetching drafted RFP...');
    if (_errorMessage != null) {
      return ErrorScaffold(
        title: 'Preview RFP',
        message: _errorMessage!,
        onRetry: _fetchResult,
      );
    }

    final res = _result!;
    final rfpBody = res.finalRfp?.rfpBody;
    final compliance = res.compliance;
    final vendorIntel = res.vendorIntel;
    final portalPosting = res.portalPosting;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: StyledAppBar(title: 'Preview RFP'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 100),
        child: Column(
          children: [

            // Hero header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F2A4A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PPRA ALIGNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (compliance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${compliance.complianceScore.toStringAsFixed(0)}% compliant',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    rfpBody?.title ?? 'Request For Proposal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 13, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          portalPosting?.referenceId ??
                              'PPRA-${widget.jobId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sections
            ExpandableSection(
              title: 'Scope of work',
              icon: Icons.assignment_outlined,
              initiallyExpanded: true,
              child: Text(
                rfpBody?.scopeOfWork ?? 'No scope drafted.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5),
              ),
            ),

            ExpandableSection(
              title: 'Eligibility criteria',
              icon: Icons.verified_user_outlined,
              child: Column(
                children: rfpBody != null && rfpBody.eligibilityCriteria.isNotEmpty
                    ? rfpBody.eligibilityCriteria.map((e) => BulletPoint(text: e)).toList()
                    : [const Text('None specified.', style: TextStyle(color: Color(0xFF94A3B8)))],
              ),
            ),

            ExpandableSection(
              title: 'Evaluation criteria',
              icon: Icons.assessment_outlined,
              child: Column(
                children: rfpBody != null && rfpBody.evaluationCriteria.isNotEmpty
                    ? rfpBody.evaluationCriteria.map((e) => BulletPoint(text: e)).toList()
                    : [const Text('None specified.', style: TextStyle(color: Color(0xFF94A3B8)))],
              ),
            ),

            ExpandableSection(
              title: 'Mandatory PPRA clauses',
              icon: Icons.gavel_outlined,
              child: Column(
                children: compliance != null && compliance.mandatoryClauses.isNotEmpty
                    ? compliance.mandatoryClauses.map((e) => BulletPoint(text: e)).toList()
                    : [const Text('None applied.', style: TextStyle(color: Color(0xFF94A3B8)))],
              ),
            ),

            ExpandableSection(
              title: 'Key dates',
              icon: Icons.event_outlined,
              child: Column(
                children: [
                  DateRow('Pre-bid meeting', 'TBD'),
                  DateRow('Submission deadline',
                      rfpBody?.submissionDeadlineIso.split('T')[0] ?? 'TBD'),
                  DateRow('Bid opening',
                      rfpBody?.openingDateIso.split('T')[0] ?? 'TBD'),
                ],
              ),
            ),

            ExpandableSection(
              title: 'Contact information',
              icon: Icons.contact_mail_outlined,
              child: Column(
                children: [
                  InfoRow('Name', rfpBody?.contactInfo.name ?? 'N/A'),
                  InfoRow('Email', rfpBody?.contactInfo.email ?? 'N/A'),
                  InfoRow('Phone', rfpBody?.contactInfo.phone ?? 'N/A'),
                  InfoRow('Organisation', rfpBody?.contactInfo.organization ?? 'N/A'),
                ],
              ),
            ),

            ExpandableSection(
              title: 'Recommended shortlist',
              icon: Icons.people_outline,
              child: vendorIntel != null && vendorIntel.shortlist.isNotEmpty
                  ? Column(
                      children: vendorIntel.shortlist.map((v) => _VendorRow(
                        name: v.name,
                        bid: v.predictedBidPkr,
                        score: v.score,
                      )).toList(),
                    )
                  : const Text('No shortlist generated.', style: TextStyle(color: Color(0xFF94A3B8))),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),

      // Sticky bottom action bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
        ),
        child: Row(
          children: [
            Expanded(
              child: SecondaryActionButton(
                text: 'Download PDF',
                onTap: _downloadPdf,
                icon: Icons.download_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryActionButton(
                text: 'Select vendors',
                isLoading: false,
                enabled: true,
                onTap: () => context.go('/rfp/contacts/${widget.jobId}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorRow extends StatelessWidget {
  final String name;
  final double bid;
  final double score;

  const _VendorRow({required this.name, required this.bid, required this.score});

  String _formatBid(double v) {
    if (v >= 1000000) return 'PKR ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'PKR ${(v / 1000).toStringAsFixed(0)}k';
    return 'PKR ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business_outlined, size: 15, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(_formatBid(bid), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}