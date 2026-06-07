import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists structured audit records under the owner's tenant.
///
/// Path: /tenants/{ownerUid}/businesses/{businessId}/audit_logs/{auto-id}
///
/// Callers should await these writes but must not crash if they fail —
/// audit logging is best-effort; the primary operation has already succeeded.
class AuditLogService {
  final FirebaseFirestore _firestore;

  AuditLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Action constants ──────────────────────────────────────────────────────

  static const String memberInvited    = 'member_invited';
  static const String memberRemoved    = 'member_removed';
  static const String memberSuspended  = 'member_suspended';
  static const String memberActivated  = 'member_activated';
  static const String roleChanged      = 'role_changed';
  static const String permissionsChanged = 'permissions_changed';

  // ── Write helpers ─────────────────────────────────────────────────────────

  /// Logs a team-management action.
  ///
  /// [ownerUid]       — Firestore tenant root (always the business owner's UID).
  /// [businessId]     — The business the action took place in.
  /// [performedByUid] — Firebase Auth UID of the actor.
  /// [performedByName]— Display name of the actor.
  /// [action]         — One of the action constants above.
  /// [targetMemberId] — Document ID of the affected team member.
  /// [targetName]     — Display name of the affected member.
  /// [previousValue]  — State before the change (nullable).
  /// [newValue]       — State after the change (nullable).
  Future<void> log({
    required String ownerUid,
    required String businessId,
    required String performedByUid,
    required String performedByName,
    required String action,
    required String targetMemberId,
    required String targetName,
    Object? previousValue,
    Object? newValue,
  }) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(ownerUid)
          .collection('businesses')
          .doc(businessId)
          .collection('audit_logs')
          .add({
        'action': action,
        'performedBy': performedByUid,
        'performedByName': performedByName,
        'targetMemberId': targetMemberId,
        'targetName': targetName,
        'previousValue': ?previousValue,
        'newValue': ?newValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort: do not propagate audit-log failures.
    }
  }
}
