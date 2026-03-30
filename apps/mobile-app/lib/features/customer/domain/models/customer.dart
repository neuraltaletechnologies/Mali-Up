class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String balance;
  final String lastTransactionDate;
  final List<String> tags;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.balance,
    required this.lastTransactionDate,
    this.tags = const [],
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
    };
  }
}
