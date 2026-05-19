import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/rfp_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';

class BriefInputScreen extends ConsumerStatefulWidget {
  const BriefInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BriefInputScreen> createState() => _BriefInputScreenState();
}

class _BriefInputScreenState extends ConsumerState<BriefInputScreen> {
  final TextEditingController _briefController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _examples = [
    {
      'title': 'Punjab Citizen Portal (Demo)',
      'text': 'We need a digital citizen services portal for the Punjab government, with cloud hosting, Urdu and English support, NADRA integration. Budget around 2.5 million PKR, 90 day timeline.',
    },
    {
      'title': 'Hospital Solarization',
      'text': 'Installation of solar panel systems across 10 public hospitals in Lahore. Estimated value 5 million PKR, must include 5 years warranty, delivery in 120 days.',
    },
    {
      'title': 'Fiber Connectivity',
      'text': 'Consulting services for high-speed fiber connectivity for educational institutes in Rawalpindi. Budget 1.2 million PKR, 60 day timeline, certified technicians required.',
    },
  ];

  @override
  void dispose() {
    _briefController.dispose();
    super.dispose();
  }

  void _autofill(String text) {
    setState(() {
      _briefController.text = text;
      _errorMessage = null;
    });
  }

  Future<void> _generateRfp() async {
    final brief = _briefController.text.trim();
    if (brief.length < 20) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final org = ref.read(authProvider);
      final orgId = org?.id ?? 'demo-org';
      final rfpService = ref.read(rfpServiceProvider);

      final jobId = await rfpService.generateRfp(brief: brief, organizationId: orgId);
      if (mounted) {
        context.go('/rfp/progress/$jobId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException(code: 400, message: ', '').replaceAll(')', '').replaceAll('ApiException', 'Error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefText = _briefController.text;
    final isBtnEnabled = briefText.trim().length >= 20;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'New RFP',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.accentColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'RFP Agent Pipeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Describe your procurement need',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our multi-agent system will classify requirements, verify PPRA compliance, extract target vendors, and draft emails/schedules.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // Multiline text input
                TextField(
                  controller: _briefController,
                  maxLines: 8,
                  onChanged: (text) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Describe your procurement need. Include: what you need, budget range in PKR, timeline, key requirements...',
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      briefText.trim().length < 20
                          ? 'Min 20 characters required'
                          : 'Valid procurement brief',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: briefText.trim().length < 20
                            ? const Color(0xFFEF4444)
                            : AppTheme.accentColor,
                      ),
                    ),
                    Text(
                      '${briefText.length} characters',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Examples section
                const Text(
                  'Example briefs (Tap to autofill)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _examples.map((example) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () => _autofill(example['text']!),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                example['title']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                example['text']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                PrimaryButton(
                  text: 'Generate RFP',
                  onPressed: isBtnEnabled ? _generateRfp : null,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
