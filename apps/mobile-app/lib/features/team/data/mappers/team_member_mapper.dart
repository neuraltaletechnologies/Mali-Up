import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/team_member.dart';

abstract final class TeamMemberMapper {
  // ─── Drift row → domain ────────────────────────────────────────────────────

  static TeamMember fromRow(TeamMembersTableData row) {
    final customPerms = _decodePermissions(row.customPermissions);
    return TeamMember(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      role: TeamRole.fromString(row.role),
      customPermissions: customPerms,
      customRoleId: row.customRoleId.isNotEmpty ? row.customRoleId : null,
      customRoleName: row.customRoleName.isNotEmpty ? row.customRoleName : null,
      status: row.status,
      invitedAt: DateTime.fromMillisecondsSinceEpoch(row.invitedAt),
      acceptedAt: row.acceptedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.acceptedAt!)
          : null,
      invitedBy: row.invitedBy,
      notes: row.notes.isNotEmpty ? row.notes : null,
      userId: row.userId.isNotEmpty ? row.userId : null,
      dataScope: DataScope.fromString(row.dataScope),
    );
  }

  // ─── domain → Drift companion ──────────────────────────────────────────────

  static TeamMembersTableCompanion toCompanion(
    TeamMember member, {
    required String businessId,
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = member.id.isNotEmpty ? member.id : const Uuid().v4();
    return TeamMembersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(member.name),
      email: Value(member.email),
      phone: Value(member.phone),
      role: Value(member.role.name),
      customPermissions: Value(
        jsonEncode(member.customPermissions.map((p) => p.name).toList()),
      ),
      customRoleId: Value(member.customRoleId ?? ''),
      customRoleName: Value(member.customRoleName ?? ''),
      status: Value(member.status),
      invitedAt: Value(member.invitedAt.millisecondsSinceEpoch),
      acceptedAt: Value(member.acceptedAt?.millisecondsSinceEpoch),
      invitedBy: Value(member.invitedBy),
      notes: Value(member.notes ?? ''),
      userId: Value(member.userId ?? ''),
      dataScope: Value(member.dataScope.name),
      createdAt: Value(createdAtMs),
      updatedAt: Value(now),
      serverUpdatedAt: Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: const Value(0),
    );
  }

  // ─── Firestore → domain ────────────────────────────────────────────────────

  static TeamMember fromFirestore(Map<String, dynamic> data, String id) {
    return TeamMember.fromFirestore(data, id);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Set<AppPermission> _decodePermissions(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map(AppPermissionX.fromString)
            .whereType<AppPermission>()
            .toSet();
      }
    } catch (_) {}
    return {};
  }
}
