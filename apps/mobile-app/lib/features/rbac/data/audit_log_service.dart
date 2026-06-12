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

  // Customer-management actions
  static const String customerCreated     = 'customer_created';
  static const String customerUpdated     = 'customer_updated';
  static const String customerDeleted     = 'customer_deleted';
  static const String creditLimitChanged  = 'credit_limit_changed';
  static const String tagAdded            = 'tag_added';
  static const String tagRemoved          = 'tag_removed';
  static const String reminderSent        = 'reminder_sent';

  // Sales & invoicing actions
  static const String saleCreated       = 'sale_created';
  static const String invoiceEdited     = 'invoice_edited';
  static const String paymentReceived   = 'payment_received';
  static const String returnProcessed   = 'return_processed';
  static const String invoiceCancelled  = 'invoice_cancelled';
  static const String invoiceDeleted    = 'invoice_deleted';
  static const String quotationConverted = 'quotation_converted';

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

  /// Logs a customer-management action (created / updated / credit limit /
  /// tags / reminders). Same best-effort semantics as [log].
  Future<void> logCustomerAction({
    required String ownerUid,
    required String businessId,
    required String performedByUid,
    required String action,
    required String customerId,
    required String customerName,
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
        'entityType': 'customer',
        'entityId': customerId,
        'entityName': customerName,
        'performedBy': performedByUid,
        'previousValue': ?previousValue,
        'newValue': ?newValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort: do not propagate audit-log failures.
    }
  }

  /// Logs a sales action (sale created / payment / return / cancel / edit).
  /// Same best-effort semantics as [log].
  Future<void> logSaleAction({
    required String ownerUid,
    required String businessId,
    required String performedByUid,
    required String performedByRole,
    required String action,
    required String invoiceId,
    required String invoiceNumber,
    Object? amount,
    Object? details,
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
        'entityType': 'sale',
        'entityId': invoiceId,
        'entityName': invoiceNumber,
        'performedBy': performedByUid,
        'performedByRole': performedByRole,
        'amount': ?amount,
        'details': ?details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort: do not propagate audit-log failures.
    }
  }
}
