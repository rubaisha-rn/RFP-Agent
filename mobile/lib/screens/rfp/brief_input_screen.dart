import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/rfp_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/shared_ui.dart';

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
      'title': 'Punjab Citizen Portal',
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
      if (mounted) context.go('/rfp/progress/$jobId');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString()
            .replaceAll('ApiException(code: 400, message: ', '')
            .replaceAll(')', '')
            .replaceAll('ApiException', 'Error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefText = _briefController.text;
    final isBtnEnabled = briefText.trim().length >= 20;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final org = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(context, org?.companyName ?? 'RFP Agent'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Hero card
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Pipeline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Describe your procurement need',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our 4-agent system classifies requirements, verifies PPRA compliance, ranks vendors, and drafts your RFP.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Text input card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EDF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Procurement brief',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _briefController,
                    maxLines: 7,
                    onChanged: (text) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you need? Include budget in PKR, timeline, and key requirements...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE8EDF3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBtnEnabled
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: isBtnEnabled
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBtnEnabled
                              ? 'Valid procurement brief'
                              : 'Minimum 20 characters required',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isBtnEnabled
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${briefText.length} chars',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFE53935),
                      size: 17,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Generate button
            PrimaryActionButton(
              text: 'Generate RFP',
              isLoading: _isLoading,
              enabled: isBtnEnabled,
              onTap: _generateRfp,
            ),

            const SizedBox(height: 28),

            // Examples section
            const SectionHeader(
              icon: Icons.tips_and_updates_outlined,
              text: 'Example briefs — tap to autofill',
            ),
            const SizedBox(height: 12),

            ..._examples.map((example) => _ExampleCard(
              title: example['title']!,
              text: example['text']!,
              onTap: () => _autofill(example['text']!),
            )),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String orgName) {
    return PreferredSize(
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
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A4A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF0F2A4A),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'New RFP',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                LogoutButton(onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Local widgets ───────────────────────────────────────────────────────────

class _ExampleCard extends StatefulWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFFEFF6FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF1E3A8A).withOpacity(0.3)
                : const Color(0xFFE8EDF3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 14,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}