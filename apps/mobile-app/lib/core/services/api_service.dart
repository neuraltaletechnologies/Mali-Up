import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  /// Base URL for auth-service requests.
  ///
  /// Priority:
  /// 1. `API_BASE_URL` dart-define
  /// 2. debug defaults for emulator / desktop / web
  /// 3. production URL
  static String get _baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;

    if (kDebugMode) {
      if (Platform.isAndroid) return 'http://10.0.2.2:3001/api/v1';
      if (Platform.isIOS || Platform.isMacOS) return 'http://localhost:3001/api/v1';
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return 'http://localhost:3001/api/v1';
      }
    }

    return 'https://auth-service.maliup.com/api/v1';
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
          .timeout(Duration(seconds: _timeoutSeconds));

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
