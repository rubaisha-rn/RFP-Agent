import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/organization.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Organization> signup({
    required String email,
    required String password,
    required String companyName,
  }) async {
    final response = await _apiClient.post('/auth/signup', {
      'company_email': email,
      'password': password,
      'company_name': companyName,
    });
    return Organization.fromJson(response);
  }

  Future<Organization> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/auth/login', {
      'company_email': email,
      'password': password,
    });
    return Organization.fromJson(response);
  }

  Future<void> completeOnboarding(String organizationId) async {
    await _apiClient.post('/auth/complete-onboarding', {
        'organization_id': organizationId,
    });
  }
}

class AuthNotifier extends StateNotifier<Organization?> {
  final AuthService _authService;
  static const String _prefKey = 'auth_organization';

  AuthNotifier(this._authService) : super(null) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrg = prefs.getString(_prefKey);
      if (savedOrg != null) {
        state = Organization.fromJson(jsonDecode(savedOrg));
        print('[AuthNotifier] Restored session for organization: ${state?.companyName}');
      }
    } catch (e) {
      print('[AuthNotifier] Error loading session: $e');
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String companyName,
  }) async {
    final org = await _authService.signup(
      email: email,
      password: password,
      companyName: companyName,
    );
    await _saveSession(org);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final org = await _authService.login(
      email: email,
      password: password,
    );
    await _saveSession(org);
  }

  Future<void> completeOnboarding() async {
    if (state == null) return;
    await _authService.completeOnboarding(state!.id);

    final updated = Organization(
        id: state!.id,
        companyName: state!.companyName,
        companyEmail: state!.companyEmail,
        isOnboarded: true,
    );

    await _saveSession(updated);
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    print('[AuthNotifier] Logged out successfully');
  }

  Future<void> _saveSession(Organization org) async {
    state = org;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(org.toJson()));
    print('[AuthNotifier] Saved session for organization: ${org.companyName}');
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, Organization?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
