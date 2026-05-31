class Organization {
  final String id;
  final String companyName;
  final String companyEmail;
  final bool isOnboarded;

  Organization({
    required this.id,
    required this.companyName,
    required this.companyEmail,
    this.isOnboarded = true,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['organization_id'] ?? json['id'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      companyEmail: json['company_email'] ?? json['companyEmail'] ?? '',
      isOnboarded: json['is_onboarded'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': id,
      'company_name': companyName,
      'company_email': companyEmail,
      'is_onboarded': isOnboarded,
    };
  }
}
