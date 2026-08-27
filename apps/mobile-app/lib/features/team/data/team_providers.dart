import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/context_firestore_repository.dart';
import '../../../core/providers/business_id_provider.dart';
import '../../../core/providers/sync_provider.dart';
import '../../rbac/data/rbac_providers.dart';
import '../domain/models/custom_role.dart';
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

// ── Reusable custom roles ────────────────────────────────────────────────────
//
// Owner-defined named permission sets (e.g. "Driver") stored at
// businesses/{bizId}/customRoles. Online-only — like the rest of the team
// flows, which already require a connection (OnlineGuard). Each member keeps
// a denormalized `customRoleName`, so the team list still labels members
// correctly offline even though this stream is empty then.

final customRolesProvider = StreamProvider<List<CustomRole>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  final bizId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';
  if (user == null || bizId.isEmpty) {
    return Stream.value(const <CustomRole>[]);
  }
  return ContextFirestoreRepository().watchCustomRoles(
    uid: user.uid,
    context: ResolvedFinanceContext.business(bizId),
  );
});
