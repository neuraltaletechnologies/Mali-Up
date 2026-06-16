import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the minimal role fields needed to gate the UI on a cold offline
/// start, when Firestore cannot be reached.
///
/// Keyed to the Firebase Auth UID so a cached role from a previous user is
/// never applied to a different account.
class RoleCacheService {
  RoleCacheService._();

  static const _keyUid          = 'mali_role_uid';
  static const _keyIsTeamMember = 'mali_role_isTeamMember';
  static const _keyOwnerUid     = 'mali_role_ownerUid';
  static const _keyBusinessId   = 'mali_role_businessId';
  static const _keyMemberId     = 'mali_role_memberId';

  /// Saves the relevant role fields from [profile] for [uid].
  /// Called every time Firestore emits a new snapshot so the cache stays fresh.
  static Future<void> save(String uid, Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final isTeamMember = profile['isTeamMember'] == true;
    await prefs.setString(_keyUid, uid);
    await prefs.setBool(_keyIsTeamMember, isTeamMember);
    if (isTeamMember) {
      await prefs.setString(_keyOwnerUid,   profile['ownerUid']   as String? ?? '');
      await prefs.setString(_keyBusinessId, profile['businessId'] as String? ?? '');
      await prefs.setString(_keyMemberId,   profile['memberId']   as String? ?? '');
    } else {
      await prefs.remove(_keyOwnerUid);
      await prefs.remove(_keyBusinessId);
      await prefs.remove(_keyMemberId);
    }
    if (kDebugMode) {
      debugPrint('[RBAC] RoleCacheService: saved uid=$uid isTeamMember=$isTeamMember');
    }
  }

  /// Returns the cached profile for [uid], or null if nothing is cached or
  /// the cached entry belongs to a different UID.
  static Future<Map<String, dynamic>?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyUid) != uid) return null;
    final isTeamMember = prefs.getBool(_keyIsTeamMember);
    if (isTeamMember == null) return null;
    return {
      'isTeamMember': isTeamMember,
      if (isTeamMember) ...{
        'ownerUid':   prefs.getString(_keyOwnerUid)   ?? '',
        'businessId': prefs.getString(_keyBusinessId) ?? '',
        'memberId':   prefs.getString(_keyMemberId)   ?? '',
      },
    };
  }

  /// Clears the cached role. Call on explicit sign-out so a subsequent user
  /// does not briefly see stale role data before Firestore responds.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyUid),
      prefs.remove(_keyIsTeamMember),
      prefs.remove(_keyOwnerUid),
      prefs.remove(_keyBusinessId),
      prefs.remove(_keyMemberId),
    ]);
    if (kDebugMode) debugPrint('[RBAC] RoleCacheService: cleared');
  }
}
