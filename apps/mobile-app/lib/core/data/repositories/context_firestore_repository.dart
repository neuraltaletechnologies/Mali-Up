import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/customer/domain/models/customer.dart';
import '../../../features/debt/domain/models/debt.dart';
import '../../../features/finance/domain/models/cash_account.dart';
import '../../../features/finance/domain/models/expense.dart';

enum FinanceContextType { business, personal }

class ResolvedFinanceContext {
  final FinanceContextType type;
  final String? businessId;

  const ResolvedFinanceContext._({
    required this.type,
    required this.businessId,
  });

  const ResolvedFinanceContext.personal()
    : this._(type: FinanceContextType.personal, businessId: null);

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
      final data = snapshot.data();

      final defaultContext = (data?['defaultContext'] as String?)
          ?.toLowerCase();
      final selectedBusinessId = (data?['selectedBusinessId'] as String?)
          ?.trim();
      final businesses = _businessListFromProfile(data);

      if (defaultContext != null && defaultContext.startsWith('business')) {
        final businessId =
            _businessIdFromContext(defaultContext) ??
            selectedBusinessId ??
            businesses.firstOrNull?.id;
        if (businessId != null && businessId.isNotEmpty) {
          return ResolvedFinanceContext.business(businessId);
        }
      }
      if (defaultContext != null && defaultContext.startsWith('personal')) {
        return const ResolvedFinanceContext.personal();
      }

      final defaultAccountType = (data?['defaultAccountType'] as String?)
          ?.toLowerCase();
      if (defaultAccountType == 'business') {
        final businessId = selectedBusinessId ?? businesses.firstOrNull?.id;
        if (businessId != null && businessId.isNotEmpty) {
          return ResolvedFinanceContext.business(businessId);
        }
      }
      if (defaultAccountType == 'personal') {
        return const ResolvedFinanceContext.personal();
      }

      if (businesses.isNotEmpty) {
        return ResolvedFinanceContext.business(
          selectedBusinessId ?? businesses.first.id,
        );
      }
    } catch (_) {
      // Keep a safe fallback when user profile is unavailable.
    }

    return const ResolvedFinanceContext.personal();
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

  Future<void> addCustomer({
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

  CollectionReference<Map<String, dynamic>> _scopeCollection({
    required String uid,
    required ResolvedFinanceContext context,
    required String childCollection,
  }) {
    if (context.isBusiness) {
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

    return _firestore
        .collection('personal_accounts')
        .doc(uid)
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
