import '../../team/domain/models/team_member.dart';

/// Central permission-checking service for the current session.
///
/// All UI, navigation, and business-logic permission checks go through here.
/// Owners receive implicit full access via [isOwner]; team members only have
/// the permissions stored in their [TeamMember.effectivePermissions] set.
class PermissionService {
  final Set<AppPermission> _permissions;
  final bool _isOwner;
  final DataScope _dataScope;

  const PermissionService._({
    required Set<AppPermission> permissions,
    required bool isOwner,
    DataScope dataScope = DataScope.all,
  })  : _permissions = permissions,
        _isOwner = isOwner,
        _dataScope = dataScope;

  /// Full access — the authenticated user is a business owner.
  factory PermissionService.owner() => const PermissionService._(
        permissions: <AppPermission>{},
        isOwner: true,
      );

  /// Permission set derived from a team member's role / custom permissions.
  factory PermissionService.forMember(
    Set<AppPermission> permissions, {
    DataScope dataScope = DataScope.all,
  }) =>
      PermissionService._(
        permissions: permissions,
        isOwner: false,
        dataScope: dataScope,
      );

  /// No access — used while permissions are loading or the user is suspended.
  factory PermissionService.denied() => const PermissionService._(
        permissions: <AppPermission>{},
        isOwner: false,
      );

  // ── Identity ──────────────────────────────────────────────────────────────

  bool get isOwner => _isOwner;
  bool get isTeamMember => !_isOwner;

  /// True when this member is restricted to only their own records
  /// (sales/expenses they created, inventory assigned to them) rather than
  /// everything in the business. Always false for owners.
  bool get isOwnRecordsOnly => !_isOwner && _dataScope == DataScope.own;

  // ── Core check ────────────────────────────────────────────────────────────

  /// Returns true if the user may perform the given action.
  /// Owners always return true regardless of the permission.
  bool can(AppPermission p) => _isOwner || _permissions.contains(p);

  /// Returns true if the user has ALL of the given permissions.
  bool canAll(Iterable<AppPermission> perms) =>
      perms.every(can);

  /// Returns true if the user has ANY of the given permissions.
  bool canAny(Iterable<AppPermission> perms) =>
      perms.any(can);

  // ── Sales ─────────────────────────────────────────────────────────────────

  bool get canViewSales => can(AppPermission.viewSales);
  bool get canCreateSale => can(AppPermission.createSale);
  bool get canEditSale => can(AppPermission.editSale);
  bool get canDeleteSale => can(AppPermission.deleteSale);
  bool get canApplyDiscount => can(AppPermission.applyDiscount);
  bool get canIssueRefund => can(AppPermission.issueRefund);

  // ── Inventory ─────────────────────────────────────────────────────────────

  bool get canViewInventory => can(AppPermission.viewInventory);
  bool get canAddStock => can(AppPermission.addStock);
  bool get canEditStock => can(AppPermission.editStock);
  bool get canAdjustStock => can(AppPermission.adjustStock);
  bool get canDeleteStock => can(AppPermission.deleteStock);

  // ── Finance ───────────────────────────────────────────────────────────────

  bool get canViewFinancialReports => can(AppPermission.viewFinancialReports);
  bool get canManageExpenses => can(AppPermission.manageExpenses);
  bool get canViewCashFlow => can(AppPermission.viewCashFlow);

  // ── Customers ─────────────────────────────────────────────────────────────

  bool get canViewCustomers => can(AppPermission.viewCustomers);
  bool get canManageCustomers => can(AppPermission.manageCustomers);
  bool get canGrantCredit => can(AppPermission.grantCredit);

  // ── Debt ──────────────────────────────────────────────────────────────────

  bool get canViewDebt => can(AppPermission.viewDebt);
  bool get canManageDebt => can(AppPermission.manageDebt);
  bool get canWriteOffDebt => can(AppPermission.writeOffDebt);

  // ── Admin ─────────────────────────────────────────────────────────────────

  bool get canManageTeam => can(AppPermission.manageTeam);
  bool get canManageBilling => can(AppPermission.manageBilling);
  bool get canExportData => can(AppPermission.exportData);
}
