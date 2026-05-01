import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/context_firestore_repository.dart';
import '../../features/customer/domain/models/customer.dart';
import '../../features/finance/domain/models/expense.dart';
import '../../features/invoice/domain/models/invoice.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import 'error_handling_service.dart';

class FirestoreService {
  final ContextFirestoreRepository _contextRepository;
  final FirebaseAuth _auth;

  FirestoreService({
    ContextFirestoreRepository? contextRepository,
    FirebaseAuth? auth,
  })  : _contextRepository = contextRepository ?? ContextFirestoreRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  // Get current user UID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user context
  Future<ResolvedFinanceContext?> _getCurrentContext() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await _contextRepository.resolveContextForUser(userId);
  }

  // Generic operations
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? customId,
  }) async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        final collectionRef = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: collection,
        );

        final docRef = customId != null
            ? collectionRef.doc(customId)
            : collectionRef.doc();

        final dataWithTimestamp = {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await docRef.set(dataWithTimestamp);
        return docRef.id;
      },
      operationContext: 'addDocument_$collection',
      onError: (error) => error,
    ).then((result) => result as String);
  }

  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        final collectionRef = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: collection,
        );

        return await collectionRef.doc(docId).get();
      },
      operationContext: 'getDocument_$collection',
      onError: (error) => throw error,
    );
  }

  Future<List<DocumentSnapshot>> listDocuments({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        Query collectionRef = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: collection,
        );

        if (queryBuilder != null) {
          collectionRef = queryBuilder(collectionRef);
        }

        final snapshot = await collectionRef.get();
        return snapshot.docs;
      },
      operationContext: 'listDocuments_$collection',
      onError: (error) => throw error,
    ).then((result) => result as List<DocumentSnapshot>);
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        final collectionRef = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: collection,
        );

        final dataWithTimestamp = {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await collectionRef.doc(docId).update(dataWithTimestamp);
      },
      operationContext: 'updateDocument_$collection',
      onError: (error) => throw error,
    );
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        final collectionRef = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: collection,
        );

        await collectionRef.doc(docId).delete();
      },
      operationContext: 'deleteDocument_$collection',
      onError: (error) => throw error,
    );
  }

  Stream<List<DocumentSnapshot>> watchDocuments({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) async* {
    final context = await _getCurrentContext();
    if (context == null) {
      yield [];
      return;
    }

    Query collectionRef = _contextRepository.scopeCollection(
      uid: currentUserId!,
      context: context,
      childCollection: collection,
    );

    if (queryBuilder != null) {
      collectionRef = queryBuilder(collectionRef);
    }

    yield* collectionRef.snapshots().map((snapshot) => snapshot.docs);
  }

  // Customer operations
  Future<String> addCustomer(Customer customer) async {
    return await addDocument(
      collection: 'customers',
      data: customer.toFirestore(),
      customId: customer.id.isEmpty ? null : customer.id,
    );
  }

  Future<Customer?> getCustomer(String customerId) async {
    final doc = await getDocument(collection: 'customers', docId: customerId);
    if (doc.exists) {
      return Customer.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Customer>> getCustomers() async {
    final docs = await listDocuments(
      collection: 'customers',
      queryBuilder: (query) => query.orderBy('name'),
    );
    return docs.map((doc) => Customer.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateCustomer(Customer customer) async {
    await updateDocument(
      collection: 'customers',
      docId: customer.id,
      data: customer.toFirestore(),
    );
  }

  Future<void> deleteCustomer(String customerId) async {
    await deleteDocument(collection: 'customers', docId: customerId);
  }

  Stream<List<Customer>> watchCustomers() {
    return watchDocuments(
      collection: 'customers',
      queryBuilder: (query) => query.orderBy('name'),
    ).map((docs) => docs.map((doc) => Customer.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Invoice operations
  Future<String> addInvoice(Invoice invoice) async {
    return await addDocument(
      collection: 'invoices',
      data: invoice.toFirestore(),
      customId: invoice.id.isEmpty ? null : invoice.id,
    );
  }

  Future<Invoice?> getInvoice(String invoiceId) async {
    final doc = await getDocument(collection: 'invoices', docId: invoiceId);
    if (doc.exists) {
      return Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Invoice>> getInvoices() async {
    final docs = await listDocuments(
      collection: 'invoices',
      queryBuilder: (query) => query.orderBy('date', descending: true),
    );
    return docs.map((doc) => Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await updateDocument(
      collection: 'invoices',
      docId: invoice.id,
      data: invoice.toFirestore(),
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await deleteDocument(collection: 'invoices', docId: invoiceId);
  }

  Stream<List<Invoice>> watchInvoices() {
    return watchDocuments(
      collection: 'invoices',
      queryBuilder: (query) => query.orderBy('date', descending: true),
    ).map((docs) => docs.map((doc) => Invoice.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Expense operations
  Future<String> addExpense(Expense expense) async {
    return await addDocument(
      collection: 'expenses',
      data: expense.toFirestore(),
      customId: expense.id.isEmpty ? null : expense.id,
    );
  }

  Future<Expense?> getExpense(String expenseId) async {
    final doc = await getDocument(collection: 'expenses', docId: expenseId);
    if (doc.exists) {
      return Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Expense>> getExpenses() async {
    final docs = await listDocuments(
      collection: 'expenses',
      queryBuilder: (query) => query.orderBy('date', descending: true),
    );
    return docs.map((doc) => Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    await updateDocument(
      collection: 'expenses',
      docId: expense.id,
      data: expense.toFirestore(),
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    await deleteDocument(collection: 'expenses', docId: expenseId);
  }

  Stream<List<Expense>> watchExpenses() {
    return watchDocuments(
      collection: 'expenses',
      queryBuilder: (query) => query.orderBy('date', descending: true),
    ).map((docs) => docs.map((doc) => Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Inventory operations
  Future<String> addInventoryItem(InventoryItem item) async {
    return await addDocument(
      collection: 'inventory',
      data: item.toFirestore(),
      customId: item.id.isEmpty ? null : item.id,
    );
  }

  Future<InventoryItem?> getInventoryItem(String itemId) async {
    final doc = await getDocument(collection: 'inventory', docId: itemId);
    if (doc.exists) {
      return InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final docs = await listDocuments(
      collection: 'inventory',
      queryBuilder: (query) => query.orderBy('name'),
    );
    return docs.map((doc) => InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await updateDocument(
      collection: 'inventory',
      docId: item.id,
      data: item.toFirestore(),
    );
  }

  Future<void> deleteInventoryItem(String itemId) async {
    await deleteDocument(collection: 'inventory', docId: itemId);
  }

  Stream<List<InventoryItem>> watchInventoryItems() {
    return watchDocuments(
      collection: 'inventory',
      queryBuilder: (query) => query.orderBy('name'),
    ).map((docs) => docs.map((doc) => InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Dashboard aggregation queries
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await ErrorHandlingService.withErrorHandling(
      operation: () async {
        final context = await _getCurrentContext();
        if (context == null) throw Exception('User not authenticated');

        final today = DateTime.now();
        final startOfMonth = DateTime(today.year, today.month, 1);
        final endOfMonth = DateTime(today.year, today.month + 1, 0, 23, 59, 59);

        // Get today's sales (from invoices)
        final invoicesQuery = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: 'invoices',
        );

        final todayInvoices = await invoicesQuery
            .where('date', isGreaterThanOrEqualTo: _formatDate(today))
            .where('date', isLessThanOrEqualTo: _formatDate(today))
            .where('status', whereIn: ['paid', 'pending'])
            .get();

        final monthInvoices = await invoicesQuery
            .where('date', isGreaterThanOrEqualTo: _formatDate(startOfMonth))
            .where('date', isLessThanOrEqualTo: _formatDate(endOfMonth))
            .where('status', whereIn: ['paid', 'pending'])
            .get();

        // Get expenses
        final expensesQuery = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: 'expenses',
        );

        final monthExpenses = await expensesQuery
            .where('date', isGreaterThanOrEqualTo: _formatDate(startOfMonth))
            .where('date', isLessThanOrEqualTo: _formatDate(endOfMonth))
            .get();

        // Get debts
        final debtsQuery = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: 'debts',
        );

        final outstandingDebts = await debtsQuery
            .where('status', whereIn: ['pending', 'overdue'])
            .get();

        // Get low stock items
        final inventoryQuery = _contextRepository.scopeCollection(
          uid: currentUserId!,
          context: context,
          childCollection: 'inventory',
        );

        final lowStockItems = await inventoryQuery
            .where('currentStock', isLessThanOrEqualTo: 0)
            .get();

        double todaySales = 0;
        double monthSales = 0;
        double totalExpenses = 0;
        double totalDebts = 0;

        for (final doc in todayInvoices.docs) {
          final data = doc.data() as Map<String, dynamic>;
          todaySales += (data['total'] as num?)?.toDouble() ?? 0;
        }

        for (final doc in monthInvoices.docs) {
          final data = doc.data() as Map<String, dynamic>;
          monthSales += (data['total'] as num?)?.toDouble() ?? 0;
        }

        for (final doc in monthExpenses.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalExpenses += (data['amount'] as num?)?.toDouble() ?? 0;
        }

        for (final doc in outstandingDebts.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalDebts += (data['amount'] as num?)?.toDouble() ?? 0;
        }

        return {
          'todaySales': todaySales,
          'monthSales': monthSales,
          'totalExpenses': totalExpenses,
          'totalDebts': totalDebts,
          'lowStockCount': lowStockItems.docs.length,
          'lowStockItems': lowStockItems.docs.map((doc) => 
              InventoryItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
          ).toList(),
        };
      },
      operationContext: 'getDashboardStats',
      onError: (error) => throw error,
    ).then((result) => result as Map<String, dynamic>);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
