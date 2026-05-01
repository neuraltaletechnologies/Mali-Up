class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String sku;
  final double currentStock;
  final double reorderPoint;
  final double unitPrice;
  final String unit; // 'pcs', 'kg', 'liters', etc.
  final String supplier;
  final String lastRestocked;
  final String createdAt;
  final String updatedAt;
  final bool isActive;

  InventoryItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.sku = '',
    required this.currentStock,
    required this.reorderPoint,
    required this.unitPrice,
    required this.unit,
    this.supplier = '',
    this.lastRestocked = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      sku: data['sku'] ?? '',
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0.0,
      reorderPoint: (data['reorderPoint'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'pcs',
      supplier: data['supplier'] ?? '',
      lastRestocked: data['lastRestocked'] ?? '',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'sku': sku,
      'currentStock': currentStock,
      'reorderPoint': reorderPoint,
      'unitPrice': unitPrice,
      'unit': unit,
      'supplier': supplier,
      'lastRestocked': lastRestocked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? sku,
    double? currentStock,
    double? reorderPoint,
    double? unitPrice,
    String? unit,
    String? supplier,
    String? lastRestocked,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      currentStock: currentStock ?? this.currentStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      supplier: supplier ?? this.supplier,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isLowStock => currentStock <= reorderPoint;
  bool get isOutOfStock => currentStock <= 0;
  double get stockValue => currentStock * unitPrice;
  double get reorderValue => reorderPoint * unitPrice;

  // Get status for UI display
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Get status color (for UI)
  String get stockStatusColor {
    if (isOutOfStock) return 'red';
    if (isLowStock) return 'orange';
    return 'green';
  }
}
