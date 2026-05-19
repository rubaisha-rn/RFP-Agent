import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/job_status.dart';
import '../models/rfp_result.dart';
import '../models/vendor.dart';

class RfpService {
  final ApiClient _apiClient = ApiClient();

  /// Initiates RFP Generation by POSTing the brief to backend
  Future<String> generateRfp({
    required String brief,
    required String organizationId,
  }) async {
    final response = await _apiClient.post('/rfp/generate', {
      'brief': brief,
      'organization_id': organizationId,
    });
    return response['job_id'] ?? '';
  }

  /// Polls status of a job every 2 seconds, emitting updates on status
  Stream<JobStatus> watchJobStatus(String jobId) {
    late StreamController<JobStatus> controller;
    Timer? timer;

    void stopTimer() {
      timer?.cancel();
      timer = null;
    }

    controller = StreamController<JobStatus>(
      onListen: () {
        Future<void> tick() async {
          try {
            final data = await _apiClient.get('/rfp/status/$jobId');
            final jobStatus = JobStatus.fromJson(data);
            if (!controller.isClosed) {
              controller.add(jobStatus);
            }
            if (jobStatus.isComplete || jobStatus.isFailed) {
              stopTimer();
              if (!controller.isClosed) {
                await controller.close();
              }
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
            stopTimer();
            if (!controller.isClosed) {
              await controller.close();
            }
          }
        }

        tick(); // Fetch immediately
        timer = Timer.periodic(const Duration(seconds: 2), (t) => tick());
      },
      onCancel: () {
        stopTimer();
      },
    );

    return controller.stream;
  }

  /// Retrieves full result data for the results/preview page
  Future<RfpResult> getResult(String jobId) async {
    final response = await _apiClient.get('/rfp/result/$jobId');
    return RfpResult.fromJson(response);
  }

  /// Lists active non-blacklisted vendors, with optional category filtering
  Future<List<Vendor>> listContacts({String? category}) async {
    final query = category != null && category.isNotEmpty ? '?category=$category' : '';
    final response = await _apiClient.get('/contacts$query');
    final vendorsList = response['vendors'] as List<dynamic>? ?? [];
    return vendorsList.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final rfpServiceProvider = Provider<RfpService>((ref) => RfpService());
