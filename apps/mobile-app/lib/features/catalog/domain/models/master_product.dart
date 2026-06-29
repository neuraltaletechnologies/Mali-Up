class MasterProduct {
  final String id;
  final String businessType; // normalised key
  final String categorySlug;
  final String productName;
  final String productNameSw;
  final String productSlug;
  final String genericName;
  final List<String> brandNames;
  final String unit;
  final List<String> unitAlternatives;
  final List<String> commonBarcodes;
  final List<String> searchKeywords;
  final List<String> tags;
  final bool prescriptionRequired;
  final bool coldStorage;

  const MasterProduct({
    required this.id,
    required this.businessType,
    this.categorySlug = '',
    required this.productName,
    this.productNameSw = '',
    this.productSlug = '',
    this.genericName = '',
    this.brandNames = const [],
    this.unit = 'Piece',
    this.unitAlternatives = const [],
    this.commonBarcodes = const [],
    this.searchKeywords = const [],
    this.tags = const [],
    this.prescriptionRequired = false,
    this.coldStorage = false,
  });

  factory MasterProduct.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String normalizedBizType,
  ) {
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];

    return MasterProduct(
      id: id,
      businessType: normalizedBizType,
      // Support both new schema and legacy field names
      categorySlug: data['categorySlug'] as String? ??
          data['categoryId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      productNameSw: data['productNameSw'] as String? ?? '',
      productSlug: data['productSlug'] as String? ?? id,
      genericName: data['genericName'] as String? ?? '',
      brandNames: strList(data['brandNames']),
      unit: data['unit'] as String? ??
          data['defaultUnit'] as String? ?? 'Piece',
      unitAlternatives: strList(data['unitAlternatives']),
      commonBarcodes: strList(data['commonBarcodes']),
      searchKeywords: strList(data['searchKeywords'] ?? data['searchableKeywords']),
      tags: strList(data['tags']),
      prescriptionRequired: data['prescriptionRequired'] as bool? ?? false,
      coldStorage: data['coldStorage'] as bool? ?? false,
    );
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (productName.toLowerCase().contains(q)) return true;
    if (productNameSw.toLowerCase().contains(q)) return true;
    if (genericName.toLowerCase().contains(q)) return true;
    if (brandNames.any((b) => b.toLowerCase().contains(q))) return true;
    if (commonBarcodes.any((b) => b.contains(q))) return true;
    if (searchKeywords.any((k) => k.toLowerCase().contains(q))) return true;
    return false;
  }

  bool get isFmcg => tags.contains('fmcg');
  bool get isCommon => tags.contains('common');
}
