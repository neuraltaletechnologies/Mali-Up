class MasterBusinessType {
  final String id;
  final String nameEn;
  final String nameSw;
  final String icon;
  final bool isActive;

  const MasterBusinessType({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.icon,
    this.isActive = true,
  });

  factory MasterBusinessType.fromFirestore(Map<String, dynamic> data, String id) {
    return MasterBusinessType(
      id: id,
      nameEn: data['nameEn'] as String? ?? '',
      nameSw: data['nameSw'] as String? ?? '',
      icon: data['icon'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameEn': nameEn,
        'nameSw': nameSw,
        'icon': icon,
        'isActive': isActive,
      };
}
