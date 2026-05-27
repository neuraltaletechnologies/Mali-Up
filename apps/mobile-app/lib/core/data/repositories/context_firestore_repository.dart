import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/customer/domain/models/customer.dart';
import '../../../features/debt/domain/models/debt.dart';
import '../../../features/finance/domain/models/cash_account.dart';
import '../../../features/finance/domain/models/cash_transaction.dart';
import '../../../features/finance/domain/models/daily_reconciliation.dart';
import '../../../features/finance/domain/models/expense.dart';
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
    final defaultContext = (data?['defaultContext'] as String?)?.toLowerCase();
    final selectedBusinessId =
        (data?['selectedBusinessId'] as String?)?.trim();
    final businesses = _businessListFromProfile(data);

    if (defaultContext != null && defaultContext.startsWith('business')) {
      final businessId = _businessIdFromContext(defaultContext) ??
          selectedBusinessId ??
          businesses.firstOrNull?.id;
      if (businessId != null && businessId.isNotEmpty) {
        return ResolvedFinanceContext.business(businessId);
      }
    }

    final defaultAccountType =
        (data?['defaultAccountType'] as String?)?.toLowerCase();
    if (defaultAccountType == 'business') {
      final businessId = selectedBusinessId ?? businesses.firstOrNull?.id;
      if (businessId != null && businessId.isNotEmpty) {
        return ResolvedFinanceContext.business(businessId);
      }
    }

    if (businesses.isNotEmpty) {
      return ResolvedFinanceContext.business(
        selectedBusinessId ?? businesses.first.id,
      );
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
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'customers',
    ).add(customer.toFirestore());
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

  // ── Team members ────────────────────────────────────────────────────────────

  Stream<List<TeamMember>> watchTeamMembers({
    required String uid,
    required ResolvedFinanceContext context,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'team_members',
    ).orderBy('invitedAt').snapshots().map((snap) => snap.docs
        .map((doc) => TeamMember.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Returns the new document reference so callers can use the generated ID.
  Future<DocumentReference<Map<String, dynamic>>> addTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required Map<String, dynamic> data,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'team_members',
    ).add(data);
  }

  Future<void> updateTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required String memberId,
    required Map<String, dynamic> data,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'team_members',
    ).doc(memberId).update(data);
  }

  Future<void> deleteTeamMember({
    required String uid,
    required ResolvedFinanceContext context,
    required String memberId,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'team_members',
    ).doc(memberId).delete();
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

  /// Fetches the display name for the current business context.
  Future<String> getBusinessName({
    required String uid,
    required ResolvedFinanceContext context,
  }) async {
    final bizId = context.businessId;
    if (bizId == null || bizId.isEmpty) return '';
    try {
      final doc = await _firestore
          .collection('tenants')
          .doc(uid)
          .collection('businesses')
          .doc(bizId)
          .get();
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
    final businessId = context.businessId;
    if (businessId == null || businessId.isEmpty) {
      return _firestore
          .collection('tenants')
          .doc(uid)
          .collection(childCollection);
    }

    return _firestore
        .collection('tenants')
        .doc(uid)
        .collection('businesses')
        .doc(businessId)
        .collection(childCollection);
  }

  CollectionReference<Map<String, dynamic>> scopeCollection({
    required String uid,
    required ResolvedFinanceContext context,
    required String childCollection,
  }) {
    return _scopeCollection(
      uid: uid,
      context: context,
      childCollection: childCollection,
    );
  }

  String? _businessIdFromContext(String contextValue) {
    final parts = contextValue.split(':');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(':').trim();
  }

  List<_BusinessProfileRecord> _businessListFromProfile(
    Map<String, dynamic>? profile,
  ) {
    final businessesRaw = profile?['businesses'];
    if (businessesRaw is! List) return const [];

    return businessesRaw
        .whereType<Map>()
        .map(
          (entry) => _BusinessProfileRecord(
            id: (entry['id'] as String?)?.trim() ?? '',
            name: (entry['name'] as String?)?.trim() ?? '',
          ),
        )
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }
}

class _BusinessProfileRecord {
  final String id;
  final String name;

  const _BusinessProfileRecord({required this.id, required this.name});
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
