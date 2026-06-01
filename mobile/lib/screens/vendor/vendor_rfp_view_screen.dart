import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/vendor_service.dart';
import '../../models/public_rfp.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/shared_ui.dart';

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
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ref.read(vendorServiceProvider).getPublicRfp(widget.jobId);
      setState(() { _rfp = res; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL: $fullUrl')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingScaffold(message: 'Loading RFP details...');
    if (_errorMessage != null) {
      return ErrorScaffold(title: 'RFP Details', message: _errorMessage!, onRetry: _fetchRfp);
    }

    final rfp = _rfp!;
    final isLogged = ref.watch(vendorAuthProvider) != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _VendorBackAppBar(
        title: 'RFP Details',
        onBack: () {
            final vendorId = ref.read(vendorAuthProvider)?.id;
            if (vendorId != null) {
            context.go('/vendor/inbox/$vendorId');
            } else {
            context.go('/vendor/login');
            }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 120),
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
                        colors: [Color(0xFF16A34A), Color(0xFF0A2918)],
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
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'VENDOR PORTAL',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PPRA ALIGNED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          rfp.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.tag_rounded, size: 13, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rfp.referenceId,
                                style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Meta info card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8EDF3)),
                    ),
                    child: Column(
                      children: [
                        _MetaRow(
                          icon: Icons.domain_outlined,
                          label: 'Issuing organisation',
                          value: rfp.issuingOrganization,
                          isLast: false,
                        ),
                        _MetaRow(
                          icon: Icons.event_outlined,
                          label: 'Submission deadline',
                          value: rfp.submissionDeadlineIso.split('T').first,
                          isLast: rfp.estimatedValuePkr == null,
                        ),
                        if (rfp.estimatedValuePkr != null)
                          _MetaRow(
                            icon: Icons.payments_outlined,
                            label: 'Estimated value',
                            value: 'PKR ${rfp.estimatedValuePkr}',
                            isLast: true,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Scope
                  ExpandableSection(
                    title: 'Scope of work',
                    icon: Icons.assignment_outlined,
                    initiallyExpanded: true,
                    child: Text(
                      rfp.scopeOfWork,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5),
                    ),
                  ),

                  if (rfp.eligibilityCriteria.isNotEmpty)
                    ExpandableSection(
                      title: 'Eligibility criteria',
                      icon: Icons.verified_user_outlined,
                      child: Column(
                        children: rfp.eligibilityCriteria.map((e) => BulletPoint(text: e)).toList(),
                      ),
                    ),

                  if (rfp.evaluationCriteria.isNotEmpty)
                    ExpandableSection(
                      title: 'Evaluation criteria',
                      icon: Icons.assessment_outlined,
                      child: Column(
                        children: rfp.evaluationCriteria.map((e) => BulletPoint(text: e)).toList(),
                      ),
                    ),

                  if (rfp.mandatoryClauses.isNotEmpty)
                    ExpandableSection(
                      title: 'Mandatory PPRA clauses',
                      icon: Icons.gavel_outlined,
                      child: Column(
                        children: rfp.mandatoryClauses.map((e) => BulletPoint(text: e)).toList(),
                      ),
                    ),

                  ExpandableSection(
                    title: 'Contact information',
                    icon: Icons.contact_mail_outlined,
                    child: Column(
                      children: [
                        InfoRow('Name', rfp.contactInfo['name'] ?? 'N/A'),
                        InfoRow('Email', rfp.contactInfo['email'] ?? 'N/A'),
                        InfoRow('Phone', rfp.contactInfo['phone'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky bottom actions
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLogged)
              VendorPrimaryButton(
                text: 'Submit bid response',
                isLoading: false,
                onTap: () => context.go('/vendor/respond/${widget.jobId}'),
              )
            else
              VendorPrimaryButton(
                text: 'Sign in to submit response',
                isLoading: false,
                onTap: () => context.go('/vendor/login?return_to=/vendor/rfp/${widget.jobId}'),
              ),
            const SizedBox(height: 10),
            SecondaryActionButton(
              text: 'Download full RFP PDF',
              onTap: _downloadPdf,
              icon: Icons.download_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3)))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _VendorBackAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              AppIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}