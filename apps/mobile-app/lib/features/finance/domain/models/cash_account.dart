class CashAccount {
  final String id;
  final String name;
  final String type; // 'Cash' | 'Mobile Money' | 'Bank'
  final double balance;
  final String? accountNumber;
  final String currency;
  final String lastReconciled; // ISO date

  const CashAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.accountNumber,
    this.currency = 'TZS',
    this.lastReconciled = '',
  });

  factory CashAccount.fromFirestore(Map<String, dynamic> data, String id) {
    final rawBalance = data['balance'];
    double bal;
    if (rawBalance is num) {
      bal = rawBalance.toDouble();
    } else {
      bal = double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;
    }
    return CashAccount(
      id: id,
      name: data['name']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Cash',
      balance: bal,
      accountNumber: data['accountNumber']?.toString(),
      currency: data['currency']?.toString() ?? 'TZS',
      lastReconciled: data['lastReconciled']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'lastReconciled': lastReconciled,
      if (accountNumber != null && accountNumber!.isNotEmpty)
        'accountNumber': accountNumber,
    };
  }

  CashAccount copyWith({
    String? name,
    String? type,
    double? balance,
    String? accountNumber,
    String? currency,
    String? lastReconciled,
  }) {
    return CashAccount(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      currency: currency ?? this.currency,
      lastReconciled: lastReconciled ?? this.lastReconciled,
    );
  }
}
