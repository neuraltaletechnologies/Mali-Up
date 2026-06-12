import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../rbac/data/rbac_providers.dart';
import '../domain/models/team_member.dart';
import 'mappers/team_member_mapper.dart';

// ── Offline-first team members stream ─────────────────────────────────────────
//
// Reads exclusively from Drift; SyncService._pullTeamMembers hydrates the
// table on every sync cycle. The stream works without internet.

final teamMembersProvider = StreamProvider<List<TeamMember>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // tenantOwnerUidProvider is used by the RBAC layer but the local team table
  // is always scoped by businessId, so we don't need ownerUid here.
  final _ = ref.watch(tenantOwnerUidProvider); // keep dependency alive
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (bizId.isEmpty) return Stream.value(const <TeamMember>[]);
  return db.teamDao
      .watchAll(bizId)
      .map((rows) => rows.map(TeamMemberMapper.fromRow).toList());
});
