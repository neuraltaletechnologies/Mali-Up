import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/localization_service.dart';
import '../../rbac/data/rbac_providers.dart';
import '../domain/models/team_member.dart';
import 'team_providers.dart';

// ── "Issued by" attribution ──────────────────────────────────────────────────
//
// Detail and receipt screens (sales, debt, expense, cash flow) show who
// created each record. Every entity already stores the creator's Firebase
// Auth UID on its `createdBy` / `recordedBy` field — these providers turn
// that UID into a human name, offline-first, using the local team table and
// the current session. No network calls: safe to watch from any build.

/// True when the business has at least one invited team member. A solo
/// business never shows the attribution line — it would only ever say "You".
final businessHasTeamProvider = Provider<bool>((ref) {
  final members = ref.watch(teamMembersProvider).valueOrNull ?? const [];
  return members.isNotEmpty;
});

/// Resolved creator for a `createdBy` / `recordedBy` UID.
///
/// [name] is null when the UID cannot be resolved to anything better than a
/// raw id — callers hide the row in that case (unless [isSelf], which always
/// has a label). [isSelf] is true when the current user created the record.
typedef CreatorInfo = ({String? name, bool isSelf});

final creatorInfoProvider =
    Provider.family<CreatorInfo, String>((ref, uid) {
  final id = uid.trim();
  if (id.isEmpty) return (name: null, isSelf: false);

  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final isSelf = currentUid.isNotEmpty && currentUid == id;

  // A staff record whose worker UID matches — the common case for an owner
  // reviewing a team member's activity.
  final members =
      ref.watch(teamMembersProvider).valueOrNull ?? const <TeamMember>[];
  for (final m in members) {
    if ((m.userId ?? '').isNotEmpty && m.userId == id) {
      final n = m.name.trim();
      return (name: n.isEmpty ? null : n, isSelf: isSelf);
    }
  }

  // The viewer themselves, but not in the staff list — typically the owner.
  if (isSelf) {
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final resolved = _nameFromProfile(profile).isNotEmpty
        ? _nameFromProfile(profile)
        : (FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '');
    return (name: resolved.isEmpty ? null : resolved, isSelf: true);
  }

  // The business owner's UID, seen by a team member — they can't read the
  // owner's profile, so fall back to a generic label rather than a raw id.
  final ownerUid = ref.watch(tenantOwnerUidProvider);
  if (ownerUid != null && ownerUid.isNotEmpty && ownerUid == id) {
    return (name: LocalizationService.tr(en: 'Owner', sw: 'Mmiliki'), isSelf: false);
  }

  return (name: null, isSelf: false);
});

/// The display string for an "Issued by" row, or null when the row should be
/// hidden (solo business, or an unresolvable UID that isn't the viewer).
String? issuedByLabel(WidgetRef ref, String uid) {
  if (!ref.watch(businessHasTeamProvider)) return null;
  final info = ref.watch(creatorInfoProvider(uid));
  if (info.name == null && !info.isSelf) return null;
  if (info.isSelf) {
    final you = LocalizationService.tr(en: 'You', sw: 'Wewe');
    final n = info.name;
    return (n == null || n.isEmpty) ? you : '$n ($you)';
  }
  return info.name;
}

String _nameFromProfile(Map<String, dynamic>? p) {
  if (p == null) return '';
  for (final key in const ['displayName', 'name', 'fullName']) {
    final v = (p[key] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  final first = (p['firstName'] ?? '').toString().trim();
  final last = (p['lastName'] ?? '').toString().trim();
  return [first, last].where((s) => s.isNotEmpty).join(' ');
}
