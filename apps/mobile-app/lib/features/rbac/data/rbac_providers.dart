import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart' show authStateProvider;
import '../../team/domain/models/team_member.dart';
import '../domain/permission_service.dart';

// ── Session state ─────────────────────────────────────────────────────────────
//
// Tracks how far the RBAC bootstrap has progressed.
// Route guards and loading overlays use this to prevent blank screens.

enum SessionState {
  /// Profile or member record hasn't arrived yet — hold navigation.
  loading,

  /// Authenticated owner — full access, no member record needed.
  ownerReady,

  /// Authenticated team member — member record loaded, permissions ready.
  memberReady,

  /// Team member profile loaded, but the member record is missing or the
  /// profile link fields (ownerUid / businessId / memberId) are empty.
  /// Show the recovery flow so the user isn't stranded.
  memberNotFound,
}

/// The single summary of bootstrap progress that all routing and UI reads.
/// Settles immediately for owners; may take a round-trip for team members.
final sessionStateProvider = Provider<SessionState>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider);
  // Use valueOrNull so that during resubscription (AsyncLoading with previous
  // data) we preserve the cached profile instead of reverting to loading.
  final profile = profileAsync.valueOrNull;
  if (profile == null) return SessionState.loading;

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) {
    if (kDebugMode) debugPrint('[RBAC] session → ownerReady');
    return SessionState.ownerReady;
  }

  final ownerUid   = profile['ownerUid']   as String?;
  final businessId = profile['businessId'] as String?;
  final memberId   = profile['memberId']   as String?;

  final fieldsOk = ownerUid   != null && ownerUid.isNotEmpty &&
                   businessId != null && businessId.isNotEmpty &&
                   memberId   != null && memberId.isNotEmpty;

  if (!fieldsOk) {
    if (kDebugMode) {
      debugPrint(
        '[RBAC] session → memberNotFound '
        '(ownerUid=$ownerUid bizId=$businessId memberId=$memberId)',
      );
    }
    return SessionState.memberNotFound;
  }

  final memberAsync = ref.watch(currentMemberProvider);
  // Use valueOrNull so cached member record survives resubscription.
  if (memberAsync.valueOrNull == null && memberAsync.isLoading) {
    return SessionState.loading;
  }

  if (memberAsync.valueOrNull == null) {
    if (kDebugMode) {
      debugPrint(
        '[RBAC] session → memberNotFound '
        '(Firestore doc missing for memberId=$memberId)',
      );
    }
    return SessionState.memberNotFound;
  }

  if (kDebugMode) debugPrint('[RBAC] session → memberReady');
  return SessionState.memberReady;
});

// ── User profile stream ───────────────────────────────────────────────────────
//
// Single Firestore stream for the authenticated user's profile document.
// Watches authStateProvider so it rebuilds whenever auth changes (sign-in
// during registration, sign-out from the recovery screen, etc.).
// All RBAC providers derive from this to avoid redundant reads.

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  // React to auth changes — this is what fixes the first-login race condition
  // where the provider is built before the registration Firebase Auth call
  // completes, capturing a null user and never updating.
  final authAsync = ref.watch(authStateProvider);
  if (authAsync.isLoading) return Stream.value(null);
  final user = authAsync.valueOrNull;
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
  // Use valueOrNull so cached profile survives resubscription (AsyncLoading
  // with previous data). Only yield null when there is genuinely no data yet.
  final profile = profileAsync.valueOrNull;
  if (profile == null) {
    if (kDebugMode) {
      debugPrint('[RBAC] currentMember: '
          '${profileAsync.isLoading ? 'profile loading' : 'no profile doc'}');
    }
    yield null;
    return;
  }

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) {
    if (kDebugMode) debugPrint('[RBAC] currentMember: owner — skipping member stream');
    yield null; // Owner — no member record.
    return;
  }

  final ownerUid   = profile['ownerUid']   as String?;
  final businessId = profile['businessId'] as String?;
  final memberId   = profile['memberId']   as String?;

  if (ownerUid == null || ownerUid.isEmpty ||
      businessId == null || businessId.isEmpty ||
      memberId == null || memberId.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[RBAC] currentMember: profile incomplete '
        '(ownerUid=$ownerUid bizId=$businessId memberId=$memberId)',
      );
    }
    yield null;
    return;
  }

  if (kDebugMode) {
    debugPrint('[RBAC] currentMember: streaming '
        'tenants/$ownerUid/businesses/$businessId/team_members/$memberId');
  }

  yield* FirebaseFirestore.instance
      .collection('tenants')
      .doc(ownerUid)
      .collection('businesses')
      .doc(businessId)
      .collection('team_members')
      .doc(memberId)
      .snapshots()
      .map((snap) {
    if (kDebugMode) {
      debugPrint('[RBAC] currentMember: snap exists=${snap.exists} '
          'status=${snap.data()?['status']} role=${snap.data()?['role']}');
    }
    return snap.exists ? TeamMember.fromFirestore(snap.data()!, snap.id) : null;
  });
});

// ── Permissions loaded flag ───────────────────────────────────────────────────
//
// True once we have enough data to make authoritative permission decisions.
// Route guards should skip redirecting until this is true.
//
// Note: returns true even when the member record is missing (memberNotFound
// state) so the router can redirect to the recovery screen rather than
// hanging on a blank loading state.

final permissionsLoadedProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileStreamProvider);
  // Use valueOrNull first so cached profile survives resubscription.
  final profile = profileAsync.valueOrNull;
  if (profile == null) {
    // Null profile has two meanings:
    //   1. Signed out — nothing to load, treat as settled.
    //   2. Signed in but users/{uid} hasn't been written yet (first-install
    //      race: Firebase Auth fired before saveUser() completed).
    // For case 2, isLoading is true and we genuinely have no previous data.
    if (profileAsync.isLoading) return false;
    return FirebaseAuth.instance.currentUser == null;
  }

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) return true; // Owner is always ready.

  // For team members, wait for the member record too.
  final memberAsync = ref.watch(currentMemberProvider);
  // Only block if there is genuinely no member data yet (not a resubscription).
  if (memberAsync.valueOrNull == null && memberAsync.isLoading) return false;

  // Member record settled (either has data or is null/missing).
  if (kDebugMode) {
    debugPrint('[RBAC] permissionsLoaded: true '
        '(member=${memberAsync.valueOrNull?.role.name ?? 'null'})');
  }
  return true;
});

// ── Permission service ────────────────────────────────────────────────────────
//
// The single source of truth for all permission checks in the app.
// Consumers call `ref.watch(permissionServiceProvider).canViewSales()` etc.

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return PermissionService.denied();

  final profileAsync = ref.watch(userProfileStreamProvider);
  // Use valueOrNull so cached profile survives resubscription (AsyncLoading
  // with previous data). Avoids reverting to denied() on auth token refresh.
  final profile = profileAsync.valueOrNull;
  if (profile == null) return PermissionService.denied();

  final isTeamMember = profile['isTeamMember'] == true;
  if (!isTeamMember) {
    if (kDebugMode) debugPrint('[RBAC] permissionService → owner');
    return PermissionService.owner();
  }

  final memberAsync = ref.watch(currentMemberProvider);
  // Only deny if there is genuinely no member data (not just resubscribing).
  if (memberAsync.valueOrNull == null && memberAsync.isLoading) {
    return PermissionService.denied();
  }

  final member = memberAsync.valueOrNull;
  if (member == null) return PermissionService.denied();

  // Suspended members lose all permissions immediately.
  if (member.status == 'suspended') {
    if (kDebugMode) debugPrint('[RBAC] permissionService → denied (suspended)');
    return PermissionService.denied();
  }

  if (kDebugMode) {
    debugPrint('[RBAC] permissionService → member '
        'role=${member.role.name} '
        'perms=${member.effectivePermissions.length}');
  }
  return PermissionService.forMember(member.effectivePermissions);
});
