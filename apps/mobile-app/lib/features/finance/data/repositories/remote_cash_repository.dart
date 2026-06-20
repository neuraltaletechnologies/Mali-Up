import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/models/daily_reconciliation.dart';

class RemoteCashRepository {
  final FirebaseFirestore _firestore;
  final String uid;
  final String businessId;

  RemoteCashRepository({
    required this.uid,
    required this.businessId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection('businesses').doc(businessId).collection(name);

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _collection('cash_accounts');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _collection('cash_transactions');
  CollectionReference<Map<String, dynamic>> get _reconciliations =>
      _collection('daily_reconciliations');

  // ─── Accounts ──────────────────────────────────────────────────────────────

  /// Full create — includes balance.
  Future<int> createAccountAndGetTimestamp(CashAccount account) async {
    final data = {
      ...account.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _accounts.doc(account.id).set(data, SetOptions(merge: true));
    return _readTimestamp(_accounts, account.id);
  }

  /// Metadata-only update — never writes balance, so server-side
  /// FieldValue.increment deltas from transactions are not clobbered.
  Future<int> updateAccountAndGetTimestamp(CashAccount account) async {
    final data = {
      'name': account.name,
      'type': account.type,
      'currency': account.currency,
      'lastReconciled': account.lastReconciled,
      if (account.accountNumber != null &&
          account.accountNumber!.isNotEmpty)
        'accountNumber': account.accountNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _accounts.doc(account.id).set(data, SetOptions(merge: true));
    return _readTimestamp(_accounts, account.id);
  }

  Future<void> deleteAccount(String id) => _accounts.doc(id).delete();

  Future<Map<String, dynamic>?> fetchAccountRaw(String id) async {
    final snap = await _accounts.doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  Future<List<({String id, Map<String, dynamic> data})>> fetchAllAccounts()
      async {
    final snap = await _accounts.get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchAccountsUpdatedSince(int sinceMs) async {
    final snap = await _accounts
        .where('updatedAt',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs))
        .get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  /// Atomically writes the transaction doc and applies balance increments to
  /// the affected account(s) — mirrors the original online-only behaviour but
  /// is idempotency-guarded by the deterministic doc id: if the doc already
  /// exists (a retry after a partially-failed sync), the increments are
  /// skipped so balances are never double-applied.
  Future<int> saveTransactionAndGetTimestamp(CashTransaction txn) async {
    final existing = await _transactions.doc(txn.id).get();
    if (existing.exists) {
      // Already pushed in a previous attempt — just return its timestamp.
      return _readTimestamp(_transactions, txn.id);
    }

    final batch = _firestore.batch();
    batch.set(_transactions.doc(txn.id), {
      ...txn.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final ts = FieldValue.serverTimestamp();
    if (txn.isDeposit && txn.toAccountId.isNotEmpty) {
      batch.update(_accounts.doc(txn.toAccountId), {
        'balance': FieldValue.increment(txn.amount),
        'updatedAt': ts,
      });
    } else if (txn.isWithdrawal && txn.fromAccountId.isNotEmpty) {
      batch.update(_accounts.doc(txn.fromAccountId), {
        'balance': FieldValue.increment(-txn.amount),
        'updatedAt': ts,
      });
    } else if (txn.isTransfer) {
      if (txn.fromAccountId.isNotEmpty) {
        batch.update(_accounts.doc(txn.fromAccountId), {
          'balance': FieldValue.increment(-txn.amount),
          'updatedAt': ts,
        });
      }
      if (txn.toAccountId.isNotEmpty) {
        batch.update(_accounts.doc(txn.toAccountId), {
          'balance': FieldValue.increment(txn.amount),
          'updatedAt': ts,
        });
      }
    }

    await batch.commit();
    return _readTimestamp(_transactions, txn.id);
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchAllTransactions() async {
    final snap = await _transactions.get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchTransactionsUpdatedSince(int sinceMs) async {
    final snap = await _transactions
        .where('updatedAt',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs))
        .get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  // ─── Reconciliations ───────────────────────────────────────────────────────

  /// Upsert by deterministic id (`<accountId>_<date>`) and update the
  /// account's lastReconciled marker.
  Future<int> saveReconciliationAndGetTimestamp(
      DailyReconciliation rec) async {
    final batch = _firestore.batch();
    batch.set(
      _reconciliations.doc(rec.id),
      {
        ...rec.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _accounts.doc(rec.accountId),
      {
        'lastReconciled': rec.date,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return _readTimestamp(_reconciliations, rec.id);
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchAllReconciliations() async {
    final snap = await _reconciliations.get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  Future<List<({String id, Map<String, dynamic> data})>>
      fetchReconciliationsUpdatedSince(int sinceMs) async {
    final snap = await _reconciliations
        .where('updatedAt',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(sinceMs))
        .get();
    return snap.docs.map((d) => (id: d.id, data: d.data())).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<int> _readTimestamp(
    CollectionReference<Map<String, dynamic>> col,
    String id,
  ) async {
    final snap = await col.doc(id).get();
    final ts = snap.data()?['updatedAt'] ?? snap.data()?['createdAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }
}
