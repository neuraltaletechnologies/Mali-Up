import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  /// Base URL for generic API requests.
  ///
  /// This app is Firebase-only for onboarding/auth. If you use this helper
  /// elsewhere, provide the endpoint explicitly with `API_BASE_URL`.
  static String get _baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    throw StateError(
      'API_BASE_URL is not configured. Provide an explicit endpoint when using this helper.',
    );
  }

  static const int _timeoutSeconds =
      int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 20);

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService.post] Error: $e');
      rethrow;
    }
  }
}
