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
}
