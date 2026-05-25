import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/customer/domain/models/customer.dart';
import '../../../features/debt/domain/models/debt.dart';
import '../../../features/finance/domain/models/cash_account.dart';
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

      final defaultAccountType = (data?['defaultAccountType'] as String?)
          ?.toLowerCase();
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
    } catch (_) {
      // Keep a safe fallback when user profile is unavailable.
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

  Future<void> addTeamMember({
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
