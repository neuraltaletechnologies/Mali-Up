class ProductCategory {
  final String id;
  final String name;
  final String createdAt;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ProductCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': createdAt,
    };
  }

  ProductCategory copyWith({String? id, String? name, String? createdAt}) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
