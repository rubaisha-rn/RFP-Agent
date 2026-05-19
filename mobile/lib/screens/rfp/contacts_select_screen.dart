import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vendor.dart';
import '../../models/rfp_result.dart';
import '../../services/rfp_service.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rfpService = ref.read(rfpServiceProvider);
      // Fetch both list of contacts and full rfp result (to precheck shortlist)
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
          (s) => s.vendorId == vendor.id || s.email.trim().toLowerCase() == vendor.email.trim().toLowerCase(),
        );
        if (isShortlisted) {
          prechecked.add(vendor.id);
        }
      }

      setState(() {
        _allVendors = vendors;
        _shortlist = shortlist;
        _selectedVendorIds = prechecked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
      // Map to friendly name: e.g. IT_services -> IT Services
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
        const SnackBar(content: Text('Please select at least one vendor to proceed.')),
      );
      return;
    }

    final selectedVendors = _allVendors.where((v) => _selectedVendorIds.contains(v.id)).toList();
    
    // Navigate to confirm send screen, passing the selected vendor objects in GoRouter extra state
    context.go('/rfp/confirm/${widget.jobId}', extra: selectedVendors);
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
                'Fetching listed active vendors...',
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
        appBar: AppBar(title: const Text('Select Vendors')),
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
                  'Failed to load vendors',
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
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredVendors;
    final categories = _categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Select Vendors',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle card
              const Text(
                'Review and confirm vendors. Shortlisted vendors are pre-checked.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 16),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search vendors by name or email...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Category Chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final catName = categories[idx];
                    final isSelected = _selectedCategory == catName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = catName;
                          });
                        },
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Vendors List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No vendors match your search criteria.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final vendor = filtered[idx];
                          final isChecked = _selectedVendorIds.contains(vendor.id);
                          final isShortlisted = _shortlist.any((s) =>
                              s.vendorId == vendor.id ||
                              s.email.trim().toLowerCase() == vendor.email.trim().toLowerCase());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isChecked 
                                    ? AppTheme.primaryColor.withOpacity(0.5) 
                                    : const Color(0xFFE5E7EB),
                                width: isChecked ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isShortlisted 
                                        ? const Color(0xFFDCFCE7) 
                                        : const Color(0xFFF3F4F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.business, 
                                    color: isShortlisted 
                                        ? AppTheme.accentColor 
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            vendor.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isShortlisted)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF86EFAC)),
                                              ),
                                              child: const Text(
                                                'AI Shortlist',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vendor.email,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              vendor.category.replaceAll('_', ' ').toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star, size: 10, color: Color(0xFFD97706)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Score: ${vendor.pastPerformanceScore.toStringAsFixed(1)}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isChecked,
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    _toggleVendorSelection(vendor.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom sticky selection count bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Send to ${_selectedVendorIds.length} Vendors',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
