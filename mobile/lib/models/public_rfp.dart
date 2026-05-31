class PublicRfp {
  final String jobId;
  final String referenceId;
  final String title;
  final String scopeOfWork;
  final List<String> eligibilityCriteria;
  final List<String> evaluationCriteria;
  final List<String> mandatoryClauses;
  final String submissionDeadlineIso;
  final String openingDateIso;
  final Map<String, dynamic> contactInfo;
  final String pdfDownloadUrl;
  final String issuingOrganization;
  final num? estimatedValuePkr;

  PublicRfp({
    required this.jobId,
    required this.referenceId,
    required this.title,
    required this.scopeOfWork,
    required this.eligibilityCriteria,
    required this.evaluationCriteria,
    required this.mandatoryClauses,
    required this.submissionDeadlineIso,
    required this.openingDateIso,
    required this.contactInfo,
    required this.pdfDownloadUrl,
    required this.issuingOrganization,
    this.estimatedValuePkr,
  });

  factory PublicRfp.fromJson(Map<String, dynamic> json) {
    return PublicRfp(
      jobId: json['job_id'] ?? '',
      referenceId: json['reference_id'] ?? '',
      title: json['title'] ?? '',
      scopeOfWork: json['scope_of_work'] ?? '',
      eligibilityCriteria: List<String>.from(json['eligibility_criteria'] ?? []),
      evaluationCriteria: List<String>.from(json['evaluation_criteria'] ?? []),
      mandatoryClauses: List<String>.from(json['mandatory_clauses'] ?? []),
      submissionDeadlineIso: json['submission_deadline_iso'] ?? '',
      openingDateIso: json['opening_date_iso'] ?? '',
      contactInfo: json['contact_info'] as Map<String, dynamic>? ?? {},
      pdfDownloadUrl: json['pdf_download_url'] ?? '',
      issuingOrganization: json['issuing_organization'] ?? '',
      estimatedValuePkr: json['estimated_value_pkr'],
    );
  }
}
