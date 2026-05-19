class JobStatus {
  final String jobId;
  final String status;
  final String? currentAgent;
  final int progressPct;
  final int traceCount;

  JobStatus({
    required this.jobId,
    required this.status,
    this.currentAgent,
    required this.progressPct,
    required this.traceCount,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      jobId: json['job_id'] ?? '',
      status: json['status'] ?? '',
      currentAgent: json['current_agent'],
      progressPct: json['progress_pct'] ?? 0,
      traceCount: json['trace_count'] ?? 0,
    );
  }
}
