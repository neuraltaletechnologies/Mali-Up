class MasterCategory {
  final String id;
  final String businessTypeId;
  final String categoryName;
  final String description;
  final String icon;
  final bool isActive;

  const MasterCategory({
    required this.id,
    required this.businessTypeId,
    required this.categoryName,
    this.description = '',
    this.icon = '',
    this.isActive = true,
  });

  factory MasterCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return MasterCategory(
      id: id,
      businessTypeId: data['businessTypeId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'businessTypeId': businessTypeId,
        'categoryName': categoryName,
        'description': description,
        'icon': icon,
        'isActive': isActive,
      };
}
