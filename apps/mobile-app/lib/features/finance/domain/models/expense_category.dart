class ExpenseCategory {
  final String key;
  final String nameEn;
  final String nameSw;
  final String iconKey;
  final int colorValue;
  final bool isBuiltIn;

  const ExpenseCategory({
    required this.key,
    required this.nameEn,
    required this.nameSw,
    required this.iconKey,
    required this.colorValue,
    this.isBuiltIn = false,
  });

  String labelFor(String language) =>
      language == 'sw' && nameSw.isNotEmpty ? nameSw : nameEn;

  factory ExpenseCategory.fromFirestore(String id, Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim() ?? '';
    return ExpenseCategory(
      key: id,
      nameEn: (data['nameEn'] as String?)?.trim().isNotEmpty == true
          ? (data['nameEn'] as String).trim()
          : name,
      nameSw: (data['nameSw'] as String?)?.trim().isNotEmpty == true
          ? (data['nameSw'] as String).trim()
          : name,
      iconKey: (data['iconKey'] as String?) ?? 'category',
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF1A6E8A,
    );
  }

  static const defaults = <ExpenseCategory>[
    ExpenseCategory(
      key: 'rent',
      nameEn: 'Rent',
      nameSw: 'Kodi',
      iconKey: 'home',
      colorValue: 0xFF0D1B3E,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'utilities',
      nameEn: 'Utilities',
      nameSw: 'Huduma',
      iconKey: 'bolt',
      colorValue: 0xFF1A6E8A,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'salaries',
      nameEn: 'Salaries',
      nameSw: 'Mishahara',
      iconKey: 'people',
      colorValue: 0xFF16A34A,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'transport',
      nameEn: 'Transport',
      nameSw: 'Usafiri',
      iconKey: 'transport',
      colorValue: 0xFFF59E0B,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'marketing',
      nameEn: 'Marketing',
      nameSw: 'Masoko',
      iconKey: 'campaign',
      colorValue: 0xFF7C3AED,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'supplies',
      nameEn: 'Supplies',
      nameSw: 'Vifaa',
      iconKey: 'inventory',
      colorValue: 0xFFB45309,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      key: 'other',
      nameEn: 'Other',
      nameSw: 'Nyingine',
      iconKey: 'more',
      colorValue: 0xFF64748B,
      isBuiltIn: true,
    ),
  ];

  static ExpenseCategory fallback(String key) {
    for (final category in defaults) {
      if (category.key == key.toLowerCase()) return category;
    }
    final words = key
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return ExpenseCategory(
      key: key,
      nameEn: words.isEmpty ? 'Other' : words,
      nameSw: words.isEmpty ? 'Nyingine' : words,
      iconKey: 'category',
      colorValue: 0xFF64748B,
    );
  }
}
