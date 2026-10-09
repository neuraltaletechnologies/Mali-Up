import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// One administrative division returned by the Country-State-City API — a
/// state/region ("mkoa") or a city/district ("wilaya"). [code] is the API's
/// alpha-2 state code and is only populated for regions (cities have no code).
@immutable
class GeoDivision {
  const GeoDivision({required this.name, this.code});

  final String name;
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is GeoDivision && other.name == name && other.code == code;

  @override
  int get hashCode => Object.hash(name, code);
}

/// Live worldwide region/district lookup, backed by the free
/// [Country-State-City API](https://countrystatecity.in).
///
/// Tanzania is **not** served from here — it has a curated local + Firestore
/// dataset in [LookupService]. Everywhere else, [fetchRegions] is called when a
/// country is picked and [fetchDistricts] when a region is picked.
///
/// The API key is injected at build time:
/// `flutter run --dart-define=CSC_API_KEY=xxxx` (or via `.env.json`). When it
/// is missing every call returns an empty list and the UI falls back to
/// free-text entry — the app never blocks on this.
///
/// Results are cached to disk per country/region, the same "fetch once,
/// persist, refresh silently" policy as [LookupService] and the product
/// catalog: a cached list is returned immediately, and refreshed from the
/// API in the background without ever blocking the picker or failing
/// because the cache is old.
class GeoLookupService {
  GeoLookupService._();

  static const String _apiKey = String.fromEnvironment('CSC_API_KEY');
  static const String _base = 'https://api.countrystatecity.in/v1';
  static const Duration _timeout = Duration(seconds: 12);

  /// True when a key was compiled in. When false, callers should go straight
  /// to free-text entry rather than showing a spinner that can't resolve.
  static bool get isConfigured => _apiKey.isNotEmpty;

  // In-memory mirror of the disk cache — avoids a SharedPreferences read on
  // every keystroke while a picker is open in the same session.
  static final Map<String, List<GeoDivision>> _regionCache = {};
  static final Map<String, List<GeoDivision>> _districtCache = {};

  /// Regions ("mkoa") for an ISO 3166-1 alpha-2 [countryCode].
  /// Returns `[]` on any failure, an empty result, or a missing API key.
  static Future<List<GeoDivision>> fetchRegions(String countryCode) async {
    final cc = countryCode.toUpperCase();
    if (!isConfigured || cc.isEmpty) return const [];
    return _cachedFetch(
      memCache: _regionCache,
      key: cc,
      cacheKey: 'geo_cache_regions_$cc',
      fetchRemote: () async {
        final result = await _get('/countries/$cc/states');
        return result
            .map((e) => GeoDivision(
                  name: (e['name'] ?? '').toString().trim(),
                  code: (e['iso2'] ?? '').toString().trim().isEmpty
                      ? null
                      : (e['iso2']).toString().trim(),
                ))
            .where((r) => r.name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      },
    );
  }

  /// Districts ("wilaya") — the API's cities — for a region within a country.
  /// Returns `[]` on any failure, an empty result, or a missing API key.
  static Future<List<GeoDivision>> fetchDistricts(
    String countryCode,
    String regionCode,
  ) async {
    final cc = countryCode.toUpperCase();
    final rc = regionCode.toUpperCase();
    if (!isConfigured || cc.isEmpty || rc.isEmpty) return const [];
    return _cachedFetch(
      memCache: _districtCache,
      key: '$cc/$rc',
      cacheKey: 'geo_cache_districts_${cc}_$rc',
      fetchRemote: () async {
        final result = await _get('/countries/$cc/states/$rc/cities');
        return result
            .map((e) => GeoDivision(name: (e['name'] ?? '').toString().trim()))
            .where((d) => d.name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      },
    );
  }

  /// Shared cache-then-fetch flow for both regions and districts: an
  /// in-memory hit returns instantly; a disk hit returns instantly and
  /// refreshes in the background; otherwise it fetches live and, only on a
  /// non-empty result, writes through to both caches (an empty result is
  /// never cached, so the next call retries rather than getting stuck).
  static Future<List<GeoDivision>> _cachedFetch({
    required Map<String, List<GeoDivision>> memCache,
    required String key,
    required String cacheKey,
    required Future<List<GeoDivision>> Function() fetchRemote,
  }) async {
    final memCached = memCache[key];
    if (memCached != null) return memCached;

    final prefs = await SharedPreferences.getInstance();
    final diskCached = _decode(prefs.getString(cacheKey));
    if (diskCached != null && diskCached.isNotEmpty) {
      memCache[key] = diskCached;
      unawaited(_refresh(memCache, key, cacheKey, prefs, fetchRemote));
      return diskCached;
    }

    List<GeoDivision> fetched;
    try {
      fetched = await fetchRemote();
    } catch (_) {
      fetched = const [];
    }
    if (fetched.isNotEmpty) {
      memCache[key] = fetched;
      try {
        await prefs.setString(cacheKey, _encode(fetched));
      } catch (_) {}
    }
    return fetched;
  }

  static Future<void> _refresh(
    Map<String, List<GeoDivision>> memCache,
    String key,
    String cacheKey,
    SharedPreferences prefs,
    Future<List<GeoDivision>> Function() fetchRemote,
  ) async {
    try {
      final fetched = await fetchRemote();
      if (fetched.isEmpty) return;
      memCache[key] = fetched;
      await prefs.setString(cacheKey, _encode(fetched));
    } catch (_) {}
  }

  static String _encode(List<GeoDivision> divisions) => jsonEncode(
        divisions.map((d) => {'name': d.name, 'code': d.code}).toList(),
      );

  static List<GeoDivision>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((e) => GeoDivision(
                name: (e as Map)['name'] as String? ?? '',
                code: e['code'] as String?,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_base$path'),
        headers: {'X-CSCAPI-KEY': _apiKey},
      ).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[GeoLookupService] $path → HTTP ${res.statusCode}');
        }
        return const [];
      }
      final decoded = json.decode(res.body);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[GeoLookupService] $path failed: $e');
      return const [];
    }
  }
}
