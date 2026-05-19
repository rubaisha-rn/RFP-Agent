class Vendor {
  final String id;
  final String name;
  final String email;
  final String category;
  final double pastPerformanceScore;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.pastPerformanceScore,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      pastPerformanceScore: (json['past_performance_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'category': category,
      'past_performance_score': pastPerformanceScore,
    };
  }
}
