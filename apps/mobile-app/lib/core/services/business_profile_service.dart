import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fired whenever the active business's profile (name, logo, plan) is edited,
/// so screens holding a cached copy — e.g. the dashboard Hero card, which
/// only refetches from Firestore once every 24h — know to refresh immediately.
class BusinessProfileService {
  BusinessProfileService._();

  static const _profileCacheKeyPrefix = 'business_profile_cache_v1_';

  static final ValueNotifier<int> updatedNotifier = ValueNotifier<int>(0);

  static void notifyUpdated() => updatedNotifier.value++;

  /// Keeps the business selector and management list available when Firestore
  /// cannot be reached. Only the fields needed to render those read-only
  /// surfaces are persisted; live Firestore data remains authoritative.
  static Future<void> cacheProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    try {
      final rawBusinesses = profile['businesses'];
      final businesses = rawBusinesses is List
          ? rawBusinesses.whereType<Map>().map(_cacheableBusiness).toList()
          : const <Map<String, dynamic>>[];

      final cached = <String, dynamic>{
        'selectedBusinessId': _stringValue(profile['selectedBusinessId']),
        'defaultContext': _stringValue(profile['defaultContext']),
        'defaultAccountType': _stringValue(profile['defaultAccountType']),
        'plan': _stringValue(profile['plan']),
        'isTeamMember': profile['isTeamMember'] == true,
        'businessId': _stringValue(profile['businessId']),
        'businesses': businesses,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_profileCacheKeyPrefix$uid', jsonEncode(cached));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('BusinessProfileService.cacheProfile failed: $error');
      }
    }
  }

  /// Returns the last successfully fetched business profile for [uid].
  /// The UID-scoped key prevents one signed-in account seeing another one's
  /// cached businesses on a shared device.
  static Future<Map<String, dynamic>?> loadCachedProfile(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('$_profileCacheKeyPrefix$uid');
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('BusinessProfileService.loadCachedProfile failed: $error');
      }
      return null;
    }
  }

  static Map<String, dynamic> _cacheableBusiness(Map entry) {
    const fields = <String>{
      'id',
      'businessName',
      'name',
      'businessCategory',
      'category',
      'city',
      'placeOfBusiness',
      'district',
      'phone',
      'email',
      'businessEmail',
      'logoUrl',
      'workingHours',
      'facebook',
      'instagram',
      'tiktok',
      'websiteUrl',
      'website',
      'hasWebsite',
      'websiteInterest',
      'x',
      'linkedin',
      'plan',
    };

    return <String, dynamic>{
      for (final field in fields)
        if (entry[field] is String ||
            entry[field] is bool ||
            entry[field] is num)
          field: entry[field],
    };
  }

  static String _stringValue(Object? value) => value is String ? value : '';
}
