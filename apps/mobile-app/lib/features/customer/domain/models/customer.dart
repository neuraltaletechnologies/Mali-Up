import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String balance; // stored as string for Firestore compat; use balanceAmount for math
  final String lastTransactionDate;
  final List<String> tags;
  final bool isOrganisation;
  final String tinNumber;
  final String address;
  final double creditLimit; // 0 = no limit set

  // Ownership & audit
  final String? createdByUserId;
  final String? assignedToUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.creditLimit = 0,
    this.createdByUserId,
    this.assignedToUserId,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  double get balanceAmount => double.tryParse(balance) ?? 0;

  bool get hasOutstandingBalance => balanceAmount > 0;

  bool get isOverCreditLimit => creditLimit > 0 && balanceAmount > creditLimit;

  double get creditUtilization =>
      creditLimit > 0 ? (balanceAmount / creditLimit).clamp(0.0, 1.0) : 0.0;

  double get availableCredit =>
      creditLimit > 0 ? (creditLimit - balanceAmount).clamp(0.0, creditLimit) : 0.0;

  // ── Factory / serialization ───────────────────────────────────────────────

  factory Customer.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

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
      creditLimit: (data['creditLimit'] as num?)?.toDouble() ?? 0,
      createdByUserId: data['createdByUserId'] as String?,
      assignedToUserId: data['assignedToUserId'] as String?,
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
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
      if (creditLimit > 0) 'creditLimit': creditLimit,
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      if (assignedToUserId != null) 'assignedToUserId': assignedToUserId,
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
    double? creditLimit,
    String? createdByUserId,
    String? assignedToUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      creditLimit: creditLimit ?? this.creditLimit,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displaySubtitle {
    if (isOrganisation && tinNumber.isNotEmpty) return 'TIN: $tinNumber';
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;
    return '';
  }
}
