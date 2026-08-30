import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/customer/domain/models/customer.dart';
import '../../../features/debt/domain/models/debt.dart';
import '../../../features/finance/domain/models/cash_account.dart';
import '../../../features/finance/domain/models/cash_transaction.dart';
import '../../../features/finance/domain/models/daily_reconciliation.dart';
import '../../../features/finance/domain/models/expense.dart';
import '../../services/sentry_metrics_service.dart';
import '../../../features/team/domain/models/custom_role.dart';
import '../../../features/team/domain/models/team_member.dart';


enum FinanceContextType { business }

class ResolvedFinanceContext {
  final FinanceContextType type;
  final String? businessId;

  const ResolvedFinanceContext._({
    required this.type,
    required this.businessId,
  });

  const ResolvedFinanceContext.business(String businessId)
    : this._(type: FinanceContextType.business, businessId: businessId);

  bool get isBusiness => type == FinanceContextType.business;
}

class ContextFirestoreRepository {
  final FirebaseFirestore _firestore;

  ContextFirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ResolvedFinanceContext> resolveContextForUser(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions());
      return resolveContextFromData(snapshot.data());
    } catch (_) {
      return const ResolvedFinanceContext.business('');
    }
  }

  /// Resolves finance context synchronously from an already-fetched profile map.
  /// Used by [currentBusinessIdProvider] to avoid redundant Firestore reads.
  ResolvedFinanceContext resolveContextFromData(Map<String, dynamic>? data) {
    // Firestore document IDs are case-sensitive, so only the prefix check
    // below may be lowercased — the ID itself must be extracted from the
    // original-case string, or a businessId like "r6vNvUx4..." gets mangled
    // into "r6vnvux4...", a document that doesn't exist, and every
    // downstream read/write against it is denied by security rules.
    final rawDefaultContext = (data?['defaultContext'] as String?)?.trim();
    final defaultContext = rawDefaultContext?.toLowerCase();
    final selectedBusinessId = (data?['selectedBusinessId'] as String?)?.trim();
    // Fallback for team members: they have `businessId` but not `selectedBusinessId`.
    final memberBusinessId = (data?['businessId'] as String?)?.trim();

    if (defaultContext != null && defaultContext.startsWith('business')) {
      final businessId = _businessIdFromContext(rawDefaultContext!) ??
          selectedBusinessId ??
          memberBusinessId;
      if (businessId != null && businessId.isNotEmpty) {
        return ResolvedFinanceContext.business(businessId);
      }
    }

    final defaultAccountType =
        (data?['defaultAccountType'] as String?)?.toLowerCase();
    if (defaultAccountType == 'business') {
      final businessId = selectedBusinessId ?? memberBusinessId;
      if (businessId != null && businessId.isNotEmpty) {
        return ResolvedFinanceContext.business(businessId);
      }
    }

    final businessId = selectedBusinessId ?? memberBusinessId;
    if (businessId != null && businessId.isNotEmpty) {
      return ResolvedFinanceContext.business(businessId);
    }

    return const ResolvedFinanceContext.business('');
  }

  Stream<List<Customer>> watchCustomers({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'customers',
    ).orderBy('name');

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> addCustomer({
    required String uid,
    required ResolvedFinanceContext context,
    required Customer customer,
  }) async {
    final ref = await _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'customers',
    ).add(customer.toFirestore());
    SentryMetricsService.customerAdded(source: 'repository');
    return ref;
  }

  Stream<List<Debt>> watchDebts({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'debts',
    ).orderBy('dueDate');

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Debt.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<DebtPayment>> watchDebtPayments({
    required String uid,
    required ResolvedFinanceContext context,
    required String debtId,
  }) {
    return _scopeCollection(uid: uid, context: context, childCollection: 'debts')
        .doc(debtId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DebtPayment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addDebtPayment({
    required String uid,
    required ResolvedFinanceContext context,
    required String debtId,
    required Map<String, dynamic> paymentData,
  }) {
    return _scopeCollection(uid: uid, context: context, childCollection: 'debts')
        .doc(debtId)
        .collection('payments')
        .add(paymentData);
  }

  Stream<List<Expense>> watchExpenses({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expenses',
    ).orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addExpense({
    required String uid,
    required ResolvedFinanceContext context,
    required Expense expense,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expenses',
    ).add(expense.toFirestore());
  }

  Future<void> addRecurringTemplate({
    required String uid,
    required ResolvedFinanceContext context,
    required Map<String, dynamic> templateData,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expense_templates',
    ).add(templateData);
  }

  Stream<List<Map<String, dynamic>>> watchRecurringTemplates({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expense_templates',
    ).orderBy('category').snapshots().map((snap) {
      return snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  Future<void> deleteRecurringTemplate({
    required String uid,
    required ResolvedFinanceContext context,
    required String templateId,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expense_templates',
    ).doc(templateId).delete();
  }

  Stream<List<CashAccount>> watchCashAccounts({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_accounts',
    ).orderBy('name');

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CashAccount.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> addCashAccount({
    required String uid,
    required ResolvedFinanceContext context,
    required CashAccount account,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_accounts',
    ).add({...account.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateCashAccount({
    required String uid,
    required ResolvedFinanceContext context,
    required String accountId,
    required Map<String, dynamic> data,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_accounts',
    ).doc(accountId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteCashAccount({
    required String uid,
    required ResolvedFinanceContext context,
    required String accountId,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_accounts',
    ).doc(accountId).delete();
  }

  // ── Cash transactions ────────────────────────────────────────────────────────

  Stream<List<CashTransaction>> watchCashTransactions({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_transactions',
    ).orderBy('date', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((doc) => CashTransaction.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Atomically records the transaction and adjusts account balance(s).
  Future<void> addCashTransaction({
    required String uid,
    required ResolvedFinanceContext context,
    required CashTransaction txn,
  }) async {
    final batch = _firestore.batch();

    final txnCol = _scopeCollection(uid: uid, context: context, childCollection: 'cash_transactions');
    final txnRef = txnCol.doc();
    batch.set(txnRef, {
      ...txn.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final accountCol = _scopeCollection(uid: uid, context: context, childCollection: 'cash_accounts');
    final ts = FieldValue.serverTimestamp();

    if (txn.isDeposit && txn.toAccountId.isNotEmpty) {
      batch.update(accountCol.doc(txn.toAccountId), {
        'balance': FieldValue.increment(txn.amount),
        'updatedAt': ts,
      });
    } else if (txn.isWithdrawal && txn.fromAccountId.isNotEmpty) {
      batch.update(accountCol.doc(txn.fromAccountId), {
        'balance': FieldValue.increment(-txn.amount),
        'updatedAt': ts,
      });
    } else if (txn.isTransfer) {
      if (txn.fromAccountId.isNotEmpty) {
        batch.update(accountCol.doc(txn.fromAccountId), {
          'balance': FieldValue.increment(-txn.amount),
          'updatedAt': ts,
        });
      }
      if (txn.toAccountId.isNotEmpty) {
        batch.update(accountCol.doc(txn.toAccountId), {
          'balance': FieldValue.increment(txn.amount),
          'updatedAt': ts,
        });
      }
    }

    await batch.commit();
  }

  // ── Daily reconciliations ─────────────────────────────────────────────────────

  Stream<List<DailyReconciliation>> watchDailyReconciliations({
    required String uid,
    required ResolvedFinanceContext context,
    String? accountId,
  }) {
    Query<Map<String, dynamic>> query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'daily_reconciliations',
    ).orderBy('date', descending: true);

    if (accountId != null && accountId.isNotEmpty) {
      query = query.where('accountId', isEqualTo: accountId);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => DailyReconciliation.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> saveReconciliation({
    required String uid,
    required ResolvedFinanceContext context,
    required DailyReconciliation reconciliation,
  }) async {
    final col = _scopeCollection(uid: uid, context: context, childCollection: 'daily_reconciliations');
    final existing = await col
        .where('accountId', isEqualTo: reconciliation.accountId)
        .where('date', isEqualTo: reconciliation.date)
        .limit(1)
        .get();

    final data = {
      ...reconciliation.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existing.docs.isEmpty) {
      await col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await existing.docs.first.reference.update(data);
    }

    // Update lastReconciled on the account
    await updateCashAccount(
      uid: uid,
      context: context,
      accountId: reconciliation.accountId,
      data: {'lastReconciled': reconciliation.date},
    );
  }

  // ── Staff (team members) ────────────────────────────────────────────────────

  Stream<List<TeamMember>> watchTeamMembers({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final bizId = context.businessId ?? '';
    if (bizId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('staff')
        .orderBy('invitedAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TeamMember.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Adds a team member and increments the business's denormalized
  /// [staffCount] in the same batch, so admin dashboards can read the count
  /// off the business doc instead of scanning the `staff` sub-collection
  /// (which also holds a UID-keyed pointer doc per accepted member and would
  /// double-count if scanned directly).
  Future<DocumentReference<Map<String, dynamic>>> addTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required Map<String, dynamic> data,
  }) async {
    final bizId = context.businessId ?? '';
    final bizRef = _firestore.collection('businesses').doc(bizId);
    final memberRef = bizRef.collection('staff').doc();
    final batch = _firestore.batch();
    batch.set(memberRef, data);
    batch.update(bizRef, {'staffCount': FieldValue.increment(1)});
    await batch.commit();
    return memberRef;
  }

  Future<void> updateTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required String memberId,
    required Map<String, dynamic> data,
    String? workerUid,
  }) async {
    final bizId = context.businessId ?? '';
    final staffRef = _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('staff');
    await staffRef.doc(memberId).update(data);
    // Mirror permission/status changes to the pointer doc so isStaffWithAny()
    // reflects the new permissions immediately.
    if (workerUid != null && workerUid.isNotEmpty) {
      final ptrUpdate = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (data.containsKey('permissions')) ptrUpdate['permissions'] = data['permissions'];
      if (data.containsKey('status')) ptrUpdate['status'] = data['status'];
      if (ptrUpdate.length > 1) {
        await staffRef.doc(workerUid).update(ptrUpdate);
      }
    }
  }

  Future<void> deleteTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required String memberId,
    String? workerUid,
  }) async {
    final bizId = context.businessId ?? '';
    final bizRef = _firestore.collection('businesses').doc(bizId);
    final staffRef = bizRef.collection('staff');
    final batch = _firestore.batch();
    batch.delete(staffRef.doc(memberId));
    // Also delete the UID-keyed pointer doc if we know the worker's Firebase UID,
    // so isStaffWithAny() stops granting access immediately. This mirrors the
    // same member, not a second one, so staffCount only drops by 1 either way.
    if (workerUid != null && workerUid.isNotEmpty) {
      batch.delete(staffRef.doc(workerUid));
    }
    batch.update(bizRef, {'staffCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Updates the staff doc when a worker's role or permissions change.
  Future<void> writeMemberAccess({
    required String ownerUid,
    required String businessId,
    required String memberUid,
    required List<String> permissions,
    required String status,
    required String role,
  }) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(memberUid)
        .set({
      'permissions': permissions,
      'status': status,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMemberAccess({
    required String ownerUid,
    required String memberUid,
  }) async {
    // memberId (staffId) and workerUid differ — query by workerUid field.
    final ownerBizSnap = await _firestore
        .collection('businesses')
        .where('ownerUid', isEqualTo: ownerUid)
        .get();
    for (final biz in ownerBizSnap.docs) {
      final staffSnap = await biz.reference
          .collection('staff')
          .where('workerUid', isEqualTo: memberUid)
          .get();
      for (final doc in staffSnap.docs) {
        await doc.reference.delete();
      }
    }
  }

  // ── Custom roles (reusable named permission sets) ──────────────────────────
  //
  // Owner-only: the `businesses/{bizId}/{collection}/{docId}` fallback rule in
  // firestore.rules already restricts this sub-collection to the business
  // owner, so no rule changes are needed.

  Stream<List<CustomRole>> watchCustomRoles({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    final bizId = context.businessId ?? '';
    if (bizId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('customRoles')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CustomRole.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> addCustomRole({
    required String uid,
    required ResolvedFinanceContext context,
    required Map<String, dynamic> data,
  }) {
    final bizId = context.businessId ?? '';
    return _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('customRoles')
        .add({
      ...data,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomRole({
    required String uid,
    required ResolvedFinanceContext context,
    required String roleId,
    required Map<String, dynamic> data,
  }) {
    final bizId = context.businessId ?? '';
    return _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('customRoles')
        .doc(roleId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteCustomRole({
    required String uid,
    required ResolvedFinanceContext context,
    required String roleId,
  }) {
    final bizId = context.businessId ?? '';
    return _firestore
        .collection('businesses')
        .doc(bizId)
        .collection('customRoles')
        .doc(roleId)
        .delete();
  }

  /// Rewrites every staff member currently assigned [roleId] with the role's
  /// new [permissions] + [dataScope] and refreshed [roleName]. Also mirrors
  /// the permission list onto each member's UID-keyed pointer doc so
  /// `isStaffWithAny()` in the security rules reflects the change immediately.
  /// Returns the number of members updated.
  Future<int> propagateCustomRole({
    required ResolvedFinanceContext context,
    required String roleId,
    required String roleName,
    required List<String> permissions,
    required String dataScope,
  }) async {
    final bizId = context.businessId ?? '';
    if (bizId.isEmpty) return 0;
    final staffRef =
        _firestore.collection('businesses').doc(bizId).collection('staff');
    final assigned =
        await staffRef.where('customRoleId', isEqualTo: roleId).get();
    if (assigned.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    var count = 0;
    for (final doc in assigned.docs) {
      final data = doc.data();
      // Defensive: never touch a UID-keyed pointer doc (workerUid == its id).
      if ((data['workerUid'] as String?) == doc.id) continue;
      batch.update(doc.reference, {
        'customRoleName': roleName,
        'customPermissions': permissions,
        'permissions': permissions,
        'dataScope': dataScope,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      count++;
      final workerUid = (data['workerUid'] as String?)?.trim() ?? '';
      if (workerUid.isNotEmpty) {
        // merge (not update) so a missing pointer doc can't abort the batch.
        batch.set(
          staffRef.doc(workerUid),
          {
            'permissions': permissions,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
    return count;
  }

  // ── Pending invites (top-level collection for easy phone lookup) ─────────────

  /// Writes a new pending invite document. Returns the auto-generated ID.
  Future<String> writePendingInvite({
    required Map<String, dynamic> inviteData,
  }) async {
    final ref = await _firestore.collection('pendingInvites').add(inviteData);
    return ref.id;
  }

  /// Updates an existing pending invite (e.g., mark as accepted).
  Future<void> updatePendingInvite({
    required String inviteId,
    required Map<String, dynamic> data,
  }) {
    return _firestore
        .collection('pendingInvites')
        .doc(inviteId)
        .update(data);
  }

  Future<String> getBusinessName({
    required String uid,
    required ResolvedFinanceContext context,
  }) async {
    final bizId = context.businessId;
    if (bizId == null || bizId.isEmpty) return '';
    try {
      final doc = await _firestore.collection('businesses').doc(bizId).get();
      return (doc.data()?['businessName'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  CollectionReference<Map<String, dynamic>> _scopeCollection({
    required String uid,
    required ResolvedFinanceContext context,
    required String childCollection,
  }) {
    final businessId = context.businessId ?? '';
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection(childCollection);
  }

  CollectionReference<Map<String, dynamic>> scopeCollection({
    required String uid,
    required ResolvedFinanceContext context,
    required String childCollection,
  }) {
    return _scopeCollection(uid: uid, context: context, childCollection: childCollection);
  }

  String? _businessIdFromContext(String contextValue) {
    final parts = contextValue.split(':');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(':').trim();
  }

}
