class Invoice {
  final String id;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final String date;
  final String dueDate;
  final String status; // 'paid', 'pending', 'overdue'
  final double subtotal;
  final double tax;
  final double total;
  final List<InvoiceItem> items;
  final String note;
  final String createdAt;
  final String updatedAt;

  Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromFirestore(Map<String, dynamic> data, String id) {
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((item) => InvoiceItem.fromFirestore(item as Map<String, dynamic>))
            .toList() ??
        <InvoiceItem>[];

    return Invoice(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      date: data['date'] ?? '',
      dueDate: data['dueDate'] ?? '',
      status: data['status'] ?? 'pending',
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      note: data['note'] ?? '',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'invoiceNumber': invoiceNumber,
      'date': date,
      'dueDate': dueDate,
      'status': status,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
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
    String? invoiceNumber,
    String? date,
    String? dueDate,
    String? status,
    double? subtotal,
    double? tax,
    double? total,
    List<InvoiceItem>? items,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
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

  InvoiceItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromFirestore(Map<String, dynamic> data) {
    return InvoiceItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? name,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}
