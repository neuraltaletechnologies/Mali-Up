import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

abstract final class SyncUtils {
  /// SHA-256 hex digest of [data].
  /// Stored alongside each sync-queue payload so the SyncService can detect
  /// in-flight corruption before sending data to Firestore.
  static String sha256(String data) {
    final digest = crypto.sha256.convert(utf8.encode(data));
    return digest.toString();
  }
}
