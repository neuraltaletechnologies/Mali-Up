import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../team/domain/models/team_member.dart';
import '../domain/permission_service.dart';

// ── User profile stream ───────────────────────────────────────────────────────
//
// Single Firestore stream for the authenticated user's profile document.
// All RBAC providers derive from this to avoid redundant reads.

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((s) => s.data());
});

// ── Tenant owner UID ─────────────────────────────────────────────────────────
//
// Returns the Firestore tenant root UID used to scope all data queries:
//   - Business owners  → their own Firebase Auth UID
//   - Team members     → the inviting owner's UID (stored as `ownerUid`)
//
// While the profile is loading, defaults to the user's own UID so that
// owners see data immediately; team members will briefly see empty data.

final tenantOwnerUidProvider = Provider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final profileAsync = ref.watch(userProfileStreamProvider);

  // Optimistic default: use own UID while loading (correct for owners).
  if (profileAsync.isLoading) return user.uid;

  final profile = profileAsync.valueOrNull;
  if (profile == null) return user.uid;

  final isTeamMember = profile['isTeamMember'] == true;
  if (isTeamMember) {
    final ownerUid = profile['ownerUid'] as String?;
    return (ownerUid != null && ownerUid.isNotEmpty) ? ownerUid : user.uid;
  }
  return user.uid;
});

// ── Current team member record ───────────────────────────────────────────────
//
// Streams the authenticated user's TeamMember document from the owner's
// tenant.  Emits null for business owners (they never have a member record).

final currentMemberProvider = StreamProvider<TeamMember?>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield null;
    return;
  }

  final profileAsync = ref.watch(userProfileStreamProvider);
  if (profileAsync.isLoading) return; // Wait for profile before emitting.

  final profile = profileAsync.valueOrNull;
  if (profile == null) {
    yield null;
    return;
  }

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) {
    yield null; // Owner — no member record.
    return;
  }

  final ownerUid  = profile['ownerUid']   as String?;
  final businessId = profile['businessId'] as String?;
  final memberId   = profile['memberId']   as String?;

  if (ownerUid == null || businessId == null || memberId == null) {
    yield null;
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('tenants')
      .doc(ownerUid)
      .collection('businesses')
      .doc(businessId)
      .collection('team_members')
      .doc(memberId)
      .snapshots()
      .map((snap) =>
          snap.exists ? TeamMember.fromFirestore(snap.data()!, snap.id) : null);
});

// ── Permissions loaded flag ───────────────────────────────────────────────────
//
// True once we have enough data to make authoritative permission decisions.
// Route guards should skip redirecting until this is true.

final permissionsLoadedProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider);
  if (profileAsync.isLoading) return false;

  final profile = profileAsync.valueOrNull;
  if (profile == null) return true; // Signed-out / no profile → treat as loaded.

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) return true; // Owner is always ready.

  // For team members, wait for the member record too.
  return !ref.watch(currentMemberProvider).isLoading;
});

// ── Permission service ────────────────────────────────────────────────────────
//
// The single source of truth for all permission checks in the app.
// Consumers call `ref.watch(permissionServiceProvider).canViewSales()` etc.

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return PermissionService.denied();

  final profileAsync = ref.watch(userProfileStreamProvider);
  if (profileAsync.isLoading) return PermissionService.denied();

  final profile = profileAsync.valueOrNull;
  if (profile == null) return PermissionService.denied();

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) return PermissionService.owner();

  final memberAsync = ref.watch(currentMemberProvider);
  if (memberAsync.isLoading) return PermissionService.denied();

  final member = memberAsync.valueOrNull;
  if (member == null) return PermissionService.denied();

  // Suspended members lose all permissions immediately.
  if (member.status == 'suspended') return PermissionService.denied();

  return PermissionService.forMember(member.effectivePermissions);
});
