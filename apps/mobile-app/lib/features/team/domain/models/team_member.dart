import 'package:cloud_firestore/cloud_firestore.dart';

// ── Role ──────────────────────────────────────────────────────────────────────

enum TeamRole {
  owner,
  manager,
  accountant,
  cashier,
  stockClerk,
  custom;

  String get label => switch (this) {
        TeamRole.owner => 'Owner',
        TeamRole.manager => 'Manager',
        TeamRole.accountant => 'Accountant',
        TeamRole.cashier => 'Cashier',
        TeamRole.stockClerk => 'Stock Clerk',
        TeamRole.custom => 'Custom',
      };

  String get labelSw => switch (this) {
        TeamRole.owner => 'Mmiliki',
        TeamRole.manager => 'Meneja',
        TeamRole.accountant => 'Mhasibu',
        TeamRole.cashier => 'Kasna',
        TeamRole.stockClerk => 'Msimamizi wa Bidhaa',
        TeamRole.custom => 'Maalum',
      };

  String get description => switch (this) {
        TeamRole.owner =>
          'Full access to all modules, settings and billing',
        TeamRole.manager =>
          'All operations and reports; no billing or role management',
        TeamRole.accountant =>
          'Full finance access; read-only sales and stock',
        TeamRole.cashier =>
          'POS and sales entry only; no financial reports',
        TeamRole.stockClerk =>
          'Inventory and purchasing only; no financial data',
        TeamRole.custom => 'Define granular permissions for this member',
      };

  String get descriptionSw => switch (this) {
        TeamRole.owner => 'Ufikiaji kamili wa moduli zote, mipangilio na bili',
        TeamRole.manager =>
          'Shughuli zote na ripoti; hakuna mabadiliko ya bili',
        TeamRole.accountant =>
          'Ufikiaji kamili wa fedha; mauzo na bidhaa — kusoma tu',
        TeamRole.cashier =>
          'POS na kuingiza mauzo tu; hakuna ripoti za fedha',
        TeamRole.stockClerk =>
          'Bidhaa na manunuzi tu; hakuna data za fedha',
        TeamRole.custom => 'Ruhusa maalum kwa mwanachama huyu',
      };

  static TeamRole fromString(String s) => switch (s) {
        'owner' => TeamRole.owner,
        'manager' => TeamRole.manager,
        'accountant' => TeamRole.accountant,
        'cashier' => TeamRole.cashier,
        'stockClerk' => TeamRole.stockClerk,
        _ => TeamRole.custom,
      };
}

// ── Data scope ────────────────────────────────────────────────────────────────
//
// Controls whether a member sees every record in the business or only the
// ones tied to them. Applies to entities with an owner-like field:
// sales/expenses use `createdBy`, inventory items use `assignedToUserId`.
// Only meaningful for members who lack the matching "view all" permission
// (viewSales / viewFinancialReports / viewInventory) — a member who has both
// simply sees everything, `own` is a fallback, not a restriction on top.

enum DataScope {
  /// Sees every record in the business (subject to their permissions).
  all,

  /// Sees only records they created (sales/expenses) or that are assigned
  /// to them (inventory) — e.g. a stylist who should see their own sales,
  /// or a driver who should see only their own vehicle's, but not other
  /// members'.
  own;

  static DataScope fromString(String s) => switch (s) {
        'own' => DataScope.own,
        _ => DataScope.all,
      };
}

// ── Permission ────────────────────────────────────────────────────────────────

enum AppPermission {
  // Sales
  viewSales,
  createSale,
  editSale,
  deleteSale,
  applyDiscount,
  issueRefund,
  // Inventory
  viewInventory,
  addStock,
  editStock,
  adjustStock,
  deleteStock,
  // Finance
  viewFinancialReports,
  manageExpenses,
  viewCashFlow,
  // Customers
  viewCustomers,
  manageCustomers,
  grantCredit,
  // Debt
  viewDebt,
  manageDebt,
  writeOffDebt,
  // Admin
  manageTeam,
  manageBilling,
  exportData,
}

extension AppPermissionX on AppPermission {
  String get label => switch (this) {
        AppPermission.viewSales => 'View Sales',
        AppPermission.createSale => 'Create Sale',
        AppPermission.editSale => 'Edit Sale',
        AppPermission.deleteSale => 'Delete Sale',
        AppPermission.applyDiscount => 'Apply Discount',
        AppPermission.issueRefund => 'Issue Refund',
        AppPermission.viewInventory => 'View Inventory',
        AppPermission.addStock => 'Add Stock',
        AppPermission.editStock => 'Edit Stock',
        AppPermission.adjustStock => 'Adjust Stock',
        AppPermission.deleteStock => 'Delete Stock',
        AppPermission.viewFinancialReports => 'View Financial Reports',
        AppPermission.manageExpenses => 'Manage Expenses',
        AppPermission.viewCashFlow => 'View Cash Flow',
        AppPermission.viewCustomers => 'View Customers',
        AppPermission.manageCustomers => 'Manage Customers',
        AppPermission.grantCredit => 'Grant Credit',
        AppPermission.viewDebt => 'View Debt Tracker',
        AppPermission.manageDebt => 'Manage Debts',
        AppPermission.writeOffDebt => 'Write-off Debt',
        AppPermission.manageTeam => 'Manage Team',
        AppPermission.manageBilling => 'Manage Billing',
        AppPermission.exportData => 'Export Data',
      };

  String get labelSw => switch (this) {
        AppPermission.viewSales => 'Angalia Mauzo',
        AppPermission.createSale => 'Ingiza Mauzo',
        AppPermission.editSale => 'Hariri Mauzo',
        AppPermission.deleteSale => 'Futa Mauzo',
        AppPermission.applyDiscount => 'Toa Punguzo',
        AppPermission.issueRefund => 'Rudisha Malipo',
        AppPermission.viewInventory => 'Angalia Bidhaa',
        AppPermission.addStock => 'Ongeza Bidhaa',
        AppPermission.editStock => 'Hariri Bidhaa',
        AppPermission.adjustStock => 'Rekebisha Bidhaa',
        AppPermission.deleteStock => 'Futa Bidhaa',
        AppPermission.viewFinancialReports => 'Angalia Ripoti za Fedha',
        AppPermission.manageExpenses => 'Simamia Matumizi',
        AppPermission.viewCashFlow => 'Angalia Mtiririko wa Fedha',
        AppPermission.viewCustomers => 'Angalia Wateja',
        AppPermission.manageCustomers => 'Simamia Wateja',
        AppPermission.grantCredit => 'Toa Mkopo',
        AppPermission.viewDebt => 'Angalia Madeni',
        AppPermission.manageDebt => 'Simamia Madeni',
        AppPermission.writeOffDebt => 'Futa Deni',
        AppPermission.manageTeam => 'Simamia Timu',
        AppPermission.manageBilling => 'Simamia Bili',
        AppPermission.exportData => 'Hamisha Data',
      };

  String get group => switch (this) {
        AppPermission.viewSales ||
        AppPermission.createSale ||
        AppPermission.editSale ||
        AppPermission.deleteSale ||
        AppPermission.applyDiscount ||
        AppPermission.issueRefund =>
          'Sales',
        AppPermission.viewInventory ||
        AppPermission.addStock ||
        AppPermission.editStock ||
        AppPermission.adjustStock ||
        AppPermission.deleteStock =>
          'Inventory',
        AppPermission.viewFinancialReports ||
        AppPermission.manageExpenses ||
        AppPermission.viewCashFlow =>
          'Finance',
        AppPermission.viewCustomers ||
        AppPermission.manageCustomers ||
        AppPermission.grantCredit =>
          'Customers',
        AppPermission.viewDebt ||
        AppPermission.manageDebt ||
        AppPermission.writeOffDebt =>
          'Debt',
        _ => 'Admin',
      };

  static AppPermission? fromString(String s) {
    try {
      return AppPermission.values.firstWhere((p) => p.name == s);
    } catch (_) {
      return null;
    }
  }
}

// ── Default permission sets per role ─────────────────────────────────────────

final _roleDefaults = <TeamRole, Set<AppPermission>>{
  TeamRole.owner: {...AppPermission.values},
  TeamRole.manager: {
    AppPermission.viewSales,
    AppPermission.createSale,
    AppPermission.editSale,
    AppPermission.deleteSale,
    AppPermission.applyDiscount,
    AppPermission.issueRefund,
    AppPermission.viewInventory,
    AppPermission.addStock,
    AppPermission.editStock,
    AppPermission.adjustStock,
    AppPermission.deleteStock,
    AppPermission.viewFinancialReports,
    AppPermission.manageExpenses,
    AppPermission.viewCashFlow,
    AppPermission.viewCustomers,
    AppPermission.manageCustomers,
    AppPermission.grantCredit,
    AppPermission.viewDebt,
    AppPermission.manageDebt,
    AppPermission.writeOffDebt,
    AppPermission.exportData,
  },
  TeamRole.accountant: {
    AppPermission.viewSales,
    AppPermission.viewInventory,
    AppPermission.viewFinancialReports,
    AppPermission.manageExpenses,
    AppPermission.viewCashFlow,
    AppPermission.viewCustomers,
    AppPermission.viewDebt,
    AppPermission.manageDebt,
    AppPermission.writeOffDebt,
    AppPermission.exportData,
  },
  TeamRole.cashier: {
    AppPermission.viewSales,
    AppPermission.createSale,
    AppPermission.applyDiscount,
    AppPermission.viewInventory,
    AppPermission.viewCustomers,
  },
  TeamRole.stockClerk: {
    AppPermission.viewInventory,
    AppPermission.addStock,
    AppPermission.editStock,
    AppPermission.adjustStock,
  },
  TeamRole.custom: {},
};

Set<AppPermission> defaultPermissionsFor(TeamRole role) =>
    Set.unmodifiable(_roleDefaults[role] ?? {});

// ── TeamMember model ──────────────────────────────────────────────────────────

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final TeamRole role;
  final Set<AppPermission> customPermissions;

  /// When [role] is [TeamRole.custom] and the member was assigned a saved,
  /// reusable custom role (see [CustomRole]), this is that role's document ID.
  /// Empty / null for one-off custom permission sets and built-in roles.
  final String? customRoleId;

  /// Denormalized display name of the assigned [customRoleId] (e.g. "Driver"),
  /// stored on the member so the team list can label them without a lookup —
  /// including offline. Null for built-in roles and one-off custom members.
  final String? customRoleName;
  final String status; // 'active' | 'pending' | 'suspended'
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final String invitedBy;
  final String? notes;
  /// Firebase Auth UID of this member — set when they accept the invite.
  /// Used as the doc ID in `memberAccess/{userId}` for Firestore rules.
  final String? userId;
  /// 'all' (default) or 'own' — see [DataScope].
  final DataScope dataScope;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.customPermissions,
    this.customRoleId,
    this.customRoleName,
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    required this.invitedBy,
    this.notes,
    this.userId,
    this.dataScope = DataScope.all,
  });

  Set<AppPermission> get effectivePermissions =>
      role == TeamRole.custom ? customPermissions : defaultPermissionsFor(role);

  /// Human-readable role label for lists and headers. Falls back to the
  /// built-in role label; for a saved custom role it returns its name.
  String roleLabel({bool sw = false}) {
    if (role == TeamRole.custom &&
        customRoleName != null &&
        customRoleName!.trim().isNotEmpty) {
      return customRoleName!.trim();
    }
    return sw ? role.labelSw : role.label;
  }

  bool can(AppPermission p) => effectivePermissions.contains(p);

  /// Flat list of effective permission names — stored in Firestore so that
  /// security rules can call `.hasAny([permission])` without a client round-trip.
  List<String> get effectivePermissionsList =>
      effectivePermissions.map((p) => p.name).toList();

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory TeamMember.fromFirestore(Map<String, dynamic> data, String id) {
    final permList = (data['customPermissions'] as List?)
            ?.whereType<String>()
            .map(AppPermissionX.fromString)
            .whereType<AppPermission>()
            .toSet() ??
        {};
    return TeamMember(
      id: id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: TeamRole.fromString((data['role'] as String?) ?? 'custom'),
      customPermissions: permList,
      customRoleId: (data['customRoleId'] as String?)?.trim().isNotEmpty == true
          ? (data['customRoleId'] as String).trim()
          : null,
      customRoleName:
          (data['customRoleName'] as String?)?.trim().isNotEmpty == true
              ? (data['customRoleName'] as String).trim()
              : null,
      status: (data['status'] as String?) ?? 'active',
      invitedAt: data['invitedAt'] is Timestamp
          ? (data['invitedAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: data['acceptedAt'] is Timestamp
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      invitedBy: (data['invitedBy'] as String?) ?? '',
      notes: data['notes'] as String?,
      userId: (data['workerUid'] ?? data['userId']) as String?,
      dataScope: DataScope.fromString((data['dataScope'] as String?) ?? 'all'),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'customPermissions': customPermissions.map((p) => p.name).toList(),
        // Flat effective-permissions list for Firestore security rule checks.
        'permissions': effectivePermissionsList,
        if (customRoleId != null && customRoleId!.isNotEmpty)
          'customRoleId': customRoleId,
        if (customRoleName != null && customRoleName!.isNotEmpty)
          'customRoleName': customRoleName,
        'status': status,
        'invitedAt': Timestamp.fromDate(invitedAt),
        if (acceptedAt != null)
          'acceptedAt': Timestamp.fromDate(acceptedAt!),
        'invitedBy': invitedBy,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (userId != null && userId!.isNotEmpty) 'userId': userId,
        'dataScope': dataScope.name,
      };

  TeamMember copyWith({
    String? name,
    String? email,
    String? phone,
    TeamRole? role,
    Set<AppPermission>? customPermissions,
    String? customRoleId,
    String? customRoleName,
    bool clearCustomRole = false,
    String? status,
    DateTime? acceptedAt,
    String? notes,
    String? userId,
    DataScope? dataScope,
  }) =>
      TeamMember(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        customPermissions: customPermissions ?? this.customPermissions,
        customRoleId: clearCustomRole ? null : (customRoleId ?? this.customRoleId),
        customRoleName:
            clearCustomRole ? null : (customRoleName ?? this.customRoleName),
        status: status ?? this.status,
        invitedAt: invitedAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        invitedBy: invitedBy,
        notes: notes ?? this.notes,
        userId: userId ?? this.userId,
        dataScope: dataScope ?? this.dataScope,
      );
}
