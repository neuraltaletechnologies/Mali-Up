import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Native: pictures are stored under the app cache directory, keyed by a hash
/// of the URL. The OS may clear that directory under storage pressure, which
/// is fine — a missing file just means one more download.
ImageProvider<Object> cachedImageProvider(String url) => DiskCachedImage(url);

/// Disk-backed [ImageProvider]. In-flight loads are already de-duplicated by
/// Flutter's [ImageCache] (same key → same completer), so two tiles showing
/// the same product only download it once.
@immutable
class DiskCachedImage extends ImageProvider<DiskCachedImage> {
  final String url;
  const DiskCachedImage(this.url);

  @override
  Future<DiskCachedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<DiskCachedImage>(this);

  @override
  ImageStreamCompleter loadImage(
    DiskCachedImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = await _ImageDiskCache.fileFor(url);

    Uint8List? bytes;
    if (file != null) {
      // Not cached yet → PathNotFoundException, caught below.
      try {
        bytes = await file.readAsBytes();
        if (bytes.isEmpty) bytes = null;
      } catch (_) {
        bytes = null;
      }
    }

    final fromDisk = bytes != null;
    if (bytes == null) {
      final uri = Uri.parse(url);
      final res = await http.get(uri);
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        throw NetworkImageLoadException(statusCode: res.statusCode, uri: uri);
      }
      bytes = res.bodyBytes;
    }

    try {
      final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      // Only persist bytes that actually decoded, so a captive-portal HTML
      // page or a truncated download never gets cached as a "picture".
      if (!fromDisk && file != null) {
        unawaited(_ImageDiskCache.write(file, bytes));
      }
      return codec;
    } catch (_) {
      if (fromDisk && file != null) {
        // Corrupt cache entry — drop it so the next attempt re-downloads.
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DiskCachedImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'DiskCachedImage("$url")';
}

class _ImageDiskCache {
  /// Above this the oldest pictures are pruned (checked once per launch).
  static const _maxBytes = 80 * 1024 * 1024;
  static const _pruneToBytes = 60 * 1024 * 1024;

  static Future<Directory?>? _dir;

  static Future<Directory?> _directory() => _dir ??= () async {
    try {
      final base = await getApplicationCacheDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}product_images');
      await dir.create(recursive: true);
      unawaited(_prune(dir));
      return dir;
    } catch (e) {
      debugPrint('[ImageDiskCache] unavailable: $e');
      return null;
    }
  }();

  static Future<File?> fileFor(String url) async {
    final dir = await _directory();
    if (dir == null) return null;
    final name = sha1.convert(utf8.encode(url)).toString();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  /// Write via a temp file + rename so a crash mid-write never leaves a
  /// half-written picture behind.
  static Future<void> write(File file, Uint8List bytes) async {
    try {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('[ImageDiskCache] write failed: $e');
    }
  }

  static Future<void> _prune(Directory dir) async {
    try {
      final files = <File, FileStat>{};
      var total = 0;
      await for (final e in dir.list(followLinks: false)) {
        if (e is! File) continue;
        final stat = e.statSync();
        files[e] = stat;
        total += stat.size;
      }
      if (total <= _maxBytes) return;
      final oldestFirst = files.entries.toList()
        ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
      for (final entry in oldestFirst) {
        if (total <= _pruneToBytes) break;
        try {
          await entry.key.delete();
          total -= entry.value.size;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ImageDiskCache] prune failed: $e');
    }
  }
}
