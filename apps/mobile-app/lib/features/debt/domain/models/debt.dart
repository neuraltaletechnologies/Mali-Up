import 'package:cloud_firestore/cloud_firestore.dart';

String _dateFromFirestore(dynamic value) {
  if (value == null) return '';
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
  return value.toString();
}

class DebtPayment {
  final String id;
  final double amount;
  final String date;
  final String method; // 'cash' | 'mpesa' | 'bank' | 'card' | custom account name
  final String note;
  final String recordedBy;

  /// The CashAccount the payment moved through, if any. Empty on legacy
  /// records recorded before repayments were wired into Cash Flow.
  final String accountId;

  const DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.note = '',
    this.recordedBy = '',
    this.accountId = '',
  });

  factory DebtPayment.fromFirestore(Map<String, dynamic> data, String id) =>
      DebtPayment(
        id: id,
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        date: data['date']?.toString() ?? '',
        method: data['method']?.toString() ?? 'cash',
        note: data['note']?.toString() ?? '',
        recordedBy: data['recordedBy']?.toString() ?? '',
        accountId: data['accountId']?.toString() ?? '',
      );

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'date': date,
        'method': method,
        if (note.isNotEmpty) 'note': note,
        if (recordedBy.isNotEmpty) 'recordedBy': recordedBy,
        if (accountId.isNotEmpty) 'accountId': accountId,
      };
}

class Debt {
  final String id;
  final String partyName;
  final String partyPhone;
  final String partyId;
  final String type; // 'receivable' | 'payable'
  final double originalAmount;
  final double paidAmount;
  final String dueDate;
  final String status; // 'current' | 'overdue' | 'paid' | 'written_off'
  final String invoiceRef;
  final String note;
  final String createdBy;
  final String createdAt;
  final bool isWrittenOff;
  final String writeOffReason;
  final String writtenOffBy;
  final String writtenOffAt;

  const Debt({
    required this.id,
    required this.partyName,
    this.partyPhone = '',
    this.partyId = '',
    required this.type,
    required this.originalAmount,
    this.paidAmount = 0,
    required this.dueDate,
    this.status = 'current',
    this.invoiceRef = '',
    this.note = '',
    this.createdBy = '',
    this.createdAt = '',
    this.isWrittenOff = false,
    this.writeOffReason = '',
    this.writtenOffBy = '',
    this.writtenOffAt = '',
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  double get remainingAmount =>
      (originalAmount - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => paidAmount >= originalAmount;
  double get paidPercent =>
      originalAmount <= 0 ? 0 : (paidAmount / originalAmount).clamp(0.0, 1.0);

  int get daysOverdue {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;
    return DateTime.now().difference(due).inDays;
  }

  String get agingBucket {
    if (isWrittenOff || isFullyPaid) return 'paid';
    final days = daysOverdue;
    if (days <= 0) return 'current';
    if (days <= 30) return '0-30';
    if (days <= 60) return '31-60';
    if (days <= 90) return '61-90';
    return '90+';
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory Debt.fromFirestore(Map<String, dynamic> data, String id) {
    // Backward compat: legacy docs stored amount as a String field.
    final origAmt = (data['originalAmount'] as num?)?.toDouble() ??
        double.tryParse(data['amount']?.toString() ?? '') ??
        0.0;
    final rawType =
        (data['type']?.toString() ?? 'receivable').toLowerCase().trim();
    final normalizedType = rawType == 'payable' ? 'payable' : 'receivable';
    return Debt(
      id: id,
      partyName: data['partyName']?.toString() ??
          data['customerName']?.toString() ?? '',
      partyPhone: data['partyPhone']?.toString() ??
          data['customerPhone']?.toString() ?? '',
      partyId: data['partyId']?.toString() ??
          data['customerId']?.toString() ?? '',
      type: normalizedType,
      originalAmount: origAmt,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ??
          (data['amountPaid'] as num?)?.toDouble() ?? 0,
      dueDate: _dateFromFirestore(data['dueDate']),
      status: data['status']?.toString() ?? 'current',
      invoiceRef: data['invoiceRef']?.toString() ??
          data['invoiceNumber']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: _dateFromFirestore(data['createdAt']),
      isWrittenOff: data['isWrittenOff'] as bool? ?? false,
      writeOffReason: data['writeOffReason']?.toString() ?? '',
      writtenOffBy: data['writtenOffBy']?.toString() ?? '',
      writtenOffAt: data['writtenOffAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'partyName': partyName,
        if (partyPhone.isNotEmpty) 'partyPhone': partyPhone,
        if (partyId.isNotEmpty) 'partyId': partyId,
        'type': type,
        'originalAmount': originalAmount,
        'paidAmount': paidAmount,
        'dueDate': dueDate,
        'status': status,
        if (invoiceRef.isNotEmpty) 'invoiceRef': invoiceRef,
        if (note.isNotEmpty) 'note': note,
        if (createdBy.isNotEmpty) 'createdBy': createdBy,
        if (createdAt.isNotEmpty) 'createdAt': createdAt,
        if (isWrittenOff) ...{
          'isWrittenOff': true,
          'writeOffReason': writeOffReason,
          'writtenOffBy': writtenOffBy,
          'writtenOffAt': writtenOffAt,
        },
      };

  Debt copyWith({
    String? partyName,
    String? partyPhone,
    String? partyId,
    String? type,
    double? originalAmount,
    double? paidAmount,
    String? dueDate,
    String? status,
    String? invoiceRef,
    String? note,
    String? createdBy,
    String? createdAt,
    bool? isWrittenOff,
    String? writeOffReason,
    String? writtenOffBy,
    String? writtenOffAt,
  }) =>
      Debt(
        id: id,
        partyName: partyName ?? this.partyName,
        partyPhone: partyPhone ?? this.partyPhone,
        partyId: partyId ?? this.partyId,
        type: type ?? this.type,
        originalAmount: originalAmount ?? this.originalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        invoiceRef: invoiceRef ?? this.invoiceRef,
        note: note ?? this.note,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        isWrittenOff: isWrittenOff ?? this.isWrittenOff,
        writeOffReason: writeOffReason ?? this.writeOffReason,
        writtenOffBy: writtenOffBy ?? this.writtenOffBy,
        writtenOffAt: writtenOffAt ?? this.writtenOffAt,
      );
}
