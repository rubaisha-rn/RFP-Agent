class VendorOrganization {
  final String id;
  final String companyName;
  final String email;
  final String? category;
  
  VendorOrganization({
    required this.id,
    required this.companyName,
    required this.email,
    this.category,
  });

  factory VendorOrganization.fromJson(Map<String, dynamic> json) {
    return VendorOrganization(
      id: json['vendor_id'] ?? json['id'] ?? '',
      companyName: json['company_name'] ?? '',
      email: json['email'] ?? '',
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': id,
      'company_name': companyName,
      'email': email,
      'category': category,
    };
  }
}
