class DailyReconciliation {
  final String id;
  final String accountId;
  final String date; // ISO date string YYYY-MM-DD
  final double openingBalance;
  final double closingBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final String notes;
  final String reconciledBy;
  final bool isReconciled;

  const DailyReconciliation({
    required this.id,
    required this.accountId,
    required this.date,
    required this.openingBalance,
    required this.closingBalance,
    this.totalDeposits = 0.0,
    this.totalWithdrawals = 0.0,
    this.notes = '',
    this.reconciledBy = '',
    this.isReconciled = false,
  });

  double get netFlow => totalDeposits - totalWithdrawals;

  factory DailyReconciliation.fromFirestore(Map<String, dynamic> data, String id) {
    return DailyReconciliation(
      id: id,
      accountId: data['accountId']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      openingBalance: (data['openingBalance'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (data['closingBalance'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (data['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (data['totalWithdrawals'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes']?.toString() ?? '',
      reconciledBy: data['reconciledBy']?.toString() ?? '',
      isReconciled: data['isReconciled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'date': date,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'notes': notes,
      'reconciledBy': reconciledBy,
      'isReconciled': isReconciled,
    };
  }

  DailyReconciliation copyWith({
    String? accountId,
    String? date,
    double? openingBalance,
    double? closingBalance,
    double? totalDeposits,
    double? totalWithdrawals,
    String? notes,
    String? reconciledBy,
    bool? isReconciled,
  }) {
    return DailyReconciliation(
      id: id,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      notes: notes ?? this.notes,
      reconciledBy: reconciledBy ?? this.reconciledBy,
      isReconciled: isReconciled ?? this.isReconciled,
    );
  }
}
