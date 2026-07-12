import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String invoiceNumber;
  final String date;
  final String dueDate;
  final String status; // 'paid', 'partial', 'unpaid', 'sent', 'draft', 'overdue', 'cancelled'
  final String type; // 'invoice' | 'quotation'
  final double subtotal;
  final double discountAmount;
  final double tax; // VAT amount
  final double total;
  final double amountPaid;
  final String paymentMethod;

  /// The exact CashAccount money moved through, when payment was via a
  /// custom account (built-in channels are re-derived from [paymentMethod]).
  final String paymentAccountId;
  final List<InvoiceItem> items;
  final String note;
  final String createdAt;
  final String updatedAt;

  Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.status,
    this.type = 'invoice',
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.tax,
    required this.total,
    this.amountPaid = 0.0,
    this.paymentMethod = '',
    this.paymentAccountId = '',
    required this.items,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Outstanding balance still owed on this invoice.
  double get outstanding {
    final due = total - amountPaid;
    return due < 0 ? 0 : due;
  }

  // Firestore documents are written by several flows (quick sale, full
  // invoice editor, sync push) with slightly different key sets and with
  // dates as either Timestamp or ISO string — normalize everything here.

  static String _readDate(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value;
    return '';
  }

  static double _readNum(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Invoice.fromFirestore(Map<String, dynamic> data, String id) {
    // Quick sales write 'items'; the full invoice editor writes 'lineItems'.
    final rawItems = (data['items'] is List && (data['items'] as List).isNotEmpty)
        ? data['items'] as List
        : (data['lineItems'] as List? ?? const []);
    final itemsList = rawItems
        .whereType<Map>()
        .map((item) =>
            InvoiceItem.fromFirestore(Map<String, dynamic>.from(item)))
        .toList();

    final total = data['total'] != null
        ? _readNum(data['total'])
        : (data['totalAmount'] != null
            ? _readNum(data['totalAmount'])
            : _readNum(data['amount']));

    return Invoice(
      id: id,
      customerId: (data['customerId'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      customerPhone: (data['customerPhone'] ?? '').toString(),
      invoiceNumber: (data['invoiceNumber'] ?? '').toString(),
      date: _readDate(data['date'] ?? data['invoiceDate'] ?? data['createdAt']),
      dueDate: _readDate(data['dueDate']),
      status: (data['status'] ?? 'pending').toString(),
      type: (data['type'] ?? 'invoice').toString(),
      subtotal: _readNum(data['subtotal']),
      discountAmount: _readNum(data['discountAmount']),
      tax: data['tax'] != null ? _readNum(data['tax']) : _readNum(data['vatAmount']),
      total: total,
      amountPaid: _readNum(data['amountPaid']),
      paymentMethod: (data['paymentMethod'] ?? '').toString(),
      paymentAccountId: (data['paymentAccountId'] ?? '').toString(),
      items: itemsList,
      note: (data['note'] ?? data['notes'] ?? '').toString(),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'invoiceNumber': invoiceNumber,
      'date': date,
      'dueDate': dueDate,
      'status': status,
      'type': type,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'tax': tax,
      'vatAmount': tax,
      'total': total,
      'totalAmount': total,
      'amount': total,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      if (paymentAccountId.isNotEmpty) 'paymentAccountId': paymentAccountId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Invoice copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? invoiceNumber,
    String? date,
    String? dueDate,
    String? status,
    String? type,
    double? subtotal,
    double? discountAmount,
    double? tax,
    double? total,
    double? amountPaid,
    String? paymentMethod,
    String? paymentAccountId,
    List<InvoiceItem>? items,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      type: type ?? this.type,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      items: items ?? this.items,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvoiceItem {
  final String id;
  final String name;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  /// Catalog price at the time of sale. When the cashier lowers the price the
  /// receipt shows this value and folds the difference into the discount
  /// line; markups above it stay business-side. 0 = not captured.
  final double basePrice;

  InvoiceItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.basePrice = 0,
  });

  factory InvoiceItem.fromFirestore(Map<String, dynamic> data) {
    // Quick-sale items: {name, qty, unitPrice, total, inventoryItemId}
    // Full-invoice lines: {productName, qty, unitPrice, lineTotal, productId}
    final qty = Invoice._readNum(data['quantity'] ?? data['qty'] ?? 1);
    final unitPrice = Invoice._readNum(data['unitPrice']);
    final total = data['total'] != null
        ? Invoice._readNum(data['total'])
        : (data['lineTotal'] != null
            ? Invoice._readNum(data['lineTotal'])
            : qty * unitPrice);
    return InvoiceItem(
      id: (data['id'] ?? data['productId'] ?? data['inventoryItemId'] ?? '')
          .toString(),
      name: (data['name'] ?? data['productName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      quantity: qty,
      unitPrice: unitPrice,
      total: total,
      basePrice: Invoice._readNum(data['basePrice']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      // Stock flows (returns, draft confirm, quotation convert) look the
      // product up by this key — without it lines lose their product link
      // after a round-trip through the local database.
      'productId': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'qty': quantity,
      'unitPrice': unitPrice,
      'total': total,
      if (basePrice > 0) 'basePrice': basePrice,
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? name,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
    double? basePrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      basePrice: basePrice ?? this.basePrice,
    );
  }
}
