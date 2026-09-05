class SellingUnit {
  final String name;
  final int qty;
  final double price;
  final double costPrice;

  const SellingUnit({
    required this.name,
    required this.qty,
    required this.price,
    this.costPrice = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'qty': qty,
    'price': price,
    'costPrice': costPrice,
  };

  factory SellingUnit.fromJson(Map<String, dynamic> j) => SellingUnit(
    name: (j['name'] as String?) ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 1,
    price: (j['price'] as num?)?.toDouble() ?? 0,
    costPrice: (j['costPrice'] as num?)?.toDouble() ?? 0,
  );
}

/// One raw-material line in a Bill of Materials.
class BomIngredient {
  final String materialName;
  final String materialId;  // ID of the linked InventoryItem; empty if unlinked
  final double quantity;    // Per batch
  final String unit;
  final double costPerUnit;

  const BomIngredient({
    required this.materialName,
    this.materialId = '',
    required this.quantity,
    this.unit = 'pcs',
    required this.costPerUnit,
  });

  double get totalCost => quantity * costPerUnit;

  Map<String, dynamic> toJson() => {
    'name': materialName,
    'matId': materialId,
    'qty': quantity,
    'unit': unit,
    'costPer': costPerUnit,
  };

  factory BomIngredient.fromJson(Map<String, dynamic> j) => BomIngredient(
    materialName: (j['name'] as String?) ?? '',
    materialId: (j['matId'] as String?) ?? '',
    quantity: (j['qty'] as num?)?.toDouble() ?? 0,
    unit: (j['unit'] as String?) ?? 'pcs',
    costPerUnit: (j['costPer'] as num?)?.toDouble() ?? 0,
  );
}

/// A fixed overhead cost per batch (electricity, labour, gas, etc.)
class BomOverheadCost {
  final String description;
  final double amount;

  const BomOverheadCost({required this.description, required this.amount});

  Map<String, dynamic> toJson() => {'desc': description, 'amount': amount};

  factory BomOverheadCost.fromJson(Map<String, dynamic> j) => BomOverheadCost(
    description: (j['desc'] as String?) ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
  );
}

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
  final double unitPrice;     // Selling price
  final double costPrice;     // Buying / cost price (auto-calculated for 'manufactured')
  final String productType;   // 'stock' | 'perishable' | 'service' | 'manufactured'
  // Service billing cadence: 'once' | 'weekly' | 'monthly'. Only meaningful
  // when productType == 'service' — a recurring service (e.g. a monthly
  // water bill) lets the Sales screen pre-fill how many unpaid periods a
  // customer owes; see RecurringBillingCalculator.
  final String billingCycle;
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
  // Multi-unit selling (e.g. single/dozen/carton)
  final List<SellingUnit> sellingUnits;
  // Customer return metadata
  final String returnReason;
  // Bill of Materials (manufactured products only)
  final List<BomIngredient> bomIngredients;
  final List<BomOverheadCost> bomOverheads;
  final double bomBatchYield;  // How many finished units one batch produces
  // Firebase Auth UID of the team member this item (e.g. a service like a
  // haircut or a vehicle) is assigned to. Empty when unassigned. Used to
  // scope Firestore reads for team members with DataScope.own — see
  // firestore.rules. Named to match Customer.assignedToUserId.
  final String assignedToUserId;

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
    this.costPrice = 0,
    this.productType = 'stock',
    this.billingCycle = 'once',
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
    this.sellingUnits = const [],
    this.returnReason = '',
    this.bomIngredients = const [],
    this.bomOverheads = const [],
    this.bomBatchYield = 1,
    this.assignedToUserId = '',
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
      costPrice: (data['costPrice'] as num?)?.toDouble() ??
          (data['buyingPrice'] as num?)?.toDouble() ??
          0.0,
      productType: data['productType'] as String? ?? 'stock',
      billingCycle: data['billingCycle'] as String? ?? 'once',
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
      sellingUnits: _parseSellingUnits(data['sellingUnits']),
      returnReason: data['returnReason'] as String? ?? '',
      bomIngredients: _parseBomIngredients(data['bomIngredients']),
      bomOverheads: _parseBomOverheads(data['bomOverheads']),
      bomBatchYield: (data['bomBatchYield'] as num?)?.toDouble() ?? 1,
      assignedToUserId: data['assignedToUserId'] as String? ?? '',
    );
  }

  static List<SellingUnit> _parseSellingUnits(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SellingUnit.fromJson)
        .toList();
  }

  static List<BomIngredient> _parseBomIngredients(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BomIngredient.fromJson)
        .toList();
  }

  static List<BomOverheadCost> _parseBomOverheads(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BomOverheadCost.fromJson)
        .toList();
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
      'costPrice': costPrice,
      'buyingPrice': costPrice,
      'productType': productType,
      'billingCycle': billingCycle,
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
      'sellingUnits': sellingUnits.map((u) => u.toJson()).toList(),
      'returnReason': returnReason,
      'bomIngredients': bomIngredients.map((i) => i.toJson()).toList(),
      'bomOverheads': bomOverheads.map((o) => o.toJson()).toList(),
      'bomBatchYield': bomBatchYield,
      'assignedToUserId': assignedToUserId,
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
    double? costPrice,
    String? productType,
    String? billingCycle,
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
    List<SellingUnit>? sellingUnits,
    String? returnReason,
    List<BomIngredient>? bomIngredients,
    List<BomOverheadCost>? bomOverheads,
    double? bomBatchYield,
    String? assignedToUserId,
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
      costPrice: costPrice ?? this.costPrice,
      productType: productType ?? this.productType,
      billingCycle: billingCycle ?? this.billingCycle,
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
      sellingUnits: sellingUnits ?? this.sellingUnits,
      returnReason: returnReason ?? this.returnReason,
      bomIngredients: bomIngredients ?? this.bomIngredients,
      bomOverheads: bomOverheads ?? this.bomOverheads,
      bomBatchYield: bomBatchYield ?? this.bomBatchYield,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
    );
  }

  // ── Stock computed properties ────────────────────────────────────────────────

  bool get isLowStock => currentStock > 0 && currentStock <= reorderPoint;
  bool get isOutOfStock => currentStock <= 0;
  bool get isService => productType == 'service';
  bool get isManufactured => productType == 'manufactured';
  bool get isRecurring => billingCycle != 'once';

  double get stockValue    => currentStock * unitPrice;
  double get costValue     => currentStock * costPrice;
  double get reorderValue  => reorderPoint * unitPrice;
  double get profitPerUnit => unitPrice > 0 ? unitPrice - costPrice : 0;
  double get marginPercent =>
      unitPrice > 0 ? ((unitPrice - costPrice) / unitPrice) * 100 : 0;

  // ── BOM computed properties ──────────────────────────────────────────────────

  double get bomTotalMaterialCost =>
      bomIngredients.fold(0, (s, i) => s + i.totalCost);
  double get bomTotalOverheadCost =>
      bomOverheads.fold(0, (s, o) => s + o.amount);
  double get bomTotalBatchCost => bomTotalMaterialCost + bomTotalOverheadCost;
  double get bomCostPerUnit =>
      bomBatchYield > 0 ? bomTotalBatchCost / bomBatchYield : 0;

  // ── Expiry computed properties ───────────────────────────────────────────────

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

  int get daysUntilExpiry {
    if (expiryDate.isEmpty) return -1;
    final date = DateTime.tryParse(expiryDate);
    if (date == null) return -1;
    return date.difference(DateTime.now()).inDays;
  }

  // ── Legacy string helpers (kept for backward compat) ────────────────────────

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
