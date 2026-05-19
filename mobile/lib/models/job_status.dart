class JobStatus {
  final String jobId;
  final String status;
  final String? currentAgent;
  final int progressPct;
  final int traceCount;
  final String? brief;
  final String? createdAt;
  final String? completedAt;

  JobStatus({
    required this.jobId,
    required this.status,
    this.currentAgent,
    required this.progressPct,
    required this.traceCount,
    this.brief,
    this.createdAt,
    this.completedAt,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      jobId: json['job_id'] ?? json['id'] ?? '',
      status: json['status'] ?? '',
      currentAgent: json['current_agent'],
      progressPct: json['progress_pct'] ?? 0,
      traceCount: json['trace_count'] ?? 0,
      brief: json['brief'],
      createdAt: json['created_at'],
      completedAt: json['completed_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'status': status,
      'current_agent': currentAgent,
      'progress_pct': progressPct,
      'trace_count': traceCount,
      'brief': brief,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  // Helpers
  bool get isComplete => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRunning => status == 'running' || status == 'pending';

  String get agentDisplayName {
    switch (currentAgent) {
      case 'classifier':
        return 'Requirements Classifier';
      case 'auditor':
        return 'Compliance Auditor';
      case 'vendor_intel':
        return 'Vendor Intelligence';
      case 'drafter':
        return 'Drafter & Executor';
      default:
        return 'Initializing Pipeline...';
    }
  }
}
