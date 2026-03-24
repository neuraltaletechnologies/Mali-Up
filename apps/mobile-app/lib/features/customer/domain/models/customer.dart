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
}
