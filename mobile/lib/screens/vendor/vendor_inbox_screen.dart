import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../core/theme.dart';
import '../../models/vendor_invitation.dart';

class VendorInboxScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorInboxScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  ConsumerState<VendorInboxScreen> createState() => _VendorInboxScreenState();
}

class _VendorInboxScreenState extends ConsumerState<VendorInboxScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _vendorData;
  List<VendorInvitation> _invitations = [];

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ref.read(vendorServiceProvider).getInbox(widget.vendorId);
      setState(() {
        _vendorData = res['vendor'];
        _invitations = (res['invitations'] as List<dynamic>? ?? [])
            .map((e) => VendorInvitation.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(vendorAuthProvider.notifier).logout();
      if (mounted) context.go('/vendor/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('VENDOR PORTAL', style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchInbox,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_vendorData?['company_name'] ?? 'Vendor'}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _vendorData?['email'] ?? '',
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Total Invitations', _invitations.length.toString())),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('Pending Response', _invitations.where((i) => !i.hasResponded).length.toString(), color: const Color(0xFFEF4444))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('Responded', _invitations.where((i) => i.hasResponded).length.toString(), color: AppTheme.accentColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Recent Invitations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_invitations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.inbox, size: 48, color: Color(0xFF9CA3AF)),
                              SizedBox(height: 16),
                              Text('No RFP invitations yet', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _invitations.length,
                          itemBuilder: (context, index) {
                            final inv = _invitations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context.go('/vendor/rfp/${inv.jobId}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              inv.rfpTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: inv.hasResponded ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              inv.hasResponded ? 'Responded' : 'Pending Response',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: inv.hasResponded ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ref: ${inv.referenceId}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                                      ),
                                      if (inv.submissionDeadline != null) ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Deadline: ${inv.submissionDeadline!.split("T")[0]}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
