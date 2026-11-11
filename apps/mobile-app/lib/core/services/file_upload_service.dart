import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// What a photo is for — decides its folder in the R2 bucket.
enum UploadKind {
  logo('logo'),
  receipt('receipt'),
  returnProof('return');

  const UploadKind(this.wireName);
  final String wireName;
}

/// Thrown for any upload failure (auth, network, rejected file, server error).
class FileUploadException implements Exception {
  const FileUploadException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'FileUploadException($code${message == null ? '' : ': $message'})';
}

/// Uploads photos to Cloudflare R2 through the Mali Up file service Worker
/// (`services/file-service`). Replaces Firebase Storage.
///
/// Returns a full public URL (`<FILES_BASE_URL>/f/<key>`), so callers store
/// and display it exactly like the old Firebase download URLs. Old
/// `firebasestorage.googleapis.com` URLs already saved in the data keep
/// loading as before until `scripts/migrate-storage-to-r2.ts` rewrites them.
class FileUploadService {
  FileUploadService._();

  /// Override per build with `--dart-define=FILES_BASE_URL=...` (e.g. a
  /// `wrangler dev` URL). Must match `PUBLIC_BASE_URL` in the Worker config.
  static const String baseUrl = String.fromEnvironment(
    'FILES_BASE_URL',
    defaultValue: 'https://maliup-files.neuraltale.com',
  );

  /// Mirrors the Worker's limit. Picked photos are already downscaled to
  /// ≤1200px by image_picker, so real uploads are far below this.
  static const int maxBytes = 5 * 1024 * 1024;

  static const Duration _timeout = Duration(seconds: 60);

  static Future<String> uploadImage({
    required File file,
    required UploadKind kind,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const FileUploadException('unauthenticated', 'No signed-in user');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const FileUploadException('empty');
    if (bytes.length > maxBytes) throw const FileUploadException('too-large');

    final uri = Uri.parse('$baseUrl/v1/files')
        .replace(queryParameters: {'kind': kind.wireName});
    final contentType = contentTypeForPath(file.path);

    Future<http.Response> send(String? token) => http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${token ?? ''}',
            'Content-Type': contentType,
          },
          body: bytes,
        )
        .timeout(_timeout);

    try {
      var response = await send(await user.getIdToken());
      // A cached ID token can be just past expiry — refresh once and retry.
      if (response.statusCode == 401) {
        response = await send(await user.getIdToken(true));
      }
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw FileUploadException(
          'http-${response.statusCode}',
          _errorCode(response.body),
        );
      }
      final url = (jsonDecode(response.body) as Map<String, dynamic>)['url'];
      if (url is! String || url.isEmpty) {
        throw const FileUploadException('bad-response');
      }
      return url;
    } on FileUploadException {
      rethrow;
    } on TimeoutException {
      throw const FileUploadException('timeout');
    } on SocketException catch (e) {
      throw FileUploadException('network', e.message);
    } on http.ClientException catch (e) {
      throw FileUploadException('network', e.message);
    } on FirebaseAuthException catch (e) {
      throw FileUploadException('unauthenticated', e.code);
    } on FormatException catch (e) {
      throw FileUploadException('bad-response', e.message);
    }
  }

  static String contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['error']?.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
