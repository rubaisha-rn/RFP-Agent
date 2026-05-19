import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException(code: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final String _baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    print('[ApiClient] POST request to: $url');
    print('[ApiClient] Request body: ${jsonEncode(body)}');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('[ApiClient] POST response - Status Code: ${response.statusCode}');
      print('[ApiClient] Response body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('[ApiClient] POST request failed: $e');
      if (e is ApiException) rethrow;
      throw ApiException(500, e.toString());
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    print('[ApiClient] GET request to: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiClient] GET response - Status Code: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('[ApiClient] GET request failed: $e');
      if (e is ApiException) rethrow;
      throw ApiException(500, e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      // Body not JSON
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } else {
      String message = 'Something went wrong';
      if (decoded is Map<String, dynamic> && decoded.containsKey('detail')) {
        final detail = decoded['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          // FastAPI list of errors e.g., [{"loc":..., "msg":..., "type":...}]
          message = detail.map((e) {
            if (e is Map && e.containsKey('msg')) {
              return e['msg'].toString();
            }
            return e.toString();
          }).join(', ');
        } else {
          message = detail.toString();
        }
      }
      throw ApiException(response.statusCode, message);
    }
  }
}
