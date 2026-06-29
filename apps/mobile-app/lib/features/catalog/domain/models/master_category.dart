class MasterCategory {
  final String id;
  final String businessType; // normalised key ("retail", "pharmacy" …)
  final String categoryName;
  final String categoryNameSw;
  final String categorySlug;
  final String icon;
  final int displayOrder;

  const MasterCategory({
    required this.id,
    required this.businessType,
    required this.categoryName,
    this.categoryNameSw = '',
    this.categorySlug = '',
    this.icon = '',
    this.displayOrder = 0,
  });

  factory MasterCategory.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String normalizedBizType,
  ) {
    return MasterCategory(
      id: id,
      businessType: normalizedBizType,
      categoryName: data['categoryName'] as String? ?? '',
      categoryNameSw: data['categoryNameSw'] as String? ?? '',
      categorySlug: data['categorySlug'] as String? ?? id,
      icon: data['icon'] as String? ?? '',
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayName => categoryName;
}
