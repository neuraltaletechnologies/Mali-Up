import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../customer/data/customer_providers.dart';
import '../../invoice/domain/models/invoice.dart';
import '../../invoice/presentation/providers/invoice_providers.dart';
import '../../rbac/data/rbac_providers.dart';

// ── Offline-first sales stream ────────────────────────────────────────────────
//
// Reads from Drift via invoicesProvider (kept in sync by SyncService).
// The raw-map shape is preserved so all existing consumers (SalesScreen,
// dashboard widgets) require zero changes.

final salesInvoiceListProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(invoicesProvider).whenData(
        (invoices) => invoices.map(_invoiceToMap).toList(),
      );
});

Map<String, dynamic> _invoiceToMap(Invoice inv) => {
      'id': inv.id,
      'customerId': inv.customerId,
      'customerName': inv.customerName,
      'customerPhone': inv.customerPhone,
      'invoiceNumber': inv.invoiceNumber,
      'date': inv.date,
      'dueDate': inv.dueDate,
      'status': inv.status,
      'paymentStatus': inv.status,
      'type': inv.type,
      'subtotal': inv.subtotal,
      'discountAmount': inv.discountAmount,
      'tax': inv.tax,
      'vatAmount': inv.tax,
      'total': inv.total,
      'totalAmount': inv.total,
      'amount': inv.total,
      'amountPaid': inv.amountPaid,
      'paymentMethod': inv.paymentMethod,
      'items': inv.items.map((i) => i.toFirestore()).toList(),
      'note': inv.note,
      'notes': inv.note,
      'createdAt': inv.createdAt,
      'updatedAt': inv.updatedAt,
    };

// ── Tenant scoping ────────────────────────────────────────────────────────────

/// Tenant root + business context for sales writes.
///
/// Team members (cashiers, managers) must write into the *owner's* tenant —
/// never their own (empty) tenant — so the tenant root comes from
/// [tenantOwnerUidProvider] while the business is resolved from the signed-in
/// user's own profile.
class SalesScope {
  final String ownerUid;
  final String userUid;
  final ResolvedFinanceContext context;

  const SalesScope({
    required this.ownerUid,
    required this.userUid,
    required this.context,
  });

  String get businessId => context.businessId ?? '';
}

Future<SalesScope?> resolveSalesScope(WidgetRef ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final ownerUid = ref.read(tenantOwnerUidProvider) ?? user.uid;
  final repo = ref.read(contextFirestoreRepositoryProvider);

  var ctx = await repo.resolveContextForUser(user.uid);
  if ((ctx.businessId ?? '').isEmpty) {
    // Team-member profiles store the business directly.
    final profile = ref.read(userProfileStreamProvider).valueOrNull;
    final bizId = (profile?['businessId'] as String?)?.trim() ?? '';
    if (bizId.isNotEmpty) ctx = ResolvedFinanceContext.business(bizId);
  }
  return SalesScope(ownerUid: ownerUid, userUid: user.uid, context: ctx);
}

/// Display role of the signed-in user, for audit-trail records.
final currentUserRoleProvider = Provider<String>((ref) {
  final ps = ref.watch(permissionServiceProvider);
  if (ps.isOwner) return 'owner';
  final member = ref.watch(currentMemberProvider).valueOrNull;
  return member?.role.name ?? 'member';
});

// ── Field readers (tolerant of the various historic document shapes) ─────────

/// Reads the invoice total from either the quick-sale field ('amount') or the
/// full-invoice field ('totalAmount'), whichever is present and non-zero.
double readInvoiceTotal(Map<String, dynamic> item) {
  final a = parseNumericAmount(item['totalAmount']);
  if (a > 0) return a;
  return parseNumericAmount(item['amount']);
}

double parseNumericAmount(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final cleaned = value
      .toString()
      .replaceAll(RegExp(r'[^0-9.\-]'), '')
      .trim();
  return double.tryParse(cleaned) ?? 0;
}

String readInvoiceStatus(Map<String, dynamic> item) {
  final raw = (item['status'] ?? item['paymentStatus'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Pending';
  return raw;
}

DateTime? readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Normalizes a stored phone number into the digits-only international format
/// wa.me links require ('+', spaces, dashes and the local leading 0 all make
/// WhatsApp reject the link as an invalid number). Returns '' when the number
/// is too short to be dialable, so callers can fall back to a share-picker link.
String normalizeWhatsAppPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = '255${digits.substring(1)}';
  }
  return digits.length >= 9 ? digits : '';
}
