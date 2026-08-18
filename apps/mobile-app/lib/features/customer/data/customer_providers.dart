import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../invoice/domain/models/invoice.dart';
import '../../invoice/presentation/providers/invoice_providers.dart';
import '../../rbac/data/audit_log_service.dart';
import '../../rbac/data/rbac_providers.dart';
import 'mappers/customer_mapper.dart';
import 'repositories/sync_customer_repository.dart';
import '../domain/models/customer.dart';

export '../../../core/providers/business_id_provider.dart'
    show currentBusinessIdProvider;

DateTime? _toDateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

final contextFirestoreRepositoryProvider = Provider<ContextFirestoreRepository>((ref) {
  return ContextFirestoreRepository();
});

/// Role-based visibility: owners, managers (manageCustomers) and finance
/// roles (viewDebt — accountants need the full receivables book) see every
/// customer. Other members (e.g. cashiers with viewCustomers only) are
/// limited to customers they created or are assigned to.
final canSeeAllCustomersProvider = Provider<bool>((ref) {
  final ps = ref.watch(permissionServiceProvider);
  return ps.isOwner || ps.canManageCustomers || ps.canViewDebt;
});

/// Offline-first customer stream backed by Drift, scoped by role.
/// Uses the DAO + CustomerMapper directly to avoid circular imports
/// with the presentation layer.
final customerListProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(_customerDatabaseProvider);
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const []);
  final seeAll = ref.watch(canSeeAllCustomersProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return db.customerDao.watchAll(bizId).map((rows) {
    final customers = rows.map(CustomerMapper.fromRow).toList();
    if (seeAll) return customers;
    return customers.where((c) => c.isVisibleTo(uid)).toList();
  });
});

// ── Audit trail ──────────────────────────────────────────────────────────────

/// Best-effort audit logger pre-bound to the active tenant/business/actor.
/// All customer mutations (create, update, delete, credit limit, tags,
/// reminders) should be recorded through this.
final customerAuditLoggerProvider = Provider<CustomerAuditLogger>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return CustomerAuditLogger(
    service: AuditLogService(),
    ownerUid: ref.watch(tenantOwnerUidProvider) ?? '',
    businessId: ref.watch(currentBusinessIdProvider).valueOrNull ?? '',
    actorUid: user?.uid ?? '',
  );
});

class CustomerAuditLogger {
  final AuditLogService service;
  final String ownerUid;
  final String businessId;
  final String actorUid;

  const CustomerAuditLogger({
    required this.service,
    required this.ownerUid,
    required this.businessId,
    required this.actorUid,
  });

  Future<void> log(
    String action, {
    required String customerId,
    required String customerName,
    Object? previousValue,
    Object? newValue,
  }) {
    if (ownerUid.isEmpty || businessId.isEmpty) return Future.value();
    return service.logCustomerAction(
      ownerUid: ownerUid,
      businessId: businessId,
      performedByUid: actorUid,
      action: action,
      customerId: customerId,
      customerName: customerName,
      previousValue: previousValue,
      newValue: newValue,
    );
  }
}

final _customerDatabaseProvider = Provider((ref) =>
    ref.watch(appDatabaseProvider));

/// Offline-first write path for customers: commits to Drift and the sync
/// queue in one transaction; [SyncService] pushes to Firestore when online.
/// Scoped to the tenant owner so team members write to the owner's business.
final customerRepositoryProvider = Provider<SyncCustomerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = ref.watch(tenantOwnerUidProvider) ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  final policy = ref.watch(offlinePolicyProvider);
  return SyncCustomerRepository(
    db: db,
    uid: uid,
    businessId: bizId,
    policy: policy,
    // Push immediately after a write instead of waiting for the next app
    // launch or connectivity blip — otherwise a customer added on one
    // device can sit queued locally until something else triggers a sync.
    onWrite: () => ref.read(syncServiceProvider).syncNow(),
  );
});

// Invoices belonging to a specific customer — read from Drift (offline-first).
// Derives from invoicesProvider so new sales appear immediately without waiting
// for Firestore sync.
final customerInvoicesProvider =
    Provider.family<AsyncValue<List<Map<String, dynamic>>>, String>(
        (ref, customerId) {
  if (customerId.isEmpty) return const AsyncValue.data([]);
  return ref.watch(invoicesProvider).whenData((invoices) {
    final filtered = invoices.where((inv) => inv.customerId == customerId).toList()
      ..sort((a, b) {
        final at = _toDateTime(a.createdAt);
        final bt = _toDateTime(b.createdAt);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    return filtered.map(_invoiceModelToMap).toList();
  });
});

Map<String, dynamic> _invoiceModelToMap(Invoice inv) => {
      'id': inv.id,
      'customerId': inv.customerId,
      'invoiceNumber': inv.invoiceNumber,
      'status': inv.status,
      'type': inv.type,
      'totalAmount': inv.total,
      'amount': inv.total,
      'amountPaid': inv.amountPaid,
      'lineItems': inv.items.map((i) => i.toFirestore()).toList(),
      'createdAt': inv.createdAt,
      'invoiceDate': inv.date,
      'dueDate': inv.dueDate,
    };

// Payment records per customer (subcollection — written on manual debt payments)
final customerPaymentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final ownerUid = ref.watch(tenantOwnerUidProvider) ?? user.uid;
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) return;
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final customersCol = repo.scopeCollection(
    uid: ownerUid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'customers',
  );
  yield* customersCol
      .doc(customerId)
      .collection('payments')
      .orderBy('paidAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// Communication log / notes per customer (subcollection)
final customerNotesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || customerId.isEmpty) {
    yield const [];
    return;
  }
  final ownerUid = ref.watch(tenantOwnerUidProvider) ?? user.uid;
  final businessAsync = ref.watch(currentBusinessIdProvider);
  if (businessAsync.isLoading) {
    return;
  }
  final bizId = businessAsync.valueOrNull;
  if (bizId == null || bizId.isEmpty) {
    yield const [];
    return;
  }
  final repo = ref.read(contextFirestoreRepositoryProvider);
  final customersCol = repo.scopeCollection(
    uid: ownerUid,
    context: ResolvedFinanceContext.business(bizId),
    childCollection: 'customers',
  );
  yield* customersCol
      .doc(customerId)
      .collection('notes')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

