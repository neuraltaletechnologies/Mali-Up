class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String balance;
  final String lastTransactionDate;
  final List<String> tags;
  final bool isOrganisation;
  final String tinNumber;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.balance = '0',
    this.lastTransactionDate = '',
    this.tags = const [],
    this.isOrganisation = false,
    this.tinNumber = '',
    this.address = '',
  });

  factory Customer.fromFirestore(Map<String, dynamic> data, String id) {
    return Customer(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      balance: data['balance']?.toString() ?? '0',
      lastTransactionDate: data['lastTransactionDate'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isOrganisation: data['isOrganisation'] as bool? ?? false,
      tinNumber: data['tinNumber'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
      'lastTransactionDate': lastTransactionDate,
      'tags': tags,
      'isOrganisation': isOrganisation,
      if (tinNumber.isNotEmpty) 'tinNumber': tinNumber,
      if (address.isNotEmpty) 'address': address,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? balance,
    String? lastTransactionDate,
    List<String>? tags,
    bool? isOrganisation,
    String? tinNumber,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      tags: tags ?? this.tags,
      isOrganisation: isOrganisation ?? this.isOrganisation,
      tinNumber: tinNumber ?? this.tinNumber,
      address: address ?? this.address,
    );
  }

  String get displaySubtitle {
    if (isOrganisation && tinNumber.isNotEmpty) return 'TIN: $tinNumber';
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;
    return '';
  }
}
