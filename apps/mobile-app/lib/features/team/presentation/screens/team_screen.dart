import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/error_reporter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/online_guard.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../shared/widgets/nav_aware_fab.dart';
import '../../../../shared/widgets/silent_refresh.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/data/repositories/context_firestore_repository.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../onboarding/domain/validators/onboarding_validator.dart';
import '../../../onboarding/presentation/screens/_onboarding_scaffold.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../../rbac/data/rbac_providers.dart';
import '../../data/mappers/team_member_mapper.dart';
import '../../data/team_providers.dart';
import '../../domain/models/custom_role.dart';
import '../../domain/models/team_member.dart';
import '../../../../shared/widgets/smart_skeleton.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Removes [memberId] from [businessId] via the `removeTeamMember` Cloud
/// Function: deletes the member's staff records + pending invite and, unless
/// they run their own business, their Mali Up login (Firebase Auth account,
/// profile and PIN) — while leaving every sale, invoice and expense they
/// created inside the business untouched. Throws on failure.
Future<void> _callRemoveTeamMember({
  required String businessId,
  required String memberId,
}) async {
  final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable(
        'removeTeamMember',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
  await callable.call<Map<String, dynamic>>({
    'businessId': businessId,
    'memberId': memberId,
  });
}

String _removeMemberErrorText(Object error) {
  if (error is FirebaseFunctionsException && error.code == 'permission-denied') {
    return _tr(
      'Only the business owner can remove a team member.',
      'Ni mmiliki wa biashara pekee anayeweza kuondoa mwanachama.',
    );
  }
  return _tr(
    'Could not remove member. Please try again.',
    'Imeshindikana kuondoa mwanachama. Jaribu tena.',
  );
}

// ── Role colours ──────────────────────────────────────────────────────────────

Color _roleColor(TeamRole r) => switch (r) {
  TeamRole.owner => AppColors.navyPrimary,
  TeamRole.manager => const Color(0xFF7C3AED),
  TeamRole.accountant => AppColors.tealAccent,
  TeamRole.cashier => AppColors.success,
  TeamRole.stockClerk => AppColors.warning,
  TeamRole.custom => AppColors.textSecondary,
};

IconData _roleIcon(TeamRole r) => switch (r) {
  TeamRole.owner => Icons.shield_rounded,
  TeamRole.manager => Icons.manage_accounts_rounded,
  TeamRole.accountant => Icons.calculate_rounded,
  TeamRole.cashier => Icons.point_of_sale_rounded,
  TeamRole.stockClerk => Icons.inventory_2_rounded,
  TeamRole.custom => Icons.tune_rounded,
};

/// Result of the role picker: a built-in [TeamRole], or [TeamRole.custom]
/// paired with a saved [CustomRole] when the owner picked a reusable role.
class _RoleSelection {
  final TeamRole role;
  final CustomRole? customRole;
  const _RoleSelection(this.role, [this.customRole]);
}

// ── Filter ────────────────────────────────────────────────────────────────────

enum _TeamFilter { all, active, pending, suspended }

extension _TeamFilterX on _TeamFilter {
  String get label => switch (this) {
    _TeamFilter.all => _tr('All', 'Wote'),
    _TeamFilter.active => _tr('Active', 'Amilifu'),
    _TeamFilter.pending => _tr('Pending', 'Wanaosubiri'),
    _TeamFilter.suspended => _tr('Suspended', 'Waliozuiwa'),
  };
}

// ═════════════════════════════════════════════════════════════════════════════
// TEAM SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  _TeamFilter _filter = _TeamFilter.all;
  bool _searchExpanded = false;
  String _query = '';

  int get _activeFilters => _filter != _TeamFilter.all ? 1 : 0;

  @override
  void dispose() {
    super.dispose();
  }

  List<TeamMember> _applyFilter(List<TeamMember> all) {
    final query = _query.toLowerCase();
    var result = switch (_filter) {
      _TeamFilter.all => all,
      _TeamFilter.active => all.where((m) => m.status == 'active').toList(),
      _TeamFilter.pending => all.where((m) => m.status == 'pending').toList(),
      _TeamFilter.suspended =>
        all.where((m) => m.status == 'suspended').toList(),
    };
    if (query.isNotEmpty) {
      result = result
          .where(
            (m) =>
                m.name.toLowerCase().contains(query) ||
                m.email.toLowerCase().contains(query) ||
                m.phone.contains(query),
          )
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);
    final ps = ref.watch(permissionServiceProvider);

    return Scaffold(
      floatingActionButton: ps.isOwner
          ? NavAwareFab(
              child: FloatingActionButton.extended(
                onPressed: () => _tryInvite(context),
                backgroundColor: AppColors.yellowBrand,
                foregroundColor: AppColors.navyPrimary,
                elevation: 3,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: Text(
                  _tr('Add Member', 'Ongeza Mwanachama'),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : null,
      body: membersAsync.smartWhen(
        skeleton: () => const TeamPageSkeleton(),
        onError: (_, _) => Center(
          child: Text(_tr('Failed to load team', 'Imeshindikana kupakia timu')),
        ),
        data: (members) {
          final filtered = _applyFilter(members);
          final active = members.where((m) => m.status == 'active').length;
          final pending = members.where((m) => m.status == 'pending').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TeamDarkHeader(
                totalCount: members.length,
                activeCount: active,
                pendingCount: pending,
                searchExpanded: _searchExpanded,
                activeFilters: _activeFilters,
                onSearchToggle: () => setState(() {
                  _searchExpanded = !_searchExpanded;
                  if (!_searchExpanded) _query = '';
                }),
                onSearchChanged: (v) => setState(() => _query = v.trim()),
                onFilterTap: () => showAppSheet<void>(
                  context,
                  builder: (_) => _TeamFilterSheet(
                    selected: _filter,
                    onApply: (f) => setState(() => _filter = f),
                  ),
                ),
              ),
              const SizedBox(height: HeaderStatsPill.pillHalf + 8),
              if (_filter != _TeamFilter.all)
                _ActiveTeamFilterChip(
                  filter: _filter,
                  onRemove: () => setState(() => _filter = _TeamFilter.all),
                ),
              Expanded(
                child: SilentRefresh(
                  onRefresh: () => triggerSilentSync(context, ref),
                  child: filtered.isEmpty
                      ? SingleChildScrollView(
                          physics: silentRefreshPhysics,
                          child: _EmptyState(filter: _filter),
                        )
                      : ListView.builder(
                          physics: silentRefreshPhysics,
                          padding: const EdgeInsets.only(bottom: 104),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => ListSwipeCard(
                            itemKey: ValueKey(filtered[i].id),
                            onEdit: ps.isOwner
                                ? () => _showMemberSheet(context, filtered[i])
                                : null,
                            onDelete: ps.isOwner
                                ? () => _removeMember(context, ref, filtered[i])
                                : null,
                            child: _MemberCard(
                              member: filtered[i],
                              isLast: i == filtered.length - 1,
                              onTap: () =>
                                  _showMemberSheet(context, filtered[i]),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _tryInvite(BuildContext ctx) async {
    // Checked here, at the very first tap, so an offline user is told
    // immediately instead of filling in the whole invite form only to have
    // Save fail at the end.
    if (!await OnlineGuard.ensureOnline(ctx)) return;
    if (!ctx.mounted) return;
    final plan = await ref.read(planStatusProvider.future);
    if (!ctx.mounted) return;
    final maxUsers = plan.limits.maxUsers;
    if (maxUsers != -1) {
      final currentCount =
          ref.read(teamMembersProvider).valueOrNull?.length ?? 0;
      // maxUsers counts total users including the owner, so additional
      // members allowed = maxUsers - 1 (Starter=1 means owner only).
      final additionalAllowed = maxUsers - 1;
      if (currentCount >= additionalAllowed) {
        await showUpgradeSheet(
          ctx,
          currentStatus: plan,
          featureKey: PlanFeatureKey.teamMembers,
          // Phrased around team-member seats (owner excluded) rather than
          // the raw maxUsers total, so it doesn't read as if the owner is
          // "using up" one of the team member slots.
          triggerReason: additionalAllowed <= 0
              ? _tr(
                  "Your plan doesn't include team members yet — it's just you as owner. Upgrade to invite your team.",
                  'Mpango wako hauna nafasi za wanachama wa timu bado — ni wewe tu kama mmiliki. Boresha ili kualika timu yako.',
                )
              : _tr(
                  'Your plan allows up to $additionalAllowed team member${additionalAllowed == 1 ? '' : 's'}, in addition to you as owner.',
                  'Mpango wako unaruhusu hadi wanachama $additionalAllowed wa timu, mbali na wewe kama mmiliki.',
                ),
        );
        return;
      }
    }
    if (!ctx.mounted) return;
    _showInviteSheet(ctx);
  }

  void _showInviteSheet(BuildContext ctx) {
    showAppSheet<void>(ctx, builder: (_) => const _InviteMemberSheet());
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _tr('Remove Member', 'Ondoa Mwanachama'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _tr(
            'Remove ${member.name} from the team? This cannot be undone.',
            'Ondoa ${member.name} kutoka timu? Haiwezi kurejeshwa.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_tr('Remove', 'Ondoa')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Removal erases the member's login server-side — it must reach the server.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!context.mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx2 = await repo.resolveContextForUser(user.uid);
      final bizId = ctx2.businessId ?? '';
      if (bizId.isEmpty) {
        if (context.mounted) {
          AppNotification.error(context, _removeMemberErrorText(Exception()));
        }
        return;
      }

      await _callRemoveTeamMember(businessId: bizId, memberId: member.id);

      // The staff doc is gone server-side; the incremental team pull only sees
      // upserts, never deletes — hide the row locally right away.
      try {
        await ref.read(appDatabaseProvider).teamDao.softDelete(member.id);
      } catch (_) {}

      unawaited(
        AuditLogService().log(
          ownerUid: user.uid,
          businessId: bizId,
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberRemoved,
          targetMemberId: member.id,
          targetName: member.name,
        ),
      );
      if (context.mounted) {
        AppNotification.success(
          context,
          _tr('${member.name} removed.', '${member.name} ameondolewa.'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.error(context, _removeMemberErrorText(e));
      }
    }
  }

  void _showMemberSheet(BuildContext ctx, TeamMember member) {
    showAppSheet<void>(ctx, builder: (_) => _MemberSheet(member: member));
  }
}

// ── Dark Header ────────────────────────────────────────────────────────────────

class _TeamDarkHeader extends StatefulWidget {
  final int totalCount;
  final int activeCount;
  final int pendingCount;
  final bool searchExpanded;
  final int activeFilters;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  const _TeamDarkHeader({
    required this.totalCount,
    required this.activeCount,
    required this.pendingCount,
    required this.searchExpanded,
    required this.activeFilters,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<_TeamDarkHeader> createState() => _TeamDarkHeaderState();
}

class _TeamDarkHeaderState extends State<_TeamDarkHeader> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_TeamDarkHeader old) {
    super.didUpdateWidget(old);
    if (!widget.searchExpanded && old.searchExpanded) {
      _ctrl.clear();
      _focus.unfocus();
    } else if (widget.searchExpanded && !old.searchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Color get _alertDotColor {
    if (widget.pendingCount > 0) return AppColors.warning;
    if (widget.activeFilters > 0) return AppColors.yellowBrand;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _alertDotColor;

    return DarkHeaderShell(
      stretchPill: true,
      title: Text(
        _tr('My Team', 'Timu Yangu'),
        style: GoogleFonts.dmSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderIconButton(
            icon: widget.searchExpanded
                ? Icons.close_rounded
                : Icons.search_rounded,
            active: widget.searchExpanded,
            onTap: widget.onSearchToggle,
          ),
          const SizedBox(width: 10),
          HeaderIconButton(
            icon: Icons.tune_rounded,
            active: widget.activeFilters > 0,
            onTap: widget.onFilterTap,
            dotColor: dotColor != Colors.transparent ? dotColor : null,
          ),
        ],
      ),
      expandable: HeaderSearchField(
        controller: _ctrl,
        focusNode: _focus,
        onChanged: widget.onSearchChanged,
        hintText: _tr('Search by name, email…', 'Tafuta kwa jina, barua pepe…'),
        showClear: _ctrl.text.isNotEmpty,
      ),
      expanded: widget.searchExpanded,
      pill: HeaderStatsPill(
        layout: HeaderPillLayout.stretched,
        stats: [
          HeaderPillStat(
            value: '${widget.totalCount}',
            label: _tr('Members', 'Wanachama'),
            color: AppColors.tealAccent,
          ),
          HeaderPillStat(
            value: '${widget.activeCount}',
            label: _tr('Active', 'Amilifu'),
            color: AppColors.success,
          ),
          HeaderPillStat(
            value: '${widget.pendingCount}',
            label: _tr('Pending', 'Wanaosubiri'),
            color: widget.pendingCount > 0
                ? AppColors.warning
                : AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet ───────────────────────────────────────────────────────────────

class _TeamFilterSheet extends StatefulWidget {
  final _TeamFilter selected;
  final ValueChanged<_TeamFilter> onApply;

  const _TeamFilterSheet({required this.selected, required this.onApply});

  @override
  State<_TeamFilterSheet> createState() => _TeamFilterSheetState();
}

class _TeamFilterSheetState extends State<_TeamFilterSheet> {
  late _TeamFilter _pick;

  @override
  void initState() {
    super.initState();
    _pick = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    // showAppSheet renders with a transparent barrier background, so the sheet
    // must paint its own surface — without this Material the content floats
    // over whatever is behind it. Matches _DebtFilterSheet.
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 4),
              _SheetSectionLabel(_tr('Status', 'Hali')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _TeamFilter.values
                    .map(
                      (f) => _SortChip(
                        label: f.label,
                        selected: _pick == f,
                        onTap: () => setState(() => _pick = f),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_pick);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _tr('Apply', 'Tumia'),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Active filter chip ─────────────────────────────────────────────────────────

class _ActiveTeamFilterChip extends StatelessWidget {
  final _TeamFilter filter;
  final VoidCallback onRemove;
  const _ActiveTeamFilterChip({required this.filter, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.navyPrimary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member card ────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final bool isLast;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(member.role);
    final permCount = member.effectivePermissions.length;

    final statusColor = switch (member.status) {
      'active' => AppColors.success,
      'pending' => AppColors.warning,
      _ => AppColors.textDisabled,
    };
    final statusLabel = switch (member.status) {
      'active' => _tr('Active', 'Amilifu'),
      'pending' => _tr('Pending', 'Inasubiri'),
      _ => _tr('Suspended', 'Imezuiliwa'),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: rc.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: rc,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(_roleIcon(member.role), size: 12, color: rc),
                          const SizedBox(width: 4),
                          Text(
                            member.roleLabel(sw: LocalizationService.isSwahili),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: rc,
                            ),
                          ),
                          if (member.email.isNotEmpty) ...[
                            Text(
                              '  ·  ',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                member.email,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '$permCount ${_tr("permissions", "ruhusa")}',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 12, left: 54),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _TeamFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: filter == _TeamFilter.all
        ? Icons.group_outlined
        : Icons.manage_accounts_outlined,
    title: filter == _TeamFilter.all
        ? _tr('Your team is just you for now', 'Timu yako ni wewe tu kwa sasa')
        : _tr('No members in this group', 'Hakuna wanachama katika kundi hili'),
    subtitle: filter == _TeamFilter.all
        ? _tr(
            'Tap "Add Member" to invite your first team member.',
            'Bonyeza "Ongeza Mwanachama" kukaribisha mwanachama wako wa kwanza.',
          )
        : _tr(
            'Try a different permission group to find members.',
            'Jaribu kundi tofauti la ruhusa kupata wanachama.',
          ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// INVITE MEMBER SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet();

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TeamRole _selectedRole = TeamRole.cashier;
  Set<AppPermission> _customPerms = {};
  bool _ownRecordsOnly = false;
  bool _isSaving = false;

  /// Non-null when a saved, reusable custom role is selected (in which case
  /// [_selectedRole] is [TeamRole.custom] and permissions come from the role).
  CustomRole? _selectedCustomRole;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _customPerms = Set.of(defaultPermissionsFor(TeamRole.cashier));

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _applySelection(_RoleSelection sel) {
    setState(() {
      _selectedRole = sel.role;
      _selectedCustomRole = sel.customRole;
      if (sel.customRole != null) {
        _customPerms = Set.of(sel.customRole!.permissions);
        // A saved role dictates its own data scope.
        _ownRecordsOnly = sel.customRole!.dataScope == DataScope.own;
      } else if (sel.role != TeamRole.custom) {
        _customPerms = Set.of(defaultPermissionsFor(sel.role));
        // _ownRecordsOnly is left as the owner set it — it applies to any role.
      }
      // Generic (one-off) custom: keep whatever permissions were toggled.
    });
  }

  Future<void> _pickRole(BuildContext context) async {
    final picked = await showAppSheet<_RoleSelection>(
      context,
      builder: (_) => _RolePickerSheet(
        currentRole: _selectedRole,
        currentCustomRoleId: _selectedCustomRole?.id,
      ),
    );
    if (picked != null) _applySelection(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();

    final rawPhone = _phoneCtrl.text.trim();
    final phoneError = OnboardingValidator.validatePhone(rawPhone);
    if (phoneError != null) {
      _snack(phoneError);
      return;
    }

    final normalizedPhone = OnboardingValidator.normalisePhone(rawPhone);

    // Inviting a member writes the invite + pending-invite lookup docs that
    // staff login depends on — this must reach the server, so online-only.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);

      final savedRole = _selectedCustomRole;
      final permsToStore = savedRole != null
          ? savedRole.permissions
          : (_selectedRole == TeamRole.custom
              ? _customPerms
              : defaultPermissionsFor(_selectedRole));

      final storedPhone = normalizedPhone.isNotEmpty
          ? normalizedPhone
          : rawPhone;

      final permNames = permsToStore.map((p) => p.name).toList();

      // "Own records only" is offered for every role now, not just custom —
      // a cashier or stock clerk can be scoped to their own contribution too.
      final effectiveScope = savedRole != null
          ? savedRole.dataScope
          : (_ownRecordsOnly ? DataScope.own : DataScope.all);

      // OnlineGuard only checks that a network interface is up (e.g.
      // connectivity_plus), not that Firestore is actually reachable — a
      // weak/captive-portal connection passes that check and then hangs
      // here indefinitely. A hard timeout turns that into a clear, fast
      // failure instead of a spinner that never resolves.
      const writeTimeout = Duration(seconds: 15);

      // Write team_member record (for team management UI)
      final memberRef = await repo
          .addTeamMember(
            uid: user.uid,
            context: ctx,
            data: {
              'name': name,
              'email': '',
              'phone': storedPhone,
              'role': _selectedRole.name,
              'customPermissions': permNames,
              // Flat list read by isStaffWithAny() security rules and pointer-doc rule.
              'permissions': permNames,
              if (savedRole != null) 'customRoleId': savedRole.id,
              if (savedRole != null) 'customRoleName': savedRole.name,
              'status': 'pending',
              'invitedAt': FieldValue.serverTimestamp(),
              'invitedBy': user.uid,
              if (_notesCtrl.text.trim().isNotEmpty)
                'notes': _notesCtrl.text.trim(),
              'dataScope': effectiveScope.name,
            },
          )
          .timeout(writeTimeout);

      // Write pendingInvite for fast phone-based lookup during staff login
      if (normalizedPhone.isNotEmpty) {
        final bizId = ctx.businessId ?? '';
        // Ensure we have a valid businessId; fetch businessName using an explicit context
        final bizName = bizId.isNotEmpty
            ? await repo
                  .getBusinessName(
                    uid: user.uid,
                    context: ResolvedFinanceContext.business(bizId),
                  )
                  .timeout(writeTimeout, onTimeout: () => '')
            : '';
        await repo
            .writePendingInvite(
              inviteData: {
                'businessId': bizId,
                'businessName': bizName,
                'fullName': name,
                'phoneNumber': normalizedPhone,
                'email': '',
                'role': _selectedRole.name,
                'invitedBy': user.uid,
                'ownerUid': user.uid,
                'memberId': memberRef.id,
                'status': 'pending',
                'pinCreated': false,
                'createdAt': FieldValue.serverTimestamp(),
              },
            )
            .timeout(writeTimeout);
      }

      // Write to Drift immediately so the member appears in the list right away.
      // syncStatus='synced' because the record is already in Firestore.
      try {
        final db = ref.read(appDatabaseProvider);
        final bizId = ctx.businessId ?? '';
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final member = TeamMember(
          id: memberRef.id,
          name: name,
          email: '',
          phone: storedPhone,
          role: _selectedRole,
          customPermissions: permsToStore,
          customRoleId: savedRole?.id,
          customRoleName: savedRole?.name,
          status: 'pending',
          invitedAt: DateTime.now(),
          invitedBy: user.uid,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
          dataScope: effectiveScope,
        );
        await db.teamDao.upsert(
          TeamMemberMapper.toCompanion(
            member,
            businessId: bizId,
            syncStatus: 'synced',
            createdAtMs: nowMs,
          ),
        );
      } catch (_) {
        // Best-effort — sync cycle will populate Drift on next pull
      }

      // Audit log — best-effort, do not await
      unawaited(
        AuditLogService().log(
          ownerUid: user.uid,
          businessId: ctx.businessId ?? '',
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberInvited,
          targetMemberId: memberRef.id,
          targetName: name,
          newValue: _selectedRole.name,
        ),
      );

      navigator.pop();
      AppNotification.showVia(
        overlay,
        _tr('$name added to the team!', '$name ameongezwa kwenye timu!'),
        type: AppNotificationType.success,
      );
    } catch (e, st) {
      // Swallowed to a generic message for the user, but reported so a
      // recurring cause (e.g. a Firestore rule not yet deployed for the
      // staff/pendingInvites collections) is visible instead of only ever
      // showing up as "try again" support tickets.
      ErrorReporter.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _isSaving = false);
      final message = e is TimeoutException
          ? _tr(
              'Your connection is too weak to add a team member right now. Try again on a stronger connection.',
              'Muunganisho wako ni dhaifu kuongeza mwanachama sasa. Jaribu tena kwenye muunganisho imara zaidi.',
            )
          : _tr(
              'Could not add team member. Please try again.',
              'Imeshindikana kuongeza mwanachama. Jaribu tena.',
            );
      AppNotification.showVia(
        overlay,
        message,
        type: AppNotificationType.error,
      );
    }
  }

  void _snack(String msg) => AppNotification.info(context, msg);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final headingStyle = GoogleFonts.dmSans(
      fontSize: 18,
      color: AppColors.navyPrimary,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      color: AppColors.textMuted,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SheetHandle(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Center(
                            child: Text(
                              _tr('Add Team Member', 'Ongeza Mwanachama'),
                              textAlign: TextAlign.center,
                              style: headingStyle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _tr(
                                'Invite someone to join your business team.',
                                'Mkaribishe mtu kujiunga na timu yako ya biashara.',
                              ),
                              textAlign: TextAlign.center,
                              style: subtitleStyle,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Member details ──────────────────────────
                          _sectionLabel(
                            _tr('Member Details', 'Maelezo ya Mwanachama'),
                          ),
                          const SizedBox(height: 8),

                          OnboardingField(
                            controller: _nameCtrl,
                            label: _tr('Full Name *', 'Jina Kamili *'),
                            hint: _tr('Enter full name', 'Ingiza jina kamili'),
                            autofocus: true,
                            prefix: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? _tr('Name is required.', 'Jina linahitajika.')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          OnboardingField(
                            controller: _phoneCtrl,
                            label: _tr('Phone Number *', 'Namba ya Simu *'),
                            hint: '+255 700 000 000',
                            keyboardType: TextInputType.phone,
                            prefix: const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            validator: (v) =>
                                OnboardingValidator.validatePhone(v ?? ''),
                          ),
                          const SizedBox(height: 24),

                          // ── Role ─────────────────────────────────────
                          _sectionLabel(_tr('Role', 'Jukumu')),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _pickRole(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _roleColor(
                                        _selectedRole,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _roleIcon(_selectedRole),
                                      size: 18,
                                      color: _roleColor(_selectedRole),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedCustomRole?.name ??
                                              _tr(
                                                _selectedRole.label,
                                                _selectedRole.labelSw,
                                              ),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _roleColor(_selectedRole),
                                          ),
                                        ),
                                        Text(
                                          _selectedCustomRole != null
                                              ? _tr(
                                                  'Saved custom role',
                                                  'Jukumu maalum lililohifadhiwa',
                                                )
                                              : _tr(
                                                  _selectedRole.description,
                                                  _selectedRole.descriptionSw,
                                                ),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Permissions ───────────────────────────────
                          if (_selectedRole == TeamRole.custom &&
                              _selectedCustomRole == null) ...[
                            _sectionLabel(_tr('Permissions', 'Ruhusa')),
                            const SizedBox(height: 10),
                            _PermissionEditor(
                              perms: _customPerms,
                              onChanged: (p) =>
                                  setState(() => _customPerms = p),
                            ),
                            const SizedBox(height: 16),
                            _OwnRecordsOnlyToggle(
                              value: _ownRecordsOnly,
                              onChanged: (v) =>
                                  setState(() => _ownRecordsOnly = v),
                            ),
                            const SizedBox(height: 16),
                          ] else if (_selectedCustomRole != null) ...[
                            _sectionLabel(_tr('Permissions', 'Ruhusa')),
                            const SizedBox(height: 10),
                            _PermissionSummary(
                              role: TeamRole.custom,
                              overridePerms: _selectedCustomRole!.permissions,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tr(
                                'From the "${_selectedCustomRole!.name}" role. '
                                'Edit the role to change these.',
                                'Kutoka jukumu la "${_selectedCustomRole!.name}". '
                                'Hariri jukumu kubadilisha ruhusa hizi.',
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            _PermissionSummary(role: _selectedRole),
                            const SizedBox(height: 16),
                            _OwnRecordsOnlyToggle(
                              value: _ownRecordsOnly,
                              onChanged: (v) =>
                                  setState(() => _ownRecordsOnly = v),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Notes ─────────────────────────────────────
                          OnboardingField(
                            controller: _notesCtrl,
                            label: _tr('Notes (optional)', 'Maelezo (hiari)'),
                            hint: _tr(
                              'Any extra info...',
                              'Maelezo ya ziada...',
                            ),
                            prefix: const Icon(
                              Icons.notes_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Save button ───────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.navyPrimary,
                                elevation: 4,
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.navyPrimary,
                                      ),
                                    )
                                  : Text(
                                      _tr('Add to Team', 'Ongeza kwenye Timu'),
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MEMBER DETAIL / ACTION SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _MemberSheet extends ConsumerStatefulWidget {
  final TeamMember member;

  const _MemberSheet({required this.member});

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  late TeamMember _member;
  bool _editingRole = false;
  bool _editingDetails = false;
  bool _showPerms = false;
  bool _isSaving = false;

  // Only editable while the invite is unaccepted — see the build method.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  TeamRole _pendingRole = TeamRole.cashier;
  Set<AppPermission> _pendingPerms = {};
  DataScope _pendingDataScope = DataScope.all;

  /// Non-null when the owner picked a saved custom role in the change-role
  /// editor. When null while [_pendingRole] is custom, permissions are edited
  /// inline (one-off). Starts null even if the member already has a saved
  /// role — reassigning is an explicit choice.
  CustomRole? _pendingCustomRole;

  /// True once the owner has actually chosen a role in the picker. Until then
  /// we must not rewrite the member's role identity on save — otherwise
  /// opening "Change Role" and hitting Save would silently detach a member
  /// from their saved custom role.
  bool _rolePicked = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _pendingRole = _member.role;
    _pendingPerms = Set.of(_member.customPermissions);
    _pendingDataScope = _member.dataScope;
    _nameCtrl = TextEditingController(text: _member.name);
    _phoneCtrl = TextEditingController(text: _member.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppNotification.info(
        context,
        _tr('Name is required.', 'Jina linahitajika.'),
      );
      return;
    }
    final rawPhone = _phoneCtrl.text.trim();
    final phoneError = OnboardingValidator.validatePhone(rawPhone);
    if (phoneError != null) {
      AppNotification.info(context, phoneError);
      return;
    }
    final normalizedPhone = OnboardingValidator.normalisePhone(rawPhone);
    final storedPhone = normalizedPhone.isNotEmpty ? normalizedPhone : rawPhone;

    if (name == _member.name && storedPhone == _member.phone) {
      setState(() => _editingDetails = false);
      return;
    }

    // Writes the staff doc + the pending-invite lookup doc, both of which must
    // reach the server — same online-only rule as inviting.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception();
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);

      await repo.updateTeamMember(
        uid: user.uid,
        context: ctx,
        memberId: _member.id,
        data: {'name': name, 'phone': storedPhone},
      );

      // Keep the pending-invite lookup doc in step so the member is still
      // found by their (new) phone number at first login.
      try {
        final inviteSnap = await FirebaseFirestore.instance
            .collection('pendingInvites')
            .where('memberId', isEqualTo: _member.id)
            .where('ownerUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        for (final doc in inviteSnap.docs) {
          await doc.reference.update({
            'fullName': name,
            if (normalizedPhone.isNotEmpty) 'phoneNumber': normalizedPhone,
          });
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[editDetails] pendingInvite update: $e');
      }

      // Mirror to Drift so the list reflects the change immediately, matching
      // what the invite flow does.
      try {
        final db = ref.read(appDatabaseProvider);
        final existing = await db.teamDao.getById(_member.id);
        await db.teamDao.upsert(
          TeamMemberMapper.toCompanion(
            _member.copyWith(name: name, phone: storedPhone),
            businessId: ctx.businessId ?? '',
            syncStatus: 'synced',
            createdAtMs:
                existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (_) {
        // Best-effort — the next sync pull will reconcile Drift.
      }

      unawaited(
        AuditLogService().log(
          ownerUid: user.uid,
          businessId: ctx.businessId ?? '',
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberDetailsChanged,
          targetMemberId: _member.id,
          targetName: name,
          previousValue: {'name': _member.name, 'phone': _member.phone},
          newValue: {'name': name, 'phone': storedPhone},
        ),
      );

      if (!mounted) return;
      setState(() {
        _member = _member.copyWith(name: name, phone: storedPhone);
        _isSaving = false;
        _editingDetails = false;
      });
      AppNotification.showVia(
        overlay,
        _tr('Details updated.', 'Maelezo yamesasishwa.'),
        type: AppNotificationType.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppNotification.showVia(
        overlay,
        _tr(
          'Could not update details. Please try again.',
          'Imeshindikana kusasisha maelezo. Jaribu tena.',
        ),
        type: AppNotificationType.error,
      );
    }
  }

  Future<void> _updateMember(Map<String, dynamic> data) async {
    setState(() => _isSaving = true);
    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception();
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo.updateTeamMember(
        uid: user.uid,
        context: ctx,
        memberId: _member.id,
        data: data,
        workerUid: _member.userId,
      );

      // Permissions are now part of the staff doc — updateTeamMember already wrote them.

      // Audit log — best-effort, do not await
      final bizId = ctx.businessId ?? '';

      // Log custom permissions changes (before role changes, to capture both)
      if (data.containsKey('customPermissions')) {
        final previousPerms = _member.customPermissions
            .map((p) => p.name)
            .toList();
        final newPerms =
            (data['customPermissions'] as List?)
                ?.whereType<String>()
                .toList() ??
            previousPerms;
        if (previousPerms != newPerms) {
          unawaited(
            AuditLogService().log(
              ownerUid: user.uid,
              businessId: bizId,
              performedByUid: user.uid,
              performedByName: user.displayName ?? 'Owner',
              action: AuditLogService.permissionsChanged,
              targetMemberId: _member.id,
              targetName: _member.name,
              previousValue: previousPerms,
              newValue: newPerms,
            ),
          );
        }
      }

      if (data.containsKey('role')) {
        unawaited(
          AuditLogService().log(
            ownerUid: user.uid,
            businessId: bizId,
            performedByUid: user.uid,
            performedByName: user.displayName ?? 'Owner',
            action: AuditLogService.roleChanged,
            targetMemberId: _member.id,
            targetName: _member.name,
            previousValue: _member.role.name,
            newValue: data['role'],
          ),
        );
      } else if (data['status'] == 'suspended') {
        unawaited(
          AuditLogService().log(
            ownerUid: user.uid,
            businessId: bizId,
            performedByUid: user.uid,
            performedByName: user.displayName ?? 'Owner',
            action: AuditLogService.memberSuspended,
            targetMemberId: _member.id,
            targetName: _member.name,
          ),
        );
      } else if (data['status'] == 'active') {
        unawaited(
          AuditLogService().log(
            ownerUid: user.uid,
            businessId: bizId,
            performedByUid: user.uid,
            performedByName: user.displayName ?? 'Owner',
            action: AuditLogService.memberActivated,
            targetMemberId: _member.id,
            targetName: _member.name,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _member = _member.copyWith(
          role: data.containsKey('role')
              ? TeamRole.fromString(data['role'] as String)
              : null,
          status: data['status'] as String?,
          dataScope: data.containsKey('dataScope')
              ? DataScope.fromString(data['dataScope'] as String)
              : null,
          customPermissions: data['customPermissions'] is List
              ? (data['customPermissions'] as List)
                  .whereType<String>()
                  .map(AppPermissionX.fromString)
                  .whereType<AppPermission>()
                  .toSet()
              : null,
          customRoleId: data['customRoleId'] is String
              ? data['customRoleId'] as String
              : null,
          customRoleName: data['customRoleName'] is String
              ? data['customRoleName'] as String
              : null,
          clearCustomRole:
              data.containsKey('customRoleId') && data['customRoleId'] is! String,
        );
        _pendingCustomRole = null;
        _isSaving = false;
        _editingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppNotification.showVia(
        overlay,
        _tr(
          'Could not update role. Please try again.',
          'Imeshindikana kusasisha jukumu. Jaribu tena.',
        ),
        type: AppNotificationType.error,
      );
    }
  }

  Future<void> _pickPendingRole() async {
    final sel = await showAppSheet<_RoleSelection>(
      context,
      builder: (_) => _RolePickerSheet(
        currentRole: _pendingRole,
        currentCustomRoleId: _pendingCustomRole?.id ?? _member.customRoleId,
      ),
    );
    if (sel == null || !mounted) return;
    setState(() {
      _rolePicked = true;
      _pendingRole = sel.role;
      _pendingCustomRole = sel.customRole;
      if (sel.customRole != null) {
        _pendingPerms = Set.of(sel.customRole!.permissions);
        // A saved role dictates its own data scope.
        _pendingDataScope = sel.customRole!.dataScope;
      } else if (sel.role != TeamRole.custom) {
        _pendingPerms = Set.of(defaultPermissionsFor(sel.role));
        // _pendingDataScope is left as-is — "own records only" applies to any role.
      }
    });
  }

  void _savePendingRole() {
    final cr = _pendingCustomRole;

    // Untouched saved-role member (owner opened the editor but didn't repick):
    // don't rewrite anything — that would strip the customRoleId linkage.
    if (!_rolePicked && _member.customRoleId != null) {
      setState(() => _editingRole = false);
      return;
    }

    final effectivePerms = cr != null
        ? cr.permissions
        : (_pendingRole == TeamRole.custom
            ? _pendingPerms
            : defaultPermissionsFor(_pendingRole));
    final permNames = effectivePerms.map((p) => p.name).toList();
    // "Own records only" (DataScope.own) can be applied to any role — the sync
    // layer + dashboard scope such a member to their own contribution
    // regardless of the view-all permissions the role also grants.
    final scope = cr != null ? cr.dataScope : _pendingDataScope;

    final data = <String, dynamic>{
      'role': _pendingRole.name,
      'customPermissions': permNames,
      // Keep flat list in sync for isStaffWithAny() rules.
      'permissions': permNames,
      'dataScope': scope.name,
    };
    if (_rolePicked) {
      if (cr != null) {
        data['customRoleId'] = cr.id;
        data['customRoleName'] = cr.name;
      } else {
        data['customRoleId'] = FieldValue.delete();
        data['customRoleName'] = FieldValue.delete();
      }
    }
    _updateMember(data);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Remove Member', 'Ondoa Mwanachama')),
        content: Text(
          _tr(
            'Remove ${_member.name} from the team? This cannot be undone.',
            'Ondoa ${_member.name} kutoka timu? Haiwezi kurejeshwa.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_tr('Remove', 'Ondoa')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Removal erases the member's login server-side — it must reach the server.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception();
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final bizId = ctx.businessId ?? '';
      if (bizId.isEmpty) throw Exception('no business context');

      await _callRemoveTeamMember(businessId: bizId, memberId: _member.id);

      // The staff doc is gone server-side; the incremental team pull only sees
      // upserts, never deletes — hide the row locally right away.
      try {
        await ref.read(appDatabaseProvider).teamDao.softDelete(_member.id);
      } catch (_) {}

      unawaited(
        AuditLogService().log(
          ownerUid: user.uid,
          businessId: bizId,
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberRemoved,
          targetMemberId: _member.id,
          targetName: _member.name,
        ),
      );
      navigator.pop();
      AppNotification.showVia(
        overlay,
        _tr('${_member.name} removed.', '${_member.name} ameondolewa.'),
        type: AppNotificationType.success,
      );
    } catch (e) {
      AppNotification.showVia(
        overlay,
        _removeMemberErrorText(e),
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(_member.role);
    final size = MediaQuery.sizeOf(context);
    final ps = ref.watch(permissionServiceProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SheetHandle(),
            // ── Member hero ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _member.initials,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: rc,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _member.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(_roleIcon(_member.role), size: 12, color: rc),
                            const SizedBox(width: 4),
                            Text(
                              _member.roleLabel(
                                sw: LocalizationService.isSwahili,
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: rc,
                              ),
                            ),
                          ],
                        ),
                        if (_member.email.isNotEmpty)
                          Text(
                            _member.email,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  _StatusBadge(status: _member.status),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Edit details ─────────────────────────────────────
                    // Only while the invite is unaccepted: an active member's
                    // phone is tied to their login, and they manage their own
                    // name/phone from their profile once they've joined.
                    if (ps.isOwner && _member.status == 'pending') ...[
                      _ActionCard(
                        icon: Icons.edit_outlined,
                        color: AppColors.tealAccent,
                        title: _tr('Edit Details', 'Hariri Maelezo'),
                        subtitle: _tr(
                          'Name and phone number',
                          'Jina na namba ya simu',
                        ),
                        trailing: Icon(
                          _editingDetails
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onTap: () => setState(
                          () => _editingDetails = !_editingDetails,
                        ),
                      ),
                      if (_editingDetails) ...[
                        const SizedBox(height: 10),
                        OnboardingField(
                          controller: _nameCtrl,
                          label: _tr('Full Name', 'Jina Kamili'),
                          hint: _tr('Enter full name', 'Ingiza jina kamili'),
                          prefix: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OnboardingField(
                          controller: _phoneCtrl,
                          label: _tr('Phone Number', 'Namba ya Simu'),
                          hint: '+255 700 000 000',
                          keyboardType: TextInputType.phone,
                          prefix: const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.navyPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _tr('Save Details', 'Hifadhi Maelezo'),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],

                    // ── Change role (owner only) ─────────────────────────
                    if (ps.isOwner) ...[
                      _ActionCard(
                        icon: Icons.swap_horiz_rounded,
                        color: AppColors.navyPrimary,
                        title: _tr('Change Role', 'Badilisha Jukumu'),
                        subtitle:
                            _member.roleLabel(sw: LocalizationService.isSwahili),
                        trailing: Icon(
                          _editingRole
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onTap: () =>
                            setState(() => _editingRole = !_editingRole),
                      ),
                      if (_editingRole) ...[
                        const SizedBox(height: 10),
                        _RolePickerButton(
                          role: _pendingRole,
                          customRoleName: _pendingCustomRole?.name ??
                              (_pendingRole == _member.role
                                  ? _member.customRoleName
                                  : null),
                          onTap: _isSaving ? null : _pickPendingRole,
                        ),
                        if (_pendingRole == TeamRole.custom &&
                            _pendingCustomRole == null) ...[
                          const SizedBox(height: 8),
                          _PermissionEditor(
                            perms: _pendingPerms,
                            onChanged: (p) => setState(() => _pendingPerms = p),
                          ),
                          const SizedBox(height: 8),
                          _OwnRecordsOnlyToggle(
                            value: _pendingDataScope == DataScope.own,
                            onChanged: (v) => setState(
                              () => _pendingDataScope = v
                                  ? DataScope.own
                                  : DataScope.all,
                            ),
                          ),
                        ] else if (_pendingCustomRole != null) ...[
                          const SizedBox(height: 8),
                          _PermissionSummary(
                            role: TeamRole.custom,
                            overridePerms: _pendingCustomRole!.permissions,
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          _OwnRecordsOnlyToggle(
                            value: _pendingDataScope == DataScope.own,
                            onChanged: (v) => setState(
                              () => _pendingDataScope =
                                  v ? DataScope.own : DataScope.all,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _savePendingRole,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.navyPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _tr('Save Role', 'Hifadhi Jukumu'),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],

                    // ── View permissions (visible to all) ────────────────
                    _ActionCard(
                      icon: Icons.lock_outline_rounded,
                      color: AppColors.tealAccent,
                      title: _tr('Permissions', 'Ruhusa'),
                      subtitle:
                          '${_member.effectivePermissions.length} ${_tr("active", "amilifu")}',
                      trailing: Icon(
                        _showPerms
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onTap: () => setState(() => _showPerms = !_showPerms),
                    ),
                    if (_showPerms) ...[
                      const SizedBox(height: 10),
                      _PermissionSummary(
                        role: _member.role,
                        overridePerms: _member.role == TeamRole.custom
                            ? _member.customPermissions
                            : null,
                      ),
                    ],

                    // ── Suspend / Activate + Remove (owner only) ─────────
                    if (ps.isOwner) ...[
                      const SizedBox(height: 10),
                      if (_member.status == 'active')
                        _ActionCard(
                          icon: Icons.pause_circle_outline_rounded,
                          color: AppColors.warning,
                          title: _tr('Suspend Member', 'Zuia Mwanachama'),
                          subtitle: _tr(
                            'Temporarily revoke access',
                            'Zuia ufikiaji kwa muda',
                          ),
                          onTap: () => _updateMember({'status': 'suspended'}),
                        )
                      else if (_member.status == 'suspended')
                        _ActionCard(
                          icon: Icons.play_circle_outline_rounded,
                          color: AppColors.success,
                          title: _tr('Activate Member', 'Wezesha Mwanachama'),
                          subtitle: _tr('Restore access', 'Rudisha ufikiaji'),
                          onTap: () => _updateMember({'status': 'active'}),
                        ),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.person_remove_outlined,
                        color: AppColors.error,
                        title: _tr('Remove Member', 'Ondoa Mwanachama'),
                        subtitle: _tr(
                          'Permanently remove from team',
                          'Ondoa kabisa kutoka timu',
                        ),
                        onTap: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role card ──────────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════════════════
// ROLE PICKER SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _RolePickerSheet extends ConsumerStatefulWidget {
  final TeamRole currentRole;
  final String? currentCustomRoleId;

  const _RolePickerSheet({
    required this.currentRole,
    this.currentCustomRoleId,
  });

  @override
  ConsumerState<_RolePickerSheet> createState() => _RolePickerSheetState();
}

class _RolePickerSheetState extends ConsumerState<_RolePickerSheet> {
  // Built-in roles offered here. `owner` is intentionally excluded — it is not
  // assignable to invitees.
  static const _builtInRoles = [
    TeamRole.manager,
    TeamRole.accountant,
    TeamRole.cashier,
    TeamRole.stockClerk,
    TeamRole.custom,
  ];

  Future<void> _confirmDelete(CustomRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Delete Role', 'Futa Jukumu')),
        content: Text(
          _tr(
            'Delete the "${role.name}" role? Members already assigned it keep '
            'their current permissions.',
            'Futa jukumu la "${role.name}"? Wanachama waliopewa tayari '
            'watabaki na ruhusa zao za sasa.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_tr('Delete', 'Futa')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await OnlineGuard.ensureOnline(context)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo.deleteCustomRole(
        uid: user.uid,
        context: ctx,
        roleId: role.id,
      );
    } catch (_) {
      if (mounted) {
        AppNotification.error(
          context,
          _tr('Could not delete role.', 'Imeshindwa kufuta jukumu.'),
        );
      }
    }
  }

  void _openEditor([CustomRole? existing]) {
    showAppSheet<void>(
      context,
      builder: (_) => _CustomRoleEditorSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final size = MediaQuery.sizeOf(context);
    final customRolesAsync = ref.watch(customRolesProvider);

    final sectionLabelStyle = GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
      letterSpacing: 0.4,
    );

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                _tr('Select Role', 'Chagua Jukumu'),
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._builtInRoles.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RoleCard(
                            role: r,
                            selected: widget.currentRole == r &&
                                (r != TeamRole.custom ||
                                    widget.currentCustomRoleId == null),
                            onTap: () => Navigator.of(context)
                                .pop(_RoleSelection(r)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tr('CUSTOM ROLES', 'MAJUKUMU MAALUM'),
                        style: sectionLabelStyle,
                      ),
                      const SizedBox(height: 10),
                      customRolesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, _) => Text(
                          _tr(
                            'Could not load custom roles.',
                            'Imeshindwa kupakia majukumu maalum.',
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                        data: (roles) {
                          if (roles.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _tr(
                                  'No custom roles yet. Create one to reuse '
                                  'across team members.',
                                  'Hakuna majukumu maalum bado. Tengeneza moja '
                                  'ili kulitumia kwa wanachama wengi.',
                                ),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final role in roles)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _CustomRoleRow(
                                    role: role,
                                    selected:
                                        widget.currentCustomRoleId == role.id,
                                    onTap: () => Navigator.of(context).pop(
                                      _RoleSelection(TeamRole.custom, role),
                                    ),
                                    onEdit: () => _openEditor(role),
                                    onDelete: () => _confirmDelete(role),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          _tr(
                            'Create custom role',
                            'Tengeneza jukumu maalum',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Selected-role button (opens the picker) ───────────────────────────────────

class _RolePickerButton extends StatelessWidget {
  final TeamRole role;
  final String? customRoleName;
  final VoidCallback? onTap;

  const _RolePickerButton({
    required this.role,
    this.customRoleName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(role);
    final label = (customRoleName != null && customRoleName!.trim().isNotEmpty)
        ? customRoleName!.trim()
        : _tr(role.label, role.labelSw);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: rc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_roleIcon(role), size: 17, color: rc),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rc,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom-role row in the picker (select / edit / delete) ────────────────────

class _CustomRoleRow extends StatelessWidget {
  final CustomRole role;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomRoleRow({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const rc = AppColors.textSecondary;
    return Container(
      decoration: BoxDecoration(
        color: selected ? rc.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? rc.withValues(alpha: 0.5) : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: rc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 17,
                        color: rc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          Text(
                            _tr(
                              '${role.permissions.length} permissions',
                              'Ruhusa ${role.permissions.length}',
                            ),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textMuted,
            tooltip: _tr('Edit', 'Hariri'),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            tooltip: _tr('Delete', 'Futa'),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM ROLE EDITOR SHEET (create / edit a reusable named role)
// ═════════════════════════════════════════════════════════════════════════════

class _CustomRoleEditorSheet extends ConsumerStatefulWidget {
  final CustomRole? existing;

  const _CustomRoleEditorSheet({this.existing});

  @override
  ConsumerState<_CustomRoleEditorSheet> createState() =>
      _CustomRoleEditorSheetState();
}

class _CustomRoleEditorSheetState
    extends ConsumerState<_CustomRoleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late Set<AppPermission> _perms;
  late bool _ownRecordsOnly;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _perms = Set.of(e?.permissions ?? defaultPermissionsFor(TeamRole.cashier));
    _ownRecordsOnly = e?.dataScope == DataScope.own;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perms.isEmpty) {
      AppNotification.warning(
        context,
        _tr('Select at least one permission.', 'Chagua angalau ruhusa moja.'),
      );
      return;
    }
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);

    final name = _nameCtrl.text.trim();
    final scope = _ownRecordsOnly ? DataScope.own : DataScope.all;
    final permNames = _perms.map((p) => p.name).toList();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final data = <String, dynamic>{
        'name': name,
        'permissions': permNames,
        'dataScope': scope.name,
      };

      var affected = 0;
      if (_isEdit) {
        await repo.updateCustomRole(
          uid: user.uid,
          context: ctx,
          roleId: widget.existing!.id,
          data: data,
        );
        affected = await repo.propagateCustomRole(
          context: ctx,
          roleId: widget.existing!.id,
          roleName: name,
          permissions: permNames,
          dataScope: scope.name,
        );
      } else {
        await repo.addCustomRole(uid: user.uid, context: ctx, data: data);
      }

      navigator.pop();
      final msg = !_isEdit
          ? _tr('"$name" role created.', 'Jukumu la "$name" limetengenezwa.')
          : (affected == 0
              ? _tr('"$name" role updated.', 'Jukumu la "$name" limesasishwa.')
              : _tr(
                  '"$name" role updated — $affected member(s) refreshed.',
                  'Jukumu la "$name" limesasishwa — wanachama $affected '
                  'wamesasishwa.',
                ));
      AppNotification.showVia(
        overlay,
        msg,
        type: AppNotificationType.success,
      );
    } catch (e, st) {
      ErrorReporter.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppNotification.showVia(
        overlay,
        _tr(
          'Could not save role. Please try again.',
          'Imeshindwa kuhifadhi jukumu. Jaribu tena.',
        ),
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SheetHandle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _isEdit
                              ? _tr('Edit Role', 'Hariri Jukumu')
                              : _tr('New Custom Role', 'Jukumu Maalum Jipya'),
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            color: AppColors.navyPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(_tr('Role name', 'Jina la jukumu')),
                      const SizedBox(height: 8),
                      OnboardingField(
                        controller: _nameCtrl,
                        label: _tr('Name *', 'Jina *'),
                        hint: _tr('e.g. Driver', 'mf. Dereva'),
                        autofocus: !_isEdit,
                        prefix: const Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _tr('Name is required.', 'Jina linahitajika.')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(_tr('Permissions', 'Ruhusa')),
                      const SizedBox(height: 10),
                      _PermissionEditor(
                        perms: _perms,
                        onChanged: (p) => setState(() => _perms = p),
                      ),
                      const SizedBox(height: 12),
                      _OwnRecordsOnlyToggle(
                        value: _ownRecordsOnly,
                        onChanged: (v) => setState(() => _ownRecordsOnly = v),
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: 12),
                        Text(
                          _tr(
                            'Saving updates every team member currently '
                            'assigned this role.',
                            'Kuhifadhi kunasasisha kila mwanachama aliye na '
                            'jukumu hili sasa.',
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.navyPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.navyPrimary,
                                  ),
                                )
                              : Text(
                                  _isEdit
                                      ? _tr('Save Changes', 'Hifadhi Mabadiliko')
                                      : _tr('Create Role', 'Tengeneza Jukumu'),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final TeamRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(role);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? rc.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? rc.withValues(alpha: 0.5) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_roleIcon(role), size: 18, color: rc),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(role.label, role.labelSw),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? rc : AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    _tr(role.description, role.descriptionSw),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? rc : AppColors.border,
                  width: 2,
                ),
                color: selected ? rc : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission editor (custom role) ───────────────────────────────────────────

// Restricts a custom-role member to only the records they created (sales,
// expenses) or are assigned to (inventory) instead of everything in the
// business — e.g. a stylist who should see only their own sales, or a
// driver who should see only their own vehicle's collections. See
// DataScope in team_member.dart and firestore.rules.
class _OwnRecordsOnlyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OwnRecordsOnlyToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Own records only', 'Rekodi zake tu'),
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tr(
                    'Sees only sales/expenses they created and inventory '
                        'assigned to them — not the rest of the business.',
                    'Ataona mauzo/matumizi aliyoingiza na bidhaa '
                        'alizopangiwa tu — si biashara nzima.',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PermissionEditor extends StatelessWidget {
  final Set<AppPermission> perms;
  final ValueChanged<Set<AppPermission>> onChanged;

  const _PermissionEditor({required this.perms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AppPermission>>{};
    for (final p in AppPermission.values) {
      groups.putIfAbsent(p.group, () => []).add(p);
    }

    return Column(
      children: groups.entries.map((e) {
        final groupPerms = e.value;
        final allOn = groupPerms.every((p) => perms.contains(p));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Group header with select-all toggle
              InkWell(
                onTap: () {
                  final updated = Set<AppPermission>.of(perms);
                  if (allOn) {
                    updated.removeAll(groupPerms);
                  } else {
                    updated.addAll(groupPerms);
                  }
                  onChanged(updated);
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        e.key,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        allOn
                            ? _tr('All on', 'Zote zimewashwa')
                            : _tr(
                                '${groupPerms.where(perms.contains).length}/${groupPerms.length}',
                                '${groupPerms.where(perms.contains).length}/${groupPerms.length}',
                              ),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: allOn,
                        onChanged: (_) {
                          final updated = Set<AppPermission>.of(perms);
                          if (allOn) {
                            updated.removeAll(groupPerms);
                          } else {
                            updated.addAll(groupPerms);
                          }
                          onChanged(updated);
                        },
                        activeThumbColor: AppColors.navyPrimary,
                        activeTrackColor: AppColors.navyPrimary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, indent: 14, color: AppColors.border),
              ...groupPerms.map((p) {
                final on = perms.contains(p);
                return InkWell(
                  onTap: () {
                    final updated = Set<AppPermission>.of(perms);
                    if (on) {
                      updated.remove(p);
                    } else {
                      updated.add(p);
                    }
                    onChanged(updated);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: on
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: on,
                          onChanged: (_) {
                            final updated = Set<AppPermission>.of(perms);
                            if (on) {
                              updated.remove(p);
                            } else {
                              updated.add(p);
                            }
                            onChanged(updated);
                          },
                          activeThumbColor: AppColors.tealAccent,
                          activeTrackColor: AppColors.tealAccent.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Permission summary (read-only) ─────────────────────────────────────────────

class _PermissionSummary extends StatelessWidget {
  final TeamRole role;
  final Set<AppPermission>? overridePerms;

  const _PermissionSummary({required this.role, this.overridePerms});

  @override
  Widget build(BuildContext context) {
    final perms = overridePerms ?? defaultPermissionsFor(role);
    final groups = <String, List<AppPermission>>{};
    for (final p in AppPermission.values) {
      groups.putIfAbsent(p.group, () => []).add(p);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((e) {
          final granted = e.value.where((p) => perms.contains(p)).toList();
          if (granted.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: granted
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary.withValues(
                              alpha: 0.07,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Action card ────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.success,
      'pending' => AppColors.warning,
      _ => AppColors.textDisabled,
    };
    final label = switch (status) {
      'active' => _tr('Active', 'Amilifu'),
      'pending' => _tr('Pending', 'Inasubiri'),
      _ => _tr('Suspended', 'Imezuiliwa'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String label) => Text(
  label,
  style: GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  ),
);
