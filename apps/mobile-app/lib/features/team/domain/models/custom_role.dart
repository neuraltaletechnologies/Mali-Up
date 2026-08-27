import 'package:cloud_firestore/cloud_firestore.dart';

import 'team_member.dart';

// ── Custom role ───────────────────────────────────────────────────────────────
//
// A reusable, owner-defined permission set with a name (e.g. "Driver",
// "Supervisor"). Stored at businesses/{bizId}/customRoles/{roleId} and
// assigned to team members, who store `role: 'custom'` plus a `customRoleId`
// pointer and a denormalized `customRoleName`. Editing a role propagates its
// new permissions to every member currently assigned it
// (ContextFirestoreRepository.propagateCustomRole).

class CustomRole {
  final String id;
  final String name;
  final Set<AppPermission> permissions;

  /// 'all' (default) or 'own' — see [DataScope]. Only meaningful for members
  /// who lack the matching "view all" permission.
  final DataScope dataScope;
  final DateTime? updatedAt;

  const CustomRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.dataScope = DataScope.all,
    this.updatedAt,
  });

  List<String> get permissionNames =>
      permissions.map((p) => p.name).toList(growable: false);

  CustomRole copyWith({
    String? name,
    Set<AppPermission>? permissions,
    DataScope? dataScope,
  }) =>
      CustomRole(
        id: id,
        name: name ?? this.name,
        permissions: permissions ?? this.permissions,
        dataScope: dataScope ?? this.dataScope,
        updatedAt: updatedAt,
      );

  factory CustomRole.fromFirestore(Map<String, dynamic> data, String id) {
    final perms = (data['permissions'] as List?)
            ?.whereType<String>()
            .map(AppPermissionX.fromString)
            .whereType<AppPermission>()
            .toSet() ??
        <AppPermission>{};
    return CustomRole(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      permissions: perms,
      dataScope: DataScope.fromString((data['dataScope'] as String?) ?? 'all'),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'permissions': permissionNames,
        'dataScope': dataScope.name,
      };
}
