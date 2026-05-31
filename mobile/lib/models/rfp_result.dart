import 'job_status.dart';

class RfpResult {
  final JobStatus job;
  final List<dynamic> traces;
  final GeneratedDocument? document;
  final List<SentEmail> emails;
  final List<CalendarEvent> calendarEvents;
  final PortalPosting? portalPosting;

  // Extracted dynamically from completed trace output_data or directly
  final Classification? classification;
  final ComplianceScorecard? compliance;
  final VendorIntel? vendorIntel;
  final FinalRfp? finalRfp;
  final List<VendorResponse> vendorResponses;

  RfpResult({
    required this.job,
    required this.traces,
    this.document,
    required this.emails,
    required this.calendarEvents,
    this.portalPosting,
    this.classification,
    this.compliance,
    this.vendorIntel,
    this.finalRfp,
    this.vendorResponses = const [],
  });

  factory RfpResult.fromJson(Map<String, dynamic> json) {
    final jobMap = json['job'] as Map<String, dynamic>? ?? {};
    final job = JobStatus.fromJson(jobMap);
    final tracesList = json['traces'] as List<dynamic>? ?? [];

    final documentJson = json['document'] as Map<String, dynamic>?;
    final document = documentJson != null ? GeneratedDocument.fromJson(documentJson) : null;

    final emailsList = json['emails'] as List<dynamic>? ?? [];
    final emails = emailsList.map((e) => SentEmail.fromJson(e as Map<String, dynamic>)).toList();

    final eventsList = json['calendar_events'] as List<dynamic>? ?? [];
    final calendarEvents = eventsList.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();

    final portalPostingJson = json['portal_posting'] as Map<String, dynamic>?;
    final portalPosting = portalPostingJson != null ? PortalPosting.fromJson(portalPostingJson) : null;

    // Robust extraction function for agent trace output
    Map<String, dynamic>? findAgentOutput(String agentName, String jobKey) {
      if (jobMap.containsKey(jobKey) && jobMap[jobKey] != null) {
        return jobMap[jobKey] as Map<String, dynamic>;
      }
      for (var trace in tracesList) {
        if (trace is Map<String, dynamic> &&
            trace['agent_name'] == agentName &&
            trace['output_data'] != null) {
          return trace['output_data'] as Map<String, dynamic>;
        }
      }
      return null;
    }

    final classificationJson = findAgentOutput('classifier', 'classification');
    final classification = classificationJson != null ? Classification.fromJson(classificationJson) : null;

    final complianceJson = findAgentOutput('auditor', 'compliance');
    final compliance = complianceJson != null ? ComplianceScorecard.fromJson(complianceJson) : null;

    final vendorIntelJson = findAgentOutput('vendor_intel', 'vendor_intel');
    final vendorIntel = vendorIntelJson != null ? VendorIntel.fromJson(vendorIntelJson) : null;

    final finalRfpJson = findAgentOutput('drafter', 'final_rfp');
    final finalRfp = finalRfpJson != null ? FinalRfp.fromJson(finalRfpJson) : null;

    final vendorResponsesList = json['vendor_responses'] as List<dynamic>? ?? [];
    final vendorResponses = vendorResponsesList.map((e) => VendorResponse.fromJson(e as Map<String, dynamic>)).toList();

    return RfpResult(
      job: job,
      traces: tracesList,
      document: document,
      emails: emails,
      calendarEvents: calendarEvents,
      portalPosting: portalPosting,
      classification: classification,
      compliance: compliance,
      vendorIntel: vendorIntel,
      finalRfp: finalRfp,
      vendorResponses: vendorResponses,
    );
  }
}

class VendorResponse {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorEmail;
  final double bidAmountPkr;
  final String technicalSummary;
  final String submittedAt;

  VendorResponse({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorEmail,
    required this.bidAmountPkr,
    required this.technicalSummary,
    required this.submittedAt,
  });

  factory VendorResponse.fromJson(Map<String, dynamic> json) {
    return VendorResponse(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      vendorEmail: json['vendor_email'] ?? '',
      bidAmountPkr: (json['bid_amount_pkr'] ?? 0.0).toDouble(),
      technicalSummary: json['technical_summary'] ?? '',
      submittedAt: json['submitted_at'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Classification Model
// ---------------------------------------------------------------------------
class Classification {
  final String category;
  final double estimatedValuePkr;
  final String urgency;
  final String biddingMethod;
  final List<String> requiredCertifications;
  final int deliveryTimelineDays;
  final List<String> keyRequirements;
  final String reasoningNotes;

  Classification({
    required this.category,
    required this.estimatedValuePkr,
    required this.urgency,
    required this.biddingMethod,
    required this.requiredCertifications,
    required this.deliveryTimelineDays,
    required this.keyRequirements,
    required this.reasoningNotes,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      category: json['category'] ?? '',
      estimatedValuePkr: (json['estimated_value_pkr'] ?? 0.0).toDouble(),
      urgency: json['urgency'] ?? '',
      biddingMethod: json['bidding_method'] ?? '',
      requiredCertifications: List<String>.from(json['required_certifications'] ?? []),
      deliveryTimelineDays: json['delivery_timeline_days'] ?? 0,
      keyRequirements: List<String>.from(json['key_requirements'] ?? []),
      reasoningNotes: json['reasoning_notes'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Compliance scorecard
// ---------------------------------------------------------------------------
class ComplianceScorecard {
  final List<String> applicableRuleCodes;
  final String confirmedBiddingMethod;
  final List<String> mandatoryClauses;
  final double complianceScore;
  final Map<String, bool> advertisementRequirements;
  final int bidValidityDays;
  final bool integrityPactRequired;
  final List<String> issuesFlagged;
  final String reasoningNotes;

  ComplianceScorecard({
    required this.applicableRuleCodes,
    required this.confirmedBiddingMethod,
    required this.mandatoryClauses,
    required this.complianceScore,
    required this.advertisementRequirements,
    required this.bidValidityDays,
    required this.integrityPactRequired,
    required this.issuesFlagged,
    required this.reasoningNotes,
  });

  factory ComplianceScorecard.fromJson(Map<String, dynamic> json) {
    final adReqs = json['advertisement_requirements'] as Map<String, dynamic>? ?? {};
    final parsedAdReqs = adReqs.map((k, v) => MapEntry(k, v == true));

    return ComplianceScorecard(
      applicableRuleCodes: List<String>.from(json['applicable_rule_codes'] ?? []),
      confirmedBiddingMethod: json['confirmed_bidding_method'] ?? '',
      mandatoryClauses: List<String>.from(json['mandatory_clauses'] ?? []),
      complianceScore: (json['compliance_score'] ?? 0.0).toDouble(),
      advertisementRequirements: parsedAdReqs,
      bidValidityDays: json['bid_validity_days'] ?? 0,
      integrityPactRequired: json['integrity_pact_required'] == true,
      issuesFlagged: List<String>.from(json['issues_flagged'] ?? []),
      reasoningNotes: json['reasoning_notes'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Vendor Intelligence & Shortlist
// ---------------------------------------------------------------------------
class VendorIntel {
  final List<ShortlistEntry> shortlist;
  final BidRange predictedBidRangePkr;
  final List<dynamic> conflictsFlagged;
  final int totalVendorsEvaluated;
  final String reasoningNotes;

  VendorIntel({
    required this.shortlist,
    required this.predictedBidRangePkr,
    required this.conflictsFlagged,
    required this.totalVendorsEvaluated,
    required this.reasoningNotes,
  });

  factory VendorIntel.fromJson(Map<String, dynamic> json) {
    final shortlistJson = json['shortlist'] as List<dynamic>? ?? [];
    final shortlist = shortlistJson.map((e) => ShortlistEntry.fromJson(e as Map<String, dynamic>)).toList();

    final bidRangeJson = json['predicted_bid_range_pkr'] as Map<String, dynamic>? ?? {};
    final bidRange = BidRange.fromJson(bidRangeJson);

    return VendorIntel(
      shortlist: shortlist,
      predictedBidRangePkr: bidRange,
      conflictsFlagged: json['conflicts_flagged'] as List<dynamic>? ?? [],
      totalVendorsEvaluated: json['total_vendors_evaluated'] ?? 0,
      reasoningNotes: json['reasoning_notes'] ?? '',
    );
  }
}

class ShortlistEntry {
  final String vendorId;
  final String name;
  final String email;
  final double score;
  final double predictedBidPkr;
  final String conflictStatus;

  ShortlistEntry({
    required this.vendorId,
    required this.name,
    required this.email,
    required this.score,
    required this.predictedBidPkr,
    required this.conflictStatus,
  });

  factory ShortlistEntry.fromJson(Map<String, dynamic> json) {
    return ShortlistEntry(
      vendorId: json['vendor_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      predictedBidPkr: (json['predicted_bid_pkr'] ?? 0.0).toDouble(),
      conflictStatus: json['conflict_status'] ?? '',
    );
  }
}

class BidRange {
  final double min;
  final double max;
  final double median;

  BidRange({
    required this.min,
    required this.max,
    required this.median,
  });

  factory BidRange.fromJson(Map<String, dynamic> json) {
    return BidRange(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      median: (json['median'] ?? 0.0).toDouble(),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Final RFP & Executive Action Records
// ---------------------------------------------------------------------------
class FinalRfp {
  final RfpBody rfpBody;
  final ExecutedActions executedActions;
  final String reasoningNotes;

  FinalRfp({
    required this.rfpBody,
    required this.executedActions,
    required this.reasoningNotes,
  });

  factory FinalRfp.fromJson(Map<String, dynamic> json) {
    final bodyJson = json['final_rfp'] as Map<String, dynamic>? ?? {};
    final body = RfpBody.fromJson(bodyJson);

    final actionsJson = json['executed_actions'] as Map<String, dynamic>? ?? {};
    final actions = ExecutedActions.fromJson(actionsJson);

    return FinalRfp(
      rfpBody: body,
      executedActions: actions,
      reasoningNotes: json['reasoning_notes'] ?? '',
    );
  }
}

class RfpBody {
  final String title;
  final String scopeOfWork;
  final List<String> eligibilityCriteria;
  final List<String> evaluationCriteria;
  final List<String> mandatoryClauses;
  final String submissionDeadlineIso;
  final String openingDateIso;
  final ContactInfo contactInfo;

  RfpBody({
    required this.title,
    required this.scopeOfWork,
    required this.eligibilityCriteria,
    required this.evaluationCriteria,
    required this.mandatoryClauses,
    required this.submissionDeadlineIso,
    required this.openingDateIso,
    required this.contactInfo,
  });

  factory RfpBody.fromJson(Map<String, dynamic> json) {
    final contactJson = json['contact_info'] as Map<String, dynamic>? ?? {};
    final contact = ContactInfo.fromJson(contactJson);

    return RfpBody(
      title: json['title'] ?? '',
      scopeOfWork: json['scope_of_work'] ?? '',
      eligibilityCriteria: List<String>.from(json['eligibility_criteria'] ?? []),
      evaluationCriteria: List<String>.from(json['evaluation_criteria'] ?? []),
      mandatoryClauses: List<String>.from(json['mandatory_clauses'] ?? []),
      submissionDeadlineIso: json['submission_deadline_iso'] ?? '',
      openingDateIso: json['opening_date_iso'] ?? '',
      contactInfo: contact,
    );
  }
}

class ContactInfo {
  final String name;
  final String email;
  final String phone;
  final String organization;

  ContactInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.organization,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      organization: json['organization'] ?? '',
    );
  }
}

class ExecutedActions {
  final String documentId;
  final String pdfPath;
  final List<EmailDispatchRecord> emailsSent;
  final List<CalendarEventRecord> calendarEventsCreated;
  final PortalPostingRecord? portalPosting;

  ExecutedActions({
    required this.documentId,
    required this.pdfPath,
    required this.emailsSent,
    required this.calendarEventsCreated,
    this.portalPosting,
  });

  factory ExecutedActions.fromJson(Map<String, dynamic> json) {
    final emailsJson = json['emails_sent'] as List<dynamic>? ?? [];
    final emails = emailsJson.map((e) => EmailDispatchRecord.fromJson(e as Map<String, dynamic>)).toList();

    final eventsJson = json['calendar_events_created'] as List<dynamic>? ?? [];
    final events = eventsJson.map((e) => CalendarEventRecord.fromJson(e as Map<String, dynamic>)).toList();

    final portalJson = json['portal_posting'] as Map<String, dynamic>?;
    final portal = portalJson != null ? PortalPostingRecord.fromJson(portalJson) : null;

    return ExecutedActions(
      documentId: json['document_id'] ?? '',
      pdfPath: json['pdf_path'] ?? '',
      emailsSent: emails,
      calendarEventsCreated: events,
      portalPosting: portal,
    );
  }
}

class EmailDispatchRecord {
  final String vendorName;
  final String emailId;

  EmailDispatchRecord({
    required this.vendorName,
    required this.emailId,
  });

  factory EmailDispatchRecord.fromJson(Map<String, dynamic> json) {
    return EmailDispatchRecord(
      vendorName: json['vendor_name'] ?? '',
      emailId: json['email_id'] ?? '',
    );
  }
}

class CalendarEventRecord {
  final String title;
  final String eventId;

  CalendarEventRecord({
    required this.title,
    required this.eventId,
  });

  factory CalendarEventRecord.fromJson(Map<String, dynamic> json) {
    return CalendarEventRecord(
      title: json['title'] ?? '',
      eventId: json['event_id'] ?? '',
    );
  }
}

class PortalPostingRecord {
  final String referenceId;
  final String postingId;
  final String postedUrl;

  PortalPostingRecord({
    required this.referenceId,
    required this.postingId,
    required this.postedUrl,
  });

  factory PortalPostingRecord.fromJson(Map<String, dynamic> json) {
    return PortalPostingRecord(
      referenceId: json['reference_id'] ?? '',
      postingId: json['posting_id'] ?? '',
      postedUrl: json['posted_url'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Database Document/Email/Event/Portal entities
// ---------------------------------------------------------------------------
class GeneratedDocument {
  final String id;
  final String jobId;
  final String documentType;
  final String filePath;
  final String pdfUrl;
  final Map<String, dynamic>? contentJson;
  final String createdAt;

  GeneratedDocument({
    required this.id,
    required this.jobId,
    required this.documentType,
    required this.filePath,
    required this.pdfUrl,
    this.contentJson,
    required this.createdAt,
  });

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      documentType: json['document_type'] ?? '',
      filePath: json['file_path'] ?? '',
      pdfUrl: json['pdf_url'] ?? '',
      contentJson: json['content_json'] as Map<String, dynamic>?,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SentEmail {
  final String id;
  final String jobId;
  final String toEmail;
  final String toName;
  final String subject;
  final String body;
  final String sentAt;

  SentEmail({
    required this.id,
    required this.jobId,
    required this.toEmail,
    required this.toName,
    required this.subject,
    required this.body,
    required this.sentAt,
  });

  factory SentEmail.fromJson(Map<String, dynamic> json) {
    return SentEmail(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      toEmail: json['to_email'] ?? '',
      toName: json['to_name'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      sentAt: json['sent_at'] ?? '',
    );
  }
}

class CalendarEvent {
  final String id;
  final String jobId;
  final String title;
  final String description;
  final String eventDate;
  final List<String> attendees;
  final String createdAt;

  CalendarEvent({
    required this.id,
    required this.jobId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.attendees,
    required this.createdAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventDate: json['event_date'] ?? '',
      attendees: List<String>.from(json['attendees'] ?? []),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PortalPosting {
  final String id;
  final String jobId;
  final String referenceId;
  final String title;
  final String postedUrl;
  final String closingDate;
  final String postedAt;

  PortalPosting({
    required this.id,
    required this.jobId,
    required this.referenceId,
    required this.title,
    required this.postedUrl,
    required this.closingDate,
    required this.postedAt,
  });

  factory PortalPosting.fromJson(Map<String, dynamic> json) {
    return PortalPosting(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      referenceId: json['reference_id'] ?? '',
      title: json['title'] ?? '',
      postedUrl: json['posted_url'] ?? '',
      closingDate: json['closing_date'] ?? '',
      postedAt: json['posted_at'] ?? '',
    );
  }
}
