import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vendor.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';
import '../../widgets/shared_ui.dart';

class ContactsSelectScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ContactsSelectScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  ConsumerState<ContactsSelectScreen> createState() => _ContactsSelectScreenState();
}

class _ContactsSelectScreenState extends ConsumerState<ContactsSelectScreen> {
  List<Vendor> _allVendors = [];
  List<ShortlistEntry> _shortlist = [];
  Set<String> _selectedVendorIds = {};
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final rfpService = ref.read(rfpServiceProvider);
      final results = await Future.wait([
        rfpService.listContacts(),
        rfpService.getResult(widget.jobId),
      ]);
      final vendors = results[0] as List<Vendor>;
      final result = results[1] as RfpResult;
      final shortlist = result.vendorIntel?.shortlist ?? [];
      final prechecked = <String>{};
      for (var vendor in vendors) {
        final isShortlisted = shortlist.any(
          (s) => s.vendorId == vendor.id ||
              s.email.trim().toLowerCase() == vendor.email.trim().toLowerCase(),
        );
        if (isShortlisted) prechecked.add(vendor.id);
      }
      setState(() {
        _allVendors = vendors;
        _shortlist = shortlist;
        _selectedVendorIds = prechecked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  List<Vendor> get _filteredVendors {
    return _allVendors.where((vendor) {
      final matchesSearch = vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          vendor.category.toLowerCase() == _selectedCategory.toLowerCase().replaceAll(' ', '_');
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final categories = <String>{'All'};
    for (var v in _allVendors) {
      final name = v.category.replaceAll('_', ' ');
      final capitalized = name.split(' ').map((word) {
        if (word.isEmpty) return '';
        if (word.toLowerCase() == 'it') return 'IT';
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
      categories.add(capitalized);
    }
    return categories.toList();
  }

  void _toggleVendorSelection(String vendorId) {
    setState(() {
      if (_selectedVendorIds.contains(vendorId)) {
        _selectedVendorIds.remove(vendorId);
      } else {
        _selectedVendorIds.add(vendorId);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedVendorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one vendor to proceed.')),
      );
      return;
    }
    final selectedVendors = _allVendors.where((v) => _selectedVendorIds.contains(v.id)).toList();
    context.go('/rfp/confirm/${widget.jobId}', extra: selectedVendors);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingScaffold(message: 'Loading vendors...');
    if (_errorMessage != null) {
      return ErrorScaffold(
        title: 'Select Vendors',
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final filtered = _filteredVendors;
    final categories = _categories;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: StyledAppBar(title: 'Select vendors'),
      body: Column(
        children: [

          // Search + filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Search vendors...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category chips
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, idx) {
                      final cat = categories[idx];
                      final selected = _selectedCategory == cat;
                      return _CategoryChip(
                        label: cat,
                        selected: selected,
                        onTap: () => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Selection count bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FB),
              border: Border(
                top: BorderSide(color: Color(0xFFE8EDF3)),
                bottom: BorderSide(color: Color(0xFFE8EDF3)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${filtered.length} vendors',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_selectedVendorIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedVendorIds.length} selected',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Vendor list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No vendors match your search.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final vendor = filtered[idx];
                      final isChecked = _selectedVendorIds.contains(vendor.id);
                      final isShortlisted = _shortlist.any((s) =>
                          s.vendorId == vendor.id ||
                          s.email.trim().toLowerCase() == vendor.email.trim().toLowerCase());
                      return _VendorCard(
                        vendor: vendor,
                        isChecked: isChecked,
                        isShortlisted: isShortlisted,
                        onToggle: () => _toggleVendorSelection(vendor.id),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Sticky CTA
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
        ),
        child: PrimaryActionButton(
          text: _selectedVendorIds.isEmpty
              ? 'Select vendors to continue'
              : 'Send to ${_selectedVendorIds.length} vendor${_selectedVendorIds.length == 1 ? '' : 's'}',
          isLoading: false,
          enabled: _selectedVendorIds.isNotEmpty,
          onTap: _confirmSelection,
        ),
      ),
    );
  }
}

class _VendorCard extends StatefulWidget {
  final Vendor vendor;
  final bool isChecked;
  final bool isShortlisted;
  final VoidCallback onToggle;

  const _VendorCard({
    required this.vendor,
    required this.isChecked,
    required this.isShortlisted,
    required this.onToggle,
  });

  @override
  State<_VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<_VendorCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isChecked
              ? const Color(0xFFEFF6FF)
              : (_pressed ? const Color(0xFFF8F9FB) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isChecked
                ? const Color(0xFF1E3A8A).withOpacity(0.4)
                : const Color(0xFFE8EDF3),
            width: widget.isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: widget.isShortlisted
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.business_outlined,
                size: 18,
                color: widget.isShortlisted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.vendor.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (widget.isShortlisted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Text(
                            'AI pick',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.vendor.email,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.vendor.category.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 2),
                      Text(
                        widget.vendor.pastPerformanceScore.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.isChecked
                    ? const Color(0xFF1E3A8A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isChecked
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: widget.isChecked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.selected
              ? const Color(0xFF1E3A8A)
              : (_pressed ? const Color(0xFFE8EDF3) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.selected
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}