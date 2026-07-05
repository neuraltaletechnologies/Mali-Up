import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the minimal role fields needed to gate the UI on a cold offline
/// start, when Firestore cannot be reached.
///
/// Keyed to the Firebase Auth UID so a cached role from a previous user is
/// never applied to a different account. Uses secure storage (not
/// SharedPreferences) since these fields identify which business/owner
/// account a device belongs to.
class RoleCacheService {
  RoleCacheService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyUid          = 'mali_role_uid';
  static const _keyIsTeamMember = 'mali_role_isTeamMember';
  static const _keyOwnerUid     = 'mali_role_ownerUid';
  static const _keyBusinessId   = 'mali_role_businessId';
  static const _keyMemberId     = 'mali_role_memberId';

  // Resolved active businessId (owner's `selectedBusinessId` or member's
  // `businessId`), cached separately from the role fields above so
  // `currentBusinessIdProvider` can serve it on a cold offline start —
  // see [saveBusinessId] / [loadBusinessId].
  static const _keyResolvedBusinessId = 'mali_resolved_business_id';

  /// Saves the relevant role fields from [profile] for [uid].
  /// Called every time Firestore emits a new snapshot so the cache stays fresh.
  static Future<void> save(String uid, Map<String, dynamic> profile) async {
    final isTeamMember = profile['isTeamMember'] == true;
    await _storage.write(key: _keyUid, value: uid);
    await _storage.write(key: _keyIsTeamMember, value: isTeamMember.toString());
    if (isTeamMember) {
      await _storage.write(key: _keyOwnerUid, value: profile['ownerUid'] as String? ?? '');
      await _storage.write(key: _keyBusinessId, value: profile['businessId'] as String? ?? '');
      await _storage.write(key: _keyMemberId, value: profile['memberId'] as String? ?? '');
    } else {
      await _storage.delete(key: _keyOwnerUid);
      await _storage.delete(key: _keyBusinessId);
      await _storage.delete(key: _keyMemberId);
    }
    if (kDebugMode) {
      debugPrint('[RBAC] RoleCacheService: saved uid=$uid isTeamMember=$isTeamMember');
    }
  }

  /// Returns the cached profile for [uid], or null if nothing is cached or
  /// the cached entry belongs to a different UID.
  static Future<Map<String, dynamic>?> load(String uid) async {
    final cachedUid = await _storage.read(key: _keyUid);
    if (cachedUid != uid) return null;
    final isTeamMemberRaw = await _storage.read(key: _keyIsTeamMember);
    if (isTeamMemberRaw == null) return null;
    final isTeamMember = isTeamMemberRaw == 'true';
    return {
      'isTeamMember': isTeamMember,
      if (isTeamMember) ...{
        'ownerUid':   await _storage.read(key: _keyOwnerUid)   ?? '',
        'businessId': await _storage.read(key: _keyBusinessId) ?? '',
        'memberId':   await _storage.read(key: _keyMemberId)   ?? '',
      },
    };
  }

  /// Saves the resolved active businessId for [uid] so
  /// `currentBusinessIdProvider` can serve it immediately on a cold offline
  /// start, before the live Firestore snapshot arrives.
  static Future<void> saveBusinessId(String uid, String businessId) async {
    await _storage.write(key: _keyUid, value: uid);
    await _storage.write(key: _keyResolvedBusinessId, value: businessId);
  }

  /// Returns the cached resolved businessId for [uid], or null if nothing is
  /// cached or the cached entry belongs to a different UID.
  static Future<String?> loadBusinessId(String uid) async {
    final cachedUid = await _storage.read(key: _keyUid);
    if (cachedUid != uid) return null;
    return _storage.read(key: _keyResolvedBusinessId);
  }

  /// Clears the cached role. Call on explicit sign-out so a subsequent user
  /// does not briefly see stale role data before Firestore responds.
  static Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keyUid),
      _storage.delete(key: _keyIsTeamMember),
      _storage.delete(key: _keyOwnerUid),
      _storage.delete(key: _keyBusinessId),
      _storage.delete(key: _keyMemberId),
      _storage.delete(key: _keyResolvedBusinessId),
    ]);
    if (kDebugMode) debugPrint('[RBAC] RoleCacheService: cleared');
  }
}
