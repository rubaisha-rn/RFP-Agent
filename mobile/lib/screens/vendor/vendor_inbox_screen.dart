import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/vendor_service.dart';
import '../../models/vendor_invitation.dart';
import '../../widgets/shared_ui.dart';

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
    setState(() { _isLoading = true; _errorMessage = null; });
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
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Log out?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text(
                'You will need to sign in again to access your inbox.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: VSecondaryButton(
                      text: 'Cancel',
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VDangerButton(
                      text: 'Log out',
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(vendorAuthProvider.notifier).logout();
      if (mounted) context.go('/vendor/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingScaffold(message: 'Loading your inbox...');
    if (_errorMessage != null) {
      return ErrorScaffold(title: 'Inbox', message: _errorMessage!, onRetry: _fetchInbox);
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final pending = _invitations.where((i) => !i.hasResponded).length;
    final responded = _invitations.where((i) => i.hasResponded).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [

          // ── Vendor header ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 20,
              left: 20, right: 20, bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16A34A), Color(0xFF0A2918)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Vendor Portal',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    LogoutButton(onTap: _logout),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _vendorData?['company_name'] ?? 'Vendor',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  _vendorData?['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                ),
                const SizedBox(height: 18),

                // Stats row
                Row(
                  children: [
                    _StatPill(label: 'Total', value: _invitations.length.toString(), color: Colors.white),
                    const SizedBox(width: 8),
                    _StatPill(label: 'Pending', value: pending.toString(), color: const Color(0xFFFBBF24)),
                    const SizedBox(width: 8),
                    _StatPill(label: 'Responded', value: responded.toString(), color: const Color(0xFF86EFAC)),
                  ],
                ),
              ],
            ),
          ),

          // ── Invitation list ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchInbox,
              color: const Color(0xFF16A34A),
              child: _invitations.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No invitations yet',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'RFP invitations from procurement\nofficers will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invitations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = _invitations[index];
                        return _InvitationCard(
                          invitation: inv,
                          onTap: () => context.go('/vendor/rfp/${inv.jobId}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatefulWidget {
  final VendorInvitation invitation;
  final VoidCallback onTap;

  const _InvitationCard({required this.invitation, required this.onTap});

  @override
  State<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<_InvitationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    final responded = inv.hasResponded;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? const Color(0xFF16A34A).withOpacity(0.3) : const Color(0xFFE8EDF3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: responded
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    responded ? Icons.check_circle_outline_rounded : Icons.description_outlined,
                    size: 18,
                    color: responded ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.rfpTitle,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${inv.referenceId}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: responded ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: responded ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    responded ? 'Responded' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: responded ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            if (inv.submissionDeadline != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: const Color(0xFFE8EDF3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Text(
                    'Deadline: ${inv.submissionDeadline!.split("T")[0]}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFCBD5E1)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}