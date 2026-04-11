import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/customer/domain/models/customer.dart';
import '../../../features/debt/domain/models/debt.dart';
import '../../../features/finance/domain/models/cash_account.dart';
import '../../../features/finance/domain/models/expense.dart';

enum FinanceContextType { business, personal }

class ContextFirestoreRepository {
  final FirebaseFirestore _firestore;

  ContextFirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FinanceContextType> resolveContextForUser(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
      final data = snapshot.data();

      final defaultContext = (data?['defaultContext'] as String?)?.toLowerCase();
      if (defaultContext != null && defaultContext.startsWith('business')) {
        return FinanceContextType.business;
      }
      if (defaultContext != null && defaultContext.startsWith('personal')) {
        return FinanceContextType.personal;
      }

      final defaultAccountType =
          (data?['defaultAccountType'] as String?)?.toLowerCase();
      if (defaultAccountType == 'business') {
        return FinanceContextType.business;
      }
      if (defaultAccountType == 'personal') {
        return FinanceContextType.personal;
      }
    } catch (_) {
      // Keep a safe fallback when user profile is unavailable.
    }

    return FinanceContextType.personal;
  }

  Stream<List<Customer>> watchCustomers({
    required String uid,
    required FinanceContextType context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'customers',
    ).orderBy('name');

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc.data(), doc.id))
          .toList();

      if (items.isEmpty && context == FinanceContextType.personal) {
        return _personalCustomerSeed();
      }

      return items;
    });
  }

  Stream<List<Debt>> watchDebts({
    required String uid,
    required FinanceContextType context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'debts',
    ).orderBy('dueDate');

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Debt.fromFirestore(doc.data(), doc.id))
          .toList();

      if (items.isEmpty && context == FinanceContextType.personal) {
        return _personalDebtSeed();
      }

      return items;
    });
  }

  Stream<List<Expense>> watchExpenses({
    required String uid,
    required FinanceContextType context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'expenses',
    ).orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
          .toList();

      if (items.isEmpty && context == FinanceContextType.personal) {
        return _personalExpenseSeed();
      }

      return items;
    });
  }

  Stream<List<CashAccount>> watchCashAccounts({
    required String uid,
    required FinanceContextType context,
  }) {
    final query = _scopeCollection(
      uid: uid,
      context: context,
      childCollection: 'cash_accounts',
    ).orderBy('name');

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CashAccount.fromFirestore(doc.data(), doc.id))
          .toList();

      if (items.isEmpty && context == FinanceContextType.personal) {
        return _personalCashAccountSeed();
      }

      return items;
    });
  }

  List<Customer> _personalCustomerSeed() {
    return [
      Customer(
        id: 'seed-personal-customer-1',
        name: 'Family Emergency',
        phone: '+255700000001',
        email: 'family@example.com',
        balance: '125,000',
        lastTransactionDate: 'Today',
        tags: const ['Personal'],
      ),
    ];
  }

  List<Debt> _personalDebtSeed() {
    return [
      Debt(
        id: 'seed-personal-debt-1',
        partyName: 'School Fees',
        type: 'Payable',
        amount: '450,000',
        dueDate: 'Fri, Apr 18',
        status: 'Pending',
      ),
      Debt(
        id: 'seed-personal-debt-2',
        partyName: 'Savings Club',
        type: 'Receivable',
        amount: '80,000',
        dueDate: 'Sun, Apr 20',
        status: 'Pending',
      ),
    ];
  }

  List<Expense> _personalExpenseSeed() {
    return [
      Expense(
        id: 'seed-personal-expense-1',
        category: 'Household',
        amount: 'TSh 65,000',
        date: 'Today',
        note: 'Groceries and home essentials',
        recipient: 'Local Market',
      ),
      Expense(
        id: 'seed-personal-expense-2',
        category: 'Transport',
        amount: 'TSh 12,000',
        date: 'Yesterday',
        note: 'Commute and errands',
        recipient: 'Bodaboda',
      ),
    ];
  }

  List<CashAccount> _personalCashAccountSeed() {
    return [
      CashAccount(
        id: 'seed-personal-cash-1',
        name: 'Personal Cash',
        type: 'Cash',
        balance: 'TSh 142,500',
        lastReconciled: 'Today, 8:00 AM',
      ),
      CashAccount(
        id: 'seed-personal-cash-2',
        name: 'M-Pesa Pocket',
        type: 'Mobile Money',
        balance: 'TSh 850,000',
        lastReconciled: '1 hour ago',
      ),
    ];
  }

  CollectionReference<Map<String, dynamic>> _scopeCollection({
    required String uid,
    required FinanceContextType context,
    required String childCollection,
  }) {
    if (context == FinanceContextType.business) {
      return _firestore
          .collection('tenants')
          .doc(uid)
          .collection(childCollection);
    }

    return _firestore
        .collection('personal_accounts')
        .doc(uid)
        .collection(childCollection);
  }
}
