import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Business Settings Model
class BusinessSettings {
  final String id;
  final double taxRate;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String currency;
  final String? businessType;
  final DateTime? createdAt;

  BusinessSettings({
    required this.id,
    required this.taxRate,
    required this.invoicePrefix,
    required this.nextInvoiceNumber,
    required this.currency,
    this.businessType,
    this.createdAt,
  });

  factory BusinessSettings.fromFirestore(Map<String, dynamic> data, String id) {
    return BusinessSettings(
      id: id,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.18,
      invoicePrefix: data['invoicePrefix'] as String? ?? 'INV-',
      nextInvoiceNumber: data['nextInvoiceNumber'] as int? ?? 1,
      currency: data['currency'] as String? ?? 'TZS',
      businessType: data['businessType'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taxRate': taxRate,
      'invoicePrefix': invoicePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'currency': currency,
      'businessType': businessType,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  BusinessSettings copyWith({
    String? id,
    double? taxRate,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? currency,
    String? businessType,
    DateTime? createdAt,
  }) {
    return BusinessSettings(
      id: id ?? this.id,
      taxRate: taxRate ?? this.taxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      currency: currency ?? this.currency,
      businessType: businessType ?? this.businessType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Invoice Model (Extended version for the new service)
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double balance;
  final String status; // 'paid', 'pending', 'overdue', 'cancelled'
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? paidAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.balance,
    required this.status,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.dueDate,
    this.paidAt,
  });

  factory InvoiceModel.fromFirestore(Map<String, dynamic> data, String id) {
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((item) => InvoiceItemModel.fromFirestore(item as Map<String, dynamic>))
            .toList() ??
        <InvoiceItemModel>[];

    return InvoiceModel(
      id: id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      items: itemsList,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      paymentMethod: data['paymentMethod'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toFirestore()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'amountPaid': amountPaid,
      'balance': balance,
      'status': status,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    double? amountPaid,
    double? balance,
    String? status,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? paidAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

/// Invoice Item Model
class InvoiceItemModel {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItemModel.fromFirestore(Map<String, dynamic> data) {
    return InvoiceItemModel(
      productName: data['productName'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

/// Customer Model (Extended version)
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalBought;
  final double amountOwed;
  final List<String>? tags;
  final String? notes;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalBought = 0.0,
    this.amountOwed = 0.0,
    this.tags,
    this.notes,
    required this.createdAt,
  });

  factory CustomerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CustomerModel(
      id: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      totalBought: (data['totalBought'] as num?)?.toDouble() ?? 0.0,
      amountOwed: (data['amountOwed'] as num?)?.toDouble() ?? 0.0,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalBought': totalBought,
      'amountOwed': amountOwed,
      'tags': tags,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalBought,
    double? amountOwed,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalBought: totalBought ?? this.totalBought,
      amountOwed: amountOwed ?? this.amountOwed,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Expense Model (Extended version)
class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String? receiptUrl;
  final DateTime date;
  final bool isRecurring;
  final String? recurringFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    this.receiptUrl,
    required this.date,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      receiptUrl: data['receiptUrl'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringFrequency: data['recurringFrequency'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'receiptUrl': receiptUrl,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    String? receiptUrl,
    DateTime? date,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Inventory Item Model (Extended version)
class InventoryItemModel {
  final String id;
  final String name;
  final String? sku;
  final String? category;
  final String? unit;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int reorderPoint;
  final String? barcode;
  final DateTime? lastRestockedAt;
  final DateTime createdAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    this.sku,
    this.category,
    this.unit,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.quantity = 0,
    this.reorderPoint = 0,
    this.barcode,
    this.lastRestockedAt,
    required this.createdAt,
  });

  factory InventoryItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItemModel(
      id: id,
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String?,
      category: data['category'] as String?,
      unit: data['unit'] as String?,
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] as int? ?? 0,
      reorderPoint: data['reorderPoint'] as int? ?? 0,
      barcode: data['barcode'] as String?,
      lastRestockedAt: (data['lastRestockedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'unit': unit,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'reorderPoint': reorderPoint,
      'barcode': barcode,
      'lastRestockedAt': lastRestockedAt != null ? Timestamp.fromDate(lastRestockedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    int? quantity,
    int? reorderPoint,
    String? barcode,
    DateTime? lastRestockedAt,
    DateTime? createdAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      barcode: barcode ?? this.barcode,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isLowStock => quantity <= reorderPoint;
  bool get isOutOfStock => quantity <= 0;
}

/// Main Firestore Service class
/// This service is scoped to a specific user's business data
class FirestoreService {
  final String _uid;
  final FirebaseFirestore _firestore;

  /// Creates a new FirestoreService instance for a specific user
  /// [uid] - The user ID to scope all queries to
  FirestoreService({
    required String uid,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the business collection path for the current user
  String get businessPath => 'business/$_uid';

  /// Gets a reference to a specific subcollection within the business
  CollectionReference<Map<String, dynamic>> _businessSubCollection(String subCollection) =>
      _firestore.collection('$businessPath/$subCollection');

  // ============================================
  // PERSONAL FINANCE - FUTURE IMPLEMENTATION (v1.5)
  // ============================================
  // Path: users/{uid}/personal/
  // String get personalPath => 'users/$_uid/personal';
  // 
  // Future collections:
  // - personal/income
  // - personal/expenses
  // - personal/savings
  // - personal/goals
  // - personal/budgets
  // - personal/bills
  // - personal/debts

  // ============================================
  // INVOICE OPERATIONS
  // ============================================

  /// Stream of all invoices for the business, ordered by creation date (newest first)
  Stream<List<InvoiceModel>> invoiceStream() {
    return _businessSubCollection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream of invoices filtered by status
  Stream<List<InvoiceModel>> invoicesByStatusStream(String status) {
    return _businessSubCollection('invoices')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all invoices as a future
  Future<List<InvoiceModel>> getInvoices() async {
    final snapshot = await _businessSubCollection('invoices')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single invoice by ID
  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    final doc = await _businessSubCollection('invoices').doc(invoiceId).get();
    if (doc.exists) {
      return InvoiceModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create a new invoice
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final docRef = await _businessSubCollection('invoices').add(invoice.toFirestore());
    return invoice.copyWith(id: docRef.id);
  }

  /// Update an existing invoice
  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _businessSubCollection('invoices')
        .doc(invoice.id)
        .update(invoice.toFirestore());
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final updateData = <String, dynamic>{
      'status': status,
    };
    
    if (status == 'paid') {
      updateData['paidAt'] = FieldValue.serverTimestamp();
      updateData['amountPaid'] = updateData['balance'];
      updateData['balance'] = 0;
    }
    
    await _businessSubCollection('invoices').doc(invoiceId).update(updateData);
  }

  /// Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    await _businessSubCollection('invoices').doc(invoiceId).delete();
  }

  // ============================================
  // CUSTOMER OPERATIONS
  // ============================================

  /// Stream of all customers, ordered by name
  Stream<List<CustomerModel>> customerStream() {
    return _businessSubCollection('customers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all customers as a future
  Future<List<CustomerModel>> getCustomers() async {
    final snapshot = await _businessSubCollection('customers')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single customer by ID
  Future<CustomerModel?> getCustomer(String customerId) async {
    final doc = await _businessSubCollection('customers').doc(customerId).get();
    if (doc.exists) {
      return CustomerModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create a new customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final docRef = await _businessSubCollection('customers').add(customer.toFirestore());
    return customer.copyWith(id: docRef.id);
  }

  /// Update an existing customer
  Future<void> updateCustomer(CustomerModel customer) async {
    await _businessSubCollection('customers')
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  /// Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    await _businessSubCollection('customers').doc(customerId).delete();
  }

  // ============================================
  // EXPENSE OPERATIONS
  // ============================================

  /// Stream of all expenses, ordered by date (newest first)
  Stream<List<ExpenseModel>> expenseStream() {
    return _businessSubCollection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream of expenses for a specific month
  Stream<List<ExpenseModel>> expensesByMonthStream(int year, int month) {
    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    return _businessSubCollection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all expenses as a future
  Future<List<ExpenseModel>> getExpenses() async {
    final snapshot = await _businessSubCollection('expenses')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single expense by ID
  Future<ExpenseModel?> getExpense(String expenseId) async {
    final doc = await _businessSubCollection('expenses').doc(expenseId).get();
    if (doc.exists) {
      return ExpenseModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create a new expense
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final docRef = await _businessSubCollection('expenses').add(expense.toFirestore());
    return expense.copyWith(id: docRef.id);
  }

  /// Update an existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _businessSubCollection('expenses')
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    await _businessSubCollection('expenses').doc(expenseId).delete();
  }

  // ============================================
  // INVENTORY OPERATIONS
  // ============================================

  /// Stream of all inventory items, ordered by name
  Stream<List<InventoryItemModel>> inventoryStream() {
    return _businessSubCollection('inventory')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all inventory items as a future
  Future<List<InventoryItemModel>> getInventoryItems() async {
    final snapshot = await _businessSubCollection('inventory')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => InventoryItemModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single inventory item by ID
  Future<InventoryItemModel?> getInventoryItem(String itemId) async {
    final doc = await _businessSubCollection('inventory').doc(itemId).get();
    if (doc.exists) {
      return InventoryItemModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create a new inventory item
  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item) async {
    final docRef = await _businessSubCollection('inventory').add(item.toFirestore());
    return item.copyWith(id: docRef.id);
  }

  /// Update an existing inventory item
  Future<void> updateInventoryItem(InventoryItemModel item) async {
    await _businessSubCollection('inventory')
        .doc(item.id)
        .update(item.toFirestore());
  }

  /// Update inventory quantity
  Future<void> updateInventoryQuantity(String itemId, int quantity) async {
    await _businessSubCollection('inventory').doc(itemId).update({
      'quantity': quantity,
      'lastRestockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    await _businessSubCollection('inventory').doc(itemId).delete();
  }

  // ============================================
  // SETTINGS OPERATIONS
  // ============================================

  /// Get business settings
  Future<BusinessSettings?> getSettings() async {
    final doc = await _businessSubCollection('settings').doc('main').get();
    if (doc.exists) {
      return BusinessSettings.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream of business settings
  Stream<BusinessSettings?> settingsStream() {
    return _businessSubCollection('settings')
        .doc('main')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BusinessSettings.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  /// Create or update business settings
  Future<void> saveSettings(BusinessSettings settings) async {
    await _businessSubCollection('settings')
        .doc('main')
        .set(settings.toFirestore(), SetOptions(merge: true));
  }

  /// Increment the next invoice number
  Future<int> incrementInvoiceNumber() async {
    final docRef = _businessSubCollection('settings').doc('main');
    
    // Use a transaction to safely increment
    return await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        final currentNumber = (doc.data()?['nextInvoiceNumber'] as int?) ?? 1;
        final newNumber = currentNumber + 1;
        transaction.update(docRef, {'nextInvoiceNumber': newNumber});
        return newNumber;
      } else {
        // Create the settings document if it doesn't exist
        const newNumber = 2;
        transaction.set(docRef, {
          'taxRate': 0.18,
          'invoicePrefix': 'INV-',
          'nextInvoiceNumber': newNumber,
          'currency': 'TZS',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return newNumber;
      }
    });
  }

  // ============================================
  // DASHBOARD AGGREGATION METHODS
  // ============================================

  /// Get today's total sales
  Future<double> getTodaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _businessSubCollection('invoices')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['paid', 'pending'])
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Get current month's total sales
  Future<double> getMonthSales() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot = await _businessSubCollection('invoices')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .where('status', whereIn: ['paid', 'pending'])
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Get current month's total expenses
  Future<double> getMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot = await _businessSubCollection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Get total outstanding debts (unpaid invoices)
  Future<double> getTotalOutstandingDebts() async {
    final snapshot = await _businessSubCollection('invoices')
        .where('status', whereIn: ['pending', 'overdue'])
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['balance'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Get list of low stock items
  Future<List<InventoryItemModel>> getLowStockItems() async {
    final snapshot = await _businessSubCollection('inventory')
        .where('quantity', isLessThanOrEqualTo: 0)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => InventoryItemModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get complete dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final todaySales = await getTodaySales();
    final monthSales = await getMonthSales();
    final monthExpenses = await getMonthExpenses();
    final totalOutstanding = await getTotalOutstandingDebts();
    final lowStockItems = await getLowStockItems();

    return {
      'todaySales': todaySales,
      'monthSales': monthSales,
      'monthExpenses': monthExpenses,
      'totalOutstanding': totalOutstanding,
      'lowStockCount': lowStockItems.length,
      'lowStockItems': lowStockItems,
      'monthlyProfit': monthSales - monthExpenses,
    };
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get the current user ID
  String get uid => _uid;

  /// Check if the service is properly initialized
  bool get isInitialized => _uid.isNotEmpty;

  /// Dispose of any resources if needed
  void dispose() {
    // No resources to dispose in this implementation
  }
}