class MasterProduct {
  final String id;
  final String businessTypeId;
  final String categoryId;
  final String categoryName;
  final String productName;
  final String skuTemplate;
  final String barcode;
  final String defaultUnit;
  final double suggestedCostPrice;
  final double suggestedSellingPrice;
  final List<String> searchableKeywords;
  final bool isActive;

  const MasterProduct({
    required this.id,
    required this.businessTypeId,
    required this.categoryId,
    required this.categoryName,
    required this.productName,
    this.skuTemplate = '',
    this.barcode = '',
    this.defaultUnit = 'pcs',
    this.suggestedCostPrice = 0,
    this.suggestedSellingPrice = 0,
    this.searchableKeywords = const [],
    this.isActive = true,
  });

  factory MasterProduct.fromFirestore(Map<String, dynamic> data, String id) {
    final rawKeywords = data['searchableKeywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.map((k) => k.toString()).toList()
        : <String>[];
    return MasterProduct(
      id: id,
      businessTypeId: data['businessTypeId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      skuTemplate: data['skuTemplate'] as String? ?? '',
      barcode: data['barcode'] as String? ?? '',
      defaultUnit: data['defaultUnit'] as String? ?? 'pcs',
      suggestedCostPrice:
          (data['suggestedCostPrice'] as num?)?.toDouble() ?? 0,
      suggestedSellingPrice:
          (data['suggestedSellingPrice'] as num?)?.toDouble() ?? 0,
      searchableKeywords: keywords,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'businessTypeId': businessTypeId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'productName': productName,
        'skuTemplate': skuTemplate,
        'barcode': barcode,
        'defaultUnit': defaultUnit,
        'suggestedCostPrice': suggestedCostPrice,
        'suggestedSellingPrice': suggestedSellingPrice,
        'searchableKeywords': searchableKeywords,
        'isActive': isActive,
      };

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (productName.toLowerCase().contains(q)) return true;
    if (categoryName.toLowerCase().contains(q)) return true;
    if (barcode.contains(q)) return true;
    if (searchableKeywords.any((k) => k.toLowerCase().contains(q))) return true;
    return false;
  }
}
