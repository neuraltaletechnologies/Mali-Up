import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
class GeoLookupService {
  GeoLookupService._();

  static const String _apiKey = String.fromEnvironment('CSC_API_KEY');
  static const String _base = 'https://api.countrystatecity.in/v1';
  static const Duration _timeout = Duration(seconds: 12);

  /// True when a key was compiled in. When false, callers should go straight
  /// to free-text entry rather than showing a spinner that can't resolve.
  static bool get isConfigured => _apiKey.isNotEmpty;

  // Session caches — onboarding is short-lived, so in-memory is enough.
  static final Map<String, List<GeoDivision>> _regionCache = {};
  static final Map<String, List<GeoDivision>> _districtCache = {};

  /// Regions ("mkoa") for an ISO 3166-1 alpha-2 [countryCode].
  /// Returns `[]` on any failure, an empty result, or a missing API key.
  static Future<List<GeoDivision>> fetchRegions(String countryCode) async {
    final cc = countryCode.toUpperCase();
    if (!isConfigured || cc.isEmpty) return const [];
    final cached = _regionCache[cc];
    if (cached != null) return cached;

    final result = await _get('/countries/$cc/states');
    final regions = result
        .map((e) => GeoDivision(
              name: (e['name'] ?? '').toString().trim(),
              code: (e['iso2'] ?? '').toString().trim().isEmpty
                  ? null
                  : (e['iso2']).toString().trim(),
            ))
        .where((r) => r.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (regions.isNotEmpty) _regionCache[cc] = regions;
    return regions;
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
    final key = '$cc/$rc';
    final cached = _districtCache[key];
    if (cached != null) return cached;

    final result = await _get('/countries/$cc/states/$rc/cities');
    final districts = result
        .map((e) => GeoDivision(name: (e['name'] ?? '').toString().trim()))
        .where((d) => d.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (districts.isNotEmpty) _districtCache[key] = districts;
    return districts;
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
