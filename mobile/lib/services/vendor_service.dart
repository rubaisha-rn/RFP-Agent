import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/vendor_organization.dart';
import '../models/public_rfp.dart';

class VendorService {
  final _apiClient = ApiClient();

  Future<VendorOrganization> signup({
    required String companyName,
    required String email,
    required String password,
    required String ntnNumber,
    required List<String> categories,
  }) async {
    final response = await _apiClient.post('/vendor/signup', {
      'company_name': companyName,
      'email': email,
      'password': password,
      'ntn_number': ntnNumber,
      'categories': categories,
    });
    return VendorOrganization.fromJson(response);
  }

  Future<VendorOrganization> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/vendor/login', {
      'email': email,
      'password': password,
    });
    return VendorOrganization.fromJson(response);
  }

  Future<Map<String, dynamic>> getInbox(String vendorId) async {
    return await _apiClient.get('/vendor/inbox/$vendorId');
  }

  Future<PublicRfp> getPublicRfp(String jobId) async {
    final response = await _apiClient.get('/vendor/rfp/$jobId');
    return PublicRfp.fromJson(response);
  }

  Future<Map<String, dynamic>> submitResponse({
    required String vendorId,
    required String jobId,
    required num bidAmountPkr,
    required String technicalSummary,
  }) async {
    return await _apiClient.post('/vendor/respond', {
      'vendor_id': vendorId,
      'job_id': jobId,
      'bid_amount_pkr': bidAmountPkr,
      'technical_summary': technicalSummary,
    });
  }
}

class VendorAuthNotifier extends StateNotifier<VendorOrganization?> {
  final VendorService _vendorService;
  static const _storageKey = 'vendor_auth_organization';

  VendorAuthNotifier(this._vendorService) : super(null) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        state = VendorOrganization.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
  }

  Future<VendorOrganization> signup({
    required String companyName,
    required String email,
    required String password,
    required String ntnNumber,
    required List<String> categories,
  }) async {
    final org = await _vendorService.signup(
      companyName: companyName,
      email: email,
      password: password,
      ntnNumber: ntnNumber,
      categories: categories,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(org.toJson()));
    state = org;
    return org;
  }

  Future<VendorOrganization> login({
    required String email,
    required String password,
  }) async {
    final org = await _vendorService.login(email: email, password: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(org.toJson()));
    state = org;
    return org;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = null;
  }
}

final vendorServiceProvider = Provider<VendorService>((ref) => VendorService());
final vendorAuthProvider = StateNotifierProvider<VendorAuthNotifier, VendorOrganization?>((ref) {
  final service = ref.watch(vendorServiceProvider);
  return VendorAuthNotifier(service);
});
