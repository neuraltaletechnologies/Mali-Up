class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String category;      // Legacy plain-text category; kept for backward compat
  final String categoryId;    // Firestore ID of the linked ProductCategory
  final String categoryName;  // Denormalized name for display
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
  // Expiry / perishable
  final String expiryDate;    // ISO-8601 date string, empty when not applicable
  // Pharmacy-specific
  final String batchNumber;
  // Electronics-specific
  final String warrantyPeriod;
  final String brand;

  InventoryItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.categoryId = '',
    this.categoryName = '',
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
    this.expiryDate = '',
    this.batchNumber = '',
    this.warrantyPeriod = '',
    this.brand = '',
  });

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    final catId   = data['categoryId']   as String? ?? '';
    final catName = data['categoryName'] as String? ?? '';
    final legacyCat = data['category']   as String? ?? 'General';
    return InventoryItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: legacyCat,
      categoryId: catId,
      categoryName: catName.isNotEmpty ? catName : legacyCat,
      sku: data['sku'] ?? '',
      currentStock: (data['currentStock'] as num?)?.toDouble() ??
          (data['stock'] as num?)?.toDouble() ??
          0.0,
      reorderPoint: (data['reorderPoint'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ??
          (data['sellingPrice'] as num?)?.toDouble() ??
          0.0,
      unit: data['unit'] ?? 'pcs',
      supplier: data['supplier'] ?? '',
      lastRestocked: data['lastRestocked'] ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
      updatedAt: data['updatedAt']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      expiryDate: data['expiryDate'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? '',
      warrantyPeriod: data['warrantyPeriod'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': categoryName.isNotEmpty ? categoryName : category,
      'categoryId': categoryId,
      'categoryName': categoryName.isNotEmpty ? categoryName : category,
      'sku': sku,
      'currentStock': currentStock,
      'stock': currentStock,
      'reorderPoint': reorderPoint,
      'unitPrice': unitPrice,
      'sellingPrice': unitPrice,
      'unit': unit,
      'supplier': supplier,
      'lastRestocked': lastRestocked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'expiryDate': expiryDate,
      'batchNumber': batchNumber,
      'warrantyPeriod': warrantyPeriod,
      'brand': brand,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? categoryId,
    String? categoryName,
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
    String? expiryDate,
    String? batchNumber,
    String? warrantyPeriod,
    String? brand,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
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
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      brand: brand ?? this.brand,
    );
  }

  bool get isLowStock => currentStock <= reorderPoint;
  bool get isOutOfStock => currentStock <= 0;
  double get stockValue => currentStock * unitPrice;
  double get reorderValue => reorderPoint * unitPrice;

  bool get isExpired {
    if (expiryDate.isEmpty) return false;
    final date = DateTime.tryParse(expiryDate);
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate.isEmpty) return false;
    final date = DateTime.tryParse(expiryDate);
    if (date == null) return false;
    return !isExpired && date.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  String get stockStatusColor {
    if (isOutOfStock) return 'red';
    if (isLowStock) return 'orange';
    return 'green';
  }
}
