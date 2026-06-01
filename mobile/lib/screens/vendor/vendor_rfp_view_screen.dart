import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/vendor_service.dart';
import '../../core/theme.dart';
import '../../models/public_rfp.dart';
import '../../utils/platform_utils.dart';

class VendorRfpViewScreen extends ConsumerStatefulWidget {
  final String jobId;
  const VendorRfpViewScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<VendorRfpViewScreen> createState() => _VendorRfpViewScreenState();
}

class _VendorRfpViewScreenState extends ConsumerState<VendorRfpViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PublicRfp? _rfp;

  @override
  void initState() {
    super.initState();
    _fetchRfp();
  }

  Future<void> _fetchRfp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ref.read(vendorServiceProvider).getPublicRfp(widget.jobId);
      setState(() {
        _rfp = res;
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
    final pdfPath = _rfp?.pdfDownloadUrl ?? '';
    if (pdfPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available.')),
      );
      return;
    }
    final fullUrl = '${ApiConstants.baseUrl}$pdfPath';
    if (kIsWeb) {
      openInBrowser(fullUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL: $fullUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogged = ref.watch(vendorAuthProvider) != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('RFP Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('VENDOR PORTAL', style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Ref: ${_rfp!.referenceId}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _rfp!.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildMetaRow('Issuing Organization', _rfp!.issuingOrganization),
                                  const Divider(),
                                  _buildMetaRow('Submission Deadline', _rfp!.submissionDeadlineIso.split('T').first),
                                  if (_rfp!.estimatedValuePkr != null) ...[
                                    const Divider(),
                                    _buildMetaRow('Estimated Value', 'PKR ${_rfp!.estimatedValuePkr}'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSection('Scope of Work', _rfp!.scopeOfWork),
                          _buildListSection('Eligibility Criteria', _rfp!.eligibilityCriteria),
                          _buildListSection('Evaluation Criteria', _rfp!.evaluationCriteria),
                          _buildListSection('Mandatory PPRA Clauses', _rfp!.mandatoryClauses),
                          
                          const SizedBox(height: 16),
                          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildMetaRow('Name', _rfp!.contactInfo['name'] ?? ''),
                                  const Divider(),
                                  _buildMetaRow('Email', _rfp!.contactInfo['email'] ?? ''),
                                  const Divider(),
                                  _buildMetaRow('Phone', _rfp!.contactInfo['phone'] ?? ''),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLogged)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => context.go('/vendor/respond/${widget.jobId}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Submit Bid Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => context.go('/vendor/login?return_to=/vendor/rfp/${widget.jobId}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Sign in to submit response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _downloadPdf,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                              ),
                              child: const Text('Download Full RFP PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.5, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, color: Color(0xFF374151))),
                Expanded(child: Text(e, style: const TextStyle(height: 1.5, color: Color(0xFF374151)))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
