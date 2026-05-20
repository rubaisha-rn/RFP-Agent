import '../../utils/platform_utils.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';

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
    print('[PreviewScreen] Opening download URL: $downloadUrl');

    if (kIsWeb) {
      // Since this hackathon is compiled and tested on Google Chrome Web, 
      // we utilize dart:html's window.open to guarantee opening the PDF 
      // in a clean, new browser tab without external package dependency issues.
      openInBrowser(downloadUrl);
    } else {
      // In a multi-platform environment, we would use url_launcher:
      // launchUrl(Uri.parse(downloadUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download URL: $downloadUrl (only open tab on web)')),
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 4),
          children: children,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4),
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
                'Fetching drafted RFP details...',
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
        appBar: AppBar(title: const Text('RFP Preview')),
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
                  'Failed to load results',
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
                  onPressed: _fetchResult,
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
    final rfpBody = res.finalRfp?.rfpBody;
    final compliance = res.compliance;
    final vendorIntel = res.vendorIntel;
    final portalPosting = res.portalPosting;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Preview RFP',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Always visible Header: Reference ID & Issued Date
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PPRA ALIGNED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (compliance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                '${compliance.complianceScore.toStringAsFixed(0)}% Compliant',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rfpBody?.title ?? 'Drafted Request For Proposal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.pin, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Ref ID: ${portalPosting?.referenceId ?? "PPRA-GENERATED-JOB-${widget.jobId.substring(0, 8).toUpperCase()}"}',
                            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          const Text(
                            'Issued: Today',
                            style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 1. Scope of work
                _buildSectionCard(
                  title: 'Scope of Work',
                  icon: Icons.assignment,
                  initiallyExpanded: true,
                  children: [
                    Text(
                      rfpBody?.scopeOfWork ?? 'No scope of work drafted by the agent.',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
                    ),
                  ],
                ),

                // 2. Eligibility criteria
                _buildSectionCard(
                  title: 'Eligibility Criteria',
                  icon: Icons.verified_user,
                  children: rfpBody != null && rfpBody.eligibilityCriteria.isNotEmpty
                      ? rfpBody.eligibilityCriteria.map((e) => _buildBulletPoint(e)).toList()
                      : [const Text('No custom eligibility criteria specified.', style: TextStyle(color: Colors.grey))],
                ),

                // 3. Evaluation criteria
                _buildSectionCard(
                  title: 'Evaluation Criteria',
                  icon: Icons.assessment,
                  children: rfpBody != null && rfpBody.evaluationCriteria.isNotEmpty
                      ? rfpBody.evaluationCriteria.map((e) => _buildBulletPoint(e)).toList()
                      : [const Text('No custom evaluation weights specified.', style: TextStyle(color: Colors.grey))],
                ),

                // 4. Mandatory PPRA clauses
                _buildSectionCard(
                  title: 'Mandatory PPRA Clauses',
                  icon: Icons.gavel,
                  children: compliance != null && compliance.mandatoryClauses.isNotEmpty
                      ? compliance.mandatoryClauses.map((e) => _buildBulletPoint(e)).toList()
                      : [const Text('No mandatory PPRA audit clauses applied.', style: TextStyle(color: Colors.grey))],
                ),

                // 5. Key Dates
                _buildSectionCard(
                  title: 'Key Dates & Deadlines',
                  icon: Icons.event,
                  children: [
                    _buildDateRow('Pre-Bid Meeting', 'TBD (Confirm on send)'),
                    _buildDateRow('Submission Deadline', rfpBody?.submissionDeadlineIso.split('T')[0] ?? 'Within 15 days'),
                    _buildDateRow('Technical Bid Opening', rfpBody?.openingDateIso.split('T')[0] ?? 'Same day as closing'),
                  ],
                ),

                // 6. Contact Info
                _buildSectionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_mail,
                  children: [
                    _buildInfoRow('Name', rfpBody?.contactInfo.name ?? 'Officer-in-charge'),
                    _buildInfoRow('Email', rfpBody?.contactInfo.email ?? 'procurement@govt.pk'),
                    _buildInfoRow('Phone', rfpBody?.contactInfo.phone ?? 'N/A'),
                    _buildInfoRow('Organization', rfpBody?.contactInfo.organization ?? 'Public Division'),
                  ],
                ),

                // 7. Shortlisted vendors preview
                _buildSectionCard(
                  title: 'Recommended Shortlist',
                  icon: Icons.people_outline,
                  children: [
                    if (vendorIntel != null && vendorIntel.shortlist.isNotEmpty) ...[
                      Column(
                        children: vendorIntel.shortlist.map((vendor) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.business, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Estimated Bid: PKR ${vendor.predictedBidPkr.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Score: ${vendor.score.toStringAsFixed(1)}/5.0',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const Text('No shortlist vendors generated.', style: TextStyle(color: Colors.grey))
                    ]
                  ],
                ),

                const SizedBox(height: 24),

                // Action Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_for_offline, color: AppTheme.primaryColor),
                        label: const Text('Download PDF', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        onPressed: _downloadPdf,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/rfp/contacts/${widget.jobId}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Select Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
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

  Widget _buildDateRow(String label, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF4B5563))),
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF4B5563))),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
          ),
        ],
      ),
    );
  }
}
