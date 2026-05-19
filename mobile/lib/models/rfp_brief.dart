class RfpBrief {
  final String brief;
  final String organizationId;

  RfpBrief({
    required this.brief,
    required this.organizationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'brief': brief,
      'organization_id': organizationId,
    };
  }
}
