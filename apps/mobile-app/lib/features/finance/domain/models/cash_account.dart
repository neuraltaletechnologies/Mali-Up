class CashAccount {
  final String id;
  final String name;
  final String type; // 'Cash', 'Mobile Money', 'Bank'
  final String balance;
  final String lastReconciled;

  CashAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.lastReconciled,
  });

  factory CashAccount.fromFirestore(Map<String, dynamic> data, String id) {
    return CashAccount(
      id: id,
      name: data['name']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Cash',
      balance: data['balance']?.toString() ?? '0',
      lastReconciled: data['lastReconciled']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'lastReconciled': lastReconciled,
    };
  }
}
