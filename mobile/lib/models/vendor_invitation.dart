class VendorInvitation {
  final String jobId;
  final String referenceId;
  final String rfpTitle;
  final String receivedAt;
  final String? submissionDeadline;
  final num? estimatedValuePkr;
  final bool hasResponded;
  final num? bidAmountPkr;

  VendorInvitation({
    required this.jobId,
    required this.referenceId,
    required this.rfpTitle,
    required this.receivedAt,
    this.submissionDeadline,
    this.estimatedValuePkr,
    required this.hasResponded,
    this.bidAmountPkr,
  });

  factory VendorInvitation.fromJson(Map<String, dynamic> json) {
    return VendorInvitation(
      jobId: json['job_id'] ?? '',
      referenceId: json['reference_id'] ?? '',
      rfpTitle: json['rfp_title'] ?? '',
      receivedAt: json['received_at'] ?? '',
      submissionDeadline: json['submission_deadline'],
      estimatedValuePkr: json['estimated_value_pkr'],
      hasResponded: json['has_responded'] ?? false,
      bidAmountPkr: json['bid_amount_pkr'],
    );
  }
}
