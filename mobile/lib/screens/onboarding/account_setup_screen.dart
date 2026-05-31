import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountSetupScreen> createState() =>
      _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  String? _selectedIndustry;
  String? _selectedBudget;
  String? _uploadedFileName;
  bool _isUploading = false;

  final List<String> _industries = [
    'Government',
    'IT',
    'Healthcare',
    'Construction',
    'Other',
  ];

  final List<String> _budgets = [
    'Under PKR 100k',
    'PKR 100k – 500k',
    'PKR 500k – 2M',
    'PKR 2M – 10M',
    'PKR 10M+',
  ];

  void _simulateUpload() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _uploadedFileName = 'procurement_policy_v2.pdf  •  1.8 MB';
      _isUploading = false;
    });
  }

  Future<void> _complete() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (mounted) context.go('/rfp/new');
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2A4A),
      body: Column(
        children: [

          // ── Dark branded header ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF0F2A4A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + step badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'RFP Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Set up your organisation',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Helps our agents tailor compliance and vendor selection to your context.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Step progress — step 2 filled
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Form panel ───────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FB),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24, 24, 24, bottomPadding + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Industry
                    _SectionLabel(
                      icon: Icons.domain_outlined,
                      text: 'Primary industry',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _industries.map((ind) {
                        final selected = _selectedIndustry == ind;
                        return _IndustryChip(
                          label: ind,
                          selected: selected,
                          onTap: () =>
                              setState(() => _selectedIndustry = ind),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 24),

                    // Budget
                    _SectionLabel(
                      icon: Icons.account_balance_wallet_outlined,
                      text: 'Annual procurement budget',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedBudget,
                      hint: const Text(
                        'Select a range',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.unfold_more_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      items: _budgets.map((b) {
                        return DropdownMenuItem<String>(
                          value: b,
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBudget = val),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E3A8A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 24),

                    // Upload
                    _SectionLabel(
                      icon: Icons.shield_outlined,
                      text: 'Compliance policy',
                      badge: 'Optional',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your procurement policy PDF to enforce custom rules in the Auditor Agent.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _UploadBox(
                      uploadedFileName: _uploadedFileName,
                      isUploading: _isUploading,
                      onTap: _isUploading ? null : _simulateUpload,
                    ),

                    const SizedBox(height: 32),

                    // CTA
                    _PrimaryActionButton(
                      text: 'Complete setup',
                      isLoading: false,
                      onTap: _complete,
                    ),
                    const SizedBox(height: 12),

                    // Skip
                    _SkipButton(onTap: _complete),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared component widgets ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? badge;

  const _SectionLabel({
    required this.icon,
    required this.text,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
            letterSpacing: 0.1,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IndustryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndustryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_IndustryChip> createState() => _IndustryChipState();
}

class _IndustryChipState extends State<_IndustryChip> {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.selected
              ? (_pressed
                  ? const Color(0xFF0F2A4A)
                  : const Color(0xFF1E3A8A))
              : (_pressed
                  ? const Color(0xFFE8EDF3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.selected
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFE2E8F0),
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: widget.selected
                ? Colors.white
                : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _UploadBox extends StatefulWidget {
  final String? uploadedFileName;
  final bool isUploading;
  final VoidCallback? onTap;

  const _UploadBox({
    required this.uploadedFileName,
    required this.isUploading,
    required this.onTap,
  });

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final uploaded = widget.uploadedFileName != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFFEFF6FF)
              : (uploaded ? const Color(0xFFF0FDF4) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF86EFAC)
                : (_pressed
                    ? const Color(0xFF1E3A8A).withOpacity(0.4)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : const Color(0xFF1E3A8A).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1E3A8A),
                      ),
                    )
                  : Icon(
                      uploaded
                          ? Icons.check_rounded
                          : Icons.upload_file_outlined,
                      size: 18,
                      color: uploaded
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF1E3A8A),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.uploadedFileName ??
                        'Upload procurement policy (.pdf)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: uploaded
                          ? const Color(0xFF15803D)
                          : const Color(0xFF334155),
                    ),
                  ),
                  if (!uploaded && !widget.isUploading) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to browse files',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.text,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [const Color(0xFF0F2A4A), const Color(0xFF0A1E35)]
                : [const Color(0xFF1E3A8A), const Color(0xFF0F2A4A)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          child: const Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFFE8EDF3),
    );
  }
}