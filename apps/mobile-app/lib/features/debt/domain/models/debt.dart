import 'dart:math' as math;

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

  /// Interest rate charged per [interestPeriod], as a percentage (e.g. `5`
  /// means 5% per period). Zero (the default) means the debt carries no
  /// interest and behaves exactly as before — every computed getter below
  /// falls back to the plain principal in that case.
  final double interestRatePercent;

  /// 'daily' | 'weekly' | 'monthly' — how often [interestRatePercent] applies.
  final String interestPeriod;

  /// 'simple' — interest = principal × rate × periods elapsed.
  /// 'compound' — interest compounds on the growing balance each period.
  final String interestType;

  /// The date interest starts accruing from (ISO `yyyy-MM-dd`). Falls back
  /// to [createdAt] when empty, so existing debts need no backfill.
  final String loanDate;

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
    this.interestRatePercent = 0,
    this.interestPeriod = 'monthly',
    this.interestType = 'simple',
    this.loanDate = '',
  });

  // ── Interest / accrual ───────────────────────────────────────────────────

  bool get hasInterest => interestRatePercent > 0;

  /// Whole periods elapsed between [loanDate] (or [createdAt] if unset) and
  /// now. Accrual freezes once the debt is settled — it never grows past
  /// what mattered while the debt was actually open.
  int get interestPeriodsElapsed {
    if (!hasInterest || isWrittenOff || status == 'paid') return 0;
    final start = DateTime.tryParse(loanDate.isNotEmpty ? loanDate : createdAt);
    if (start == null) return 0;
    final now = DateTime.now();
    if (!now.isAfter(start)) return 0;
    switch (interestPeriod) {
      case 'daily':
        return now.difference(start).inDays;
      case 'weekly':
        return now.difference(start).inDays ~/ 7;
      case 'monthly':
      default:
        var months = (now.year - start.year) * 12 + (now.month - start.month);
        if (now.day < start.day) months -= 1;
        return months < 0 ? 0 : months;
    }
  }

  /// Interest accrued so far, in the same currency unit as [originalAmount].
  double get accruedInterest {
    if (!hasInterest) return 0;
    final periods = interestPeriodsElapsed;
    if (periods <= 0) return 0;
    final rate = interestRatePercent / 100;
    if (interestType == 'compound') {
      return originalAmount * (math.pow(1 + rate, periods) - 1);
    }
    return originalAmount * rate * periods;
  }

  /// Principal + interest accrued to date — what is actually owed right now.
  double get totalOwedWithInterest => originalAmount + accruedInterest;

  // ── Computed ──────────────────────────────────────────────────────────────

  double get remainingAmount =>
      (totalOwedWithInterest - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => paidAmount >= totalOwedWithInterest;
  double get paidPercent => totalOwedWithInterest <= 0
      ? 0
      : (paidAmount / totalOwedWithInterest).clamp(0.0, 1.0);

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
      interestRatePercent:
          (data['interestRatePercent'] as num?)?.toDouble() ?? 0,
      interestPeriod: data['interestPeriod']?.toString() ?? 'monthly',
      interestType: data['interestType']?.toString() ?? 'simple',
      loanDate: data['loanDate']?.toString() ?? '',
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
        if (interestRatePercent > 0) ...{
          'interestRatePercent': interestRatePercent,
          'interestPeriod': interestPeriod,
          'interestType': interestType,
          if (loanDate.isNotEmpty) 'loanDate': loanDate,
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
    double? interestRatePercent,
    String? interestPeriod,
    String? interestType,
    String? loanDate,
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
        interestRatePercent: interestRatePercent ?? this.interestRatePercent,
        interestPeriod: interestPeriod ?? this.interestPeriod,
        interestType: interestType ?? this.interestType,
        loanDate: loanDate ?? this.loanDate,
      );
}
