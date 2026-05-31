import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
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
    'Other'
  ];

  final List<String> _budgets = [
    'Under \$100k',
    '\$100k - \$500k',
    '\$500k - \$2M',
    '\$2M+'
  ];

  void _simulateUpload() async {
    setState(() {
      _isUploading = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _uploadedFileName = 'procurement_policy_v2.pdf (1.8 MB)';
      _isUploading = false;
    });
  }

  Future<void> _complete() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (mounted) context.go('/rfp/new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Steps indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Tell us about your organization',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps our agents tailor the RFP generation & compliance auditing to your exact rules.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 32),

                // Industry dropdown
                const Text(
                  'Primary Industry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedIndustry,
                  hint: const Text('Select your industry', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                  items: _industries.map((String industry) {
                    return DropdownMenuItem<String>(
                      value: industry,
                      child: Text(industry),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedIndustry = val;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0F2A4A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Budget dropdown
                const Text(
                  'Annual Procurement Budget',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBudget,
                  hint: const Text('Select procurement budget range', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                  items: _budgets.map((String budget) {
                    return DropdownMenuItem<String>(
                      value: budget,
                      child: Text(budget),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBudget = val;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0F2A4A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Policy Box (Visual only)
                const Text(
                  'Compliance Policy (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading ? null : _simulateUpload,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(
                        color: _uploadedFileName != null ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _uploadedFileName != null 
                              ? Icons.check_circle_outline 
                              : Icons.cloud_upload_outlined,
                          size: 32,
                          color: _uploadedFileName != null 
                              ? const Color(0xFF16A34A) 
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _uploadedFileName ?? 'Upload procurement policy (.pdf)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _uploadedFileName != null 
                                ? const Color(0xFF16A34A) 
                                : const Color(0xFF374151),
                          ),
                        ),
                        if (_uploadedFileName == null) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Used by the Auditor Agent to enforce custom rules.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                        if (_isUploading) ...[
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                PrimaryButton(
                  text: 'Continue',
                  onPressed: _complete,
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _complete,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
