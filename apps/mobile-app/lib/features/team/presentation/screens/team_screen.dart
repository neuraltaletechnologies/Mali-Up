import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/list_swipe_card.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/data/repositories/context_firestore_repository.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../onboarding/domain/validators/onboarding_validator.dart';
import '../../../onboarding/presentation/screens/_onboarding_scaffold.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../../rbac/data/rbac_providers.dart';
import '../../data/mappers/team_member_mapper.dart';
import '../../data/team_providers.dart';
import '../../domain/models/team_member.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

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
          .where((m) =>
              m.name.toLowerCase().contains(query) ||
              m.email.toLowerCase().contains(query) ||
              m.phone.contains(query))
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
          ? FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context),
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 3,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                _tr('Add Member', 'Ongeza Mwanachama'),
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
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
              const SizedBox(height: _TeamDarkHeader._pillHalf + 8),
              if (_filter != _TeamFilter.all)
                _ActiveTeamFilterChip(
                  filter: _filter,
                  onRemove: () => setState(() => _filter = _TeamFilter.all),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.builder(
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
            ],
          );
        },
      ),
    );
  }

  void _showInviteSheet(BuildContext ctx) {
    showAppSheet<void>(
      ctx,
      builder: (_) => const _InviteMemberSheet(),
    );
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Remove Member', 'Ondoa Mwanachama'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(_tr(
          'Remove ${member.name} from the team? This cannot be undone.',
          'Ondoa ${member.name} kutoka timu? Haiwezi kurejeshwa.',
        )),
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
    if (confirmed != true) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx2 = await repo.resolveContextForUser(user.uid);
      await repo.deleteTeamMember(uid: user.uid, context: ctx2, memberId: member.id);

      // No memberAccess collection to clean up — permissions now live on the staff doc.

      // Mark the pending invite as cancelled so the phone lookup no longer
      // returns this person as a team member.
      try {
        final inviteSnap = await FirebaseFirestore.instance
            .collection('pendingInvites')
            .where('memberId', isEqualTo: member.id)
            .where('ownerUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        for (final doc in inviteSnap.docs) {
          unawaited(doc.reference.update({'status': 'cancelled'}));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[removeMember] pendingInvite cleanup: $e');
      }

      unawaited(AuditLogService().log(
        ownerUid: user.uid,
        businessId: ctx2.businessId ?? '',
        performedByUid: user.uid,
        performedByName: user.displayName ?? 'Owner',
        action: AuditLogService.memberRemoved,
        targetMemberId: member.id,
        targetName: member.name,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('${member.name} removed.', '${member.name} ameondolewa.')),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.error,
          content: Text(_tr(
            'Could not remove member. Please try again.',
            'Imeshindikana kuondoa mwanachama. Jaribu tena.',
          )),
        ));
      }
    }
  }

  void _showMemberSheet(BuildContext ctx, TeamMember member) {
    showAppSheet<void>(
      ctx,
      builder: (_) => _MemberSheet(member: member),
    );
  }
}

// ── Dark Header ────────────────────────────────────────────────────────────────

class _TeamDarkHeader extends StatefulWidget {
  static const double _pillHalf = 22.0;

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
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
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, top + 16, 20, _TeamDarkHeader._pillHalf + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr('My Team', 'Timu Yangu'),
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Search icon
                  GestureDetector(
                    onTap: widget.onSearchToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.searchExpanded
                            ? AppColors.yellowBrand.withValues(alpha: 0.18)
                            : Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.searchExpanded ? AppColors.yellowBrand : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.searchExpanded ? Icons.close_rounded : Icons.search_rounded,
                        color: widget.searchExpanded ? AppColors.yellowBrand : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter icon
                  GestureDetector(
                    onTap: widget.onFilterTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.activeFilters > 0
                                ? AppColors.yellowBrand.withValues(alpha: 0.18)
                                : Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.activeFilters > 0 ? AppColors.yellowBrand : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: widget.activeFilters > 0 ? AppColors.yellowBrand : Colors.white,
                            size: 20,
                          ),
                        ),
                        if (_alertDotColor != Colors.transparent)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _alertDotColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.navyPrimary, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: widget.searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          onChanged: widget.onSearchChanged,
                          style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _tr(
                              'Search by name, email…',
                              'Tafuta kwa jina, barua pepe…',
                            ),
                            hintStyle: GoogleFonts.dmSans(
                                color: Colors.white54, fontSize: 14),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Colors.white54, size: 18),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -_TeamDarkHeader._pillHalf,
          left: 24,
          right: 24,
          child: Container(
            height: _TeamDarkHeader._pillHalf * 2,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(_TeamDarkHeader._pillHalf),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PillStat(
                  value: '${widget.totalCount}',
                  label: _tr('Members', 'Wanachama'),
                  valueColor: AppColors.tealAccent,
                ),
                const _PillDivider(),
                _PillStat(
                  value: '${widget.activeCount}',
                  label: _tr('Active', 'Amilifu'),
                  valueColor: AppColors.success,
                ),
                const _PillDivider(),
                _PillStat(
                  value: '${widget.pendingCount}',
                  label: _tr('Pending', 'Wanaosubiri'),
                  valueColor: widget.pendingCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PillStat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _PillStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }
}

// ── Filter Sheet ───────────────────────────────────────────────────────────────

class _TeamFilterSheet extends StatefulWidget {
  final _TeamFilter selected;
  final ValueChanged<_TeamFilter> onApply;

  const _TeamFilterSheet({
    required this.selected,
    required this.onApply,
  });

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SheetSectionLabel(_tr('Status', 'Hali')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TeamFilter.values
                  .map((f) => _SortChip(
                        label: f.label,
                        selected: _pick == f,
                        onTap: () => setState(() => _pick = f),
                      ))
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _tr('Apply', 'Tumia'),
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
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
  const _ActiveTeamFilterChip({
    required this.filter,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.navyPrimary.withValues(alpha: 0.20)),
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
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.navyPrimary),
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
                                horizontal: 8, vertical: 3),
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
                                Text(statusLabel,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor)),
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
                            member.role.label,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: rc),
                          ),
                          if (member.email.isNotEmpty) ...[
                            Text('  ·  ',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                            Expanded(
                              child: Text(
                                member.email,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted),
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
                            horizontal: 7, vertical: 2),
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
                              color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
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
            ? _tr('Your team is just you for now',
                'Timu yako ni wewe tu kwa sasa')
            : _tr('No members in this group',
                'Hakuna wanachama katika kundi hili'),
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
  ConsumerState<_InviteMemberSheet> createState() =>
      _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TeamRole _selectedRole = TeamRole.cashier;
  Set<AppPermission> _customPerms = {};
  bool _isSaving = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _customPerms = Set.of(defaultPermissionsFor(TeamRole.cashier));

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(TeamRole r) {
    setState(() {
      _selectedRole = r;
      if (r != TeamRole.custom) {
        _customPerms = Set.of(defaultPermissionsFor(r));
      }
    });
  }

  Future<void> _pickRole(BuildContext context) async {
    final picked = await showAppSheet<TeamRole>(
      context,
      builder: (_) => _RolePickerSheet(current: _selectedRole),
    );
    if (picked != null) _onRoleChanged(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();

    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isNotEmpty) {
      final phoneError = OnboardingValidator.validatePhone(rawPhone);
      if (phoneError != null) {
        _snack(phoneError);
        return;
      }
    }

    final normalizedPhone =
        rawPhone.isNotEmpty ? OnboardingValidator.normalisePhone(rawPhone) : '';

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);

      final permsToStore = _selectedRole == TeamRole.custom
          ? _customPerms
          : defaultPermissionsFor(_selectedRole);

      final storedPhone =
          normalizedPhone.isNotEmpty ? normalizedPhone : rawPhone;

      final permNames = permsToStore.map((p) => p.name).toList();

      // Write team_member record (for team management UI)
      final memberRef = await repo.addTeamMember(
        uid: user.uid,
        context: ctx,
        data: {
          'name': name,
          'email': _emailCtrl.text.trim(),
          'phone': storedPhone,
          'role': _selectedRole.name,
          'customPermissions': permNames,
          // Flat list read by isStaffWithAny() security rules and pointer-doc rule.
          'permissions': permNames,
          'status': 'pending',
          'invitedAt': FieldValue.serverTimestamp(),
          'invitedBy': user.uid,
          if (_notesCtrl.text.trim().isNotEmpty)
            'notes': _notesCtrl.text.trim(),
        },
      );

      // Write pendingInvite for fast phone-based lookup during staff login
      if (normalizedPhone.isNotEmpty) {
        final bizId = ctx.businessId ?? '';
        // Ensure we have a valid businessId; fetch businessName using an explicit context
        final bizName = bizId.isNotEmpty
            ? await repo.getBusinessName(uid: user.uid, context: ResolvedFinanceContext.business(bizId))
            : '';
        await repo.writePendingInvite(
          inviteData: {
            'businessId': bizId,
            'businessName': bizName,
            'fullName': name,
            'phoneNumber': normalizedPhone,
            'email': _emailCtrl.text.trim(),
            'role': _selectedRole.name,
            'invitedBy': user.uid,
            'ownerUid': user.uid,
            'memberId': memberRef.id,
            'status': 'pending',
            'pinCreated': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
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
          email: _emailCtrl.text.trim(),
          phone: storedPhone,
          role: _selectedRole,
          customPermissions: permsToStore,
          status: 'pending',
          invitedAt: DateTime.now(),
          invitedBy: user.uid,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
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
      unawaited(AuditLogService().log(
        ownerUid: user.uid,
        businessId: ctx.businessId ?? '',
        performedByUid: user.uid,
        performedByName: user.displayName ?? 'Owner',
        action: AuditLogService.memberInvited,
        targetMemberId: memberRef.id,
        targetName: name,
        newValue: _selectedRole.name,
      ));

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
            _tr('$name added to the team!', '$name ameongezwa kwenye timu!')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(_tr(
            'Could not add team member. Please try again.',
            'Imeshindikana kuongeza mwanachama. Jaribu tena.'))));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final headingStyle = GoogleFonts.poppins(
      fontSize: 26,
      color: AppColors.navyPrimary,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4,
    );
    final subtitleStyle = GoogleFonts.poppins(
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
                              _tr('Member Details', 'Maelezo ya Mwanachama')),
                          const SizedBox(height: 8),

                          OnboardingField(
                            controller: _nameCtrl,
                            label: _tr('Full Name *', 'Jina Kamili *'),
                            hint: _tr('Enter full name', 'Ingiza jina kamili'),
                            autofocus: true,
                            prefix: const Icon(Icons.person_outline_rounded,
                                size: 18, color: AppColors.textMuted),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? _tr('Name is required.',
                                        'Jina linahitajika.')
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          OnboardingField(
                            controller: _emailCtrl,
                            label: _tr('Email (optional)', 'Barua pepe (hiari)'),
                            hint: _tr('you@example.com', 'jina@mfano.com'),
                            keyboardType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.alternate_email_rounded,
                                size: 18, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),

                          OnboardingField(
                            controller: _phoneCtrl,
                            label: _tr('Phone (optional)', 'Simu (hiari)'),
                            hint: '+255 700 000 000',
                            keyboardType: TextInputType.phone,
                            prefix: const Icon(Icons.phone_outlined,
                                size: 18, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),

                          // ── Role ─────────────────────────────────────
                          _sectionLabel(_tr('Role', 'Jukumu')),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _pickRole(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
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
                                      color: _roleColor(_selectedRole)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_roleIcon(_selectedRole),
                                        size: 18,
                                        color: _roleColor(_selectedRole)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _tr(_selectedRole.label,
                                              _selectedRole.labelSw),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _roleColor(_selectedRole),
                                          ),
                                        ),
                                        Text(
                                          _tr(_selectedRole.description,
                                              _selectedRole.descriptionSw),
                                          style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textMuted, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Permissions ───────────────────────────────
                          if (_selectedRole == TeamRole.custom) ...[
                            _sectionLabel(_tr('Permissions', 'Ruhusa')),
                            const SizedBox(height: 10),
                            _PermissionEditor(
                              perms: _customPerms,
                              onChanged: (p) =>
                                  setState(() => _customPerms = p),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            _PermissionSummary(role: _selectedRole),
                            const SizedBox(height: 16),
                          ],

                          // ── Notes ─────────────────────────────────────
                          OnboardingField(
                            controller: _notesCtrl,
                            label: _tr('Notes (optional)', 'Maelezo (hiari)'),
                            hint: _tr(
                                'Any extra info...', 'Maelezo ya ziada...'),
                            prefix: const Icon(Icons.notes_outlined,
                                size: 18, color: AppColors.textMuted),
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
                                shadowColor:
                                    AppColors.primary.withValues(alpha: 0.3),
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
                                          color: AppColors.navyPrimary))
                                  : Text(
                                      _tr('Add to Team', 'Ongeza kwenye Timu'),
                                      style: GoogleFonts.poppins(
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
  bool _showPerms = false;
  bool _isSaving = false;

  TeamRole _pendingRole = TeamRole.cashier;
  Set<AppPermission> _pendingPerms = {};

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _pendingRole = _member.role;
    _pendingPerms = Set.of(_member.customPermissions);
  }

  Future<void> _updateMember(Map<String, dynamic> data) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
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
          workerUid: _member.userId);

      // Permissions are now part of the staff doc — updateTeamMember already wrote them.

      // Audit log — best-effort, do not await
      final bizId = ctx.businessId ?? '';

      // Log custom permissions changes (before role changes, to capture both)
      if (data.containsKey('customPermissions')) {
        final previousPerms = _member.customPermissions.map((p) => p.name).toList();
        final newPerms = (data['customPermissions'] as List?)
                ?.whereType<String>()
                .toList() ??
            previousPerms;
        if (previousPerms != newPerms) {
          unawaited(AuditLogService().log(
            ownerUid: user.uid,
            businessId: bizId,
            performedByUid: user.uid,
            performedByName: user.displayName ?? 'Owner',
            action: AuditLogService.permissionsChanged,
            targetMemberId: _member.id,
            targetName: _member.name,
            previousValue: previousPerms,
            newValue: newPerms,
          ));
        }
      }

      if (data.containsKey('role')) {
        unawaited(AuditLogService().log(
          ownerUid: user.uid,
          businessId: bizId,
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.roleChanged,
          targetMemberId: _member.id,
          targetName: _member.name,
          previousValue: _member.role.name,
          newValue: data['role'],
        ));
      } else if (data['status'] == 'suspended') {
        unawaited(AuditLogService().log(
          ownerUid: user.uid,
          businessId: bizId,
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberSuspended,
          targetMemberId: _member.id,
          targetName: _member.name,
        ));
      } else if (data['status'] == 'active') {
        unawaited(AuditLogService().log(
          ownerUid: user.uid,
          businessId: bizId,
          performedByUid: user.uid,
          performedByName: user.displayName ?? 'Owner',
          action: AuditLogService.memberActivated,
          targetMemberId: _member.id,
          targetName: _member.name,
        ));
      }
      if (!mounted) return;
      setState(() {
        _member = _member.copyWith(
          role: data.containsKey('role')
              ? TeamRole.fromString(data['role'] as String)
              : null,
          status: data['status'] as String?,
        );
        _isSaving = false;
        _editingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(_tr('Could not update role. Please try again.', 'Imeshindikana kusasisha jukumu. Jaribu tena.'))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Remove Member', 'Ondoa Mwanachama')),
        content: Text(_tr(
            'Remove ${_member.name} from the team? This cannot be undone.',
            'Ondoa ${_member.name} kutoka timu? Haiwezi kurejeshwa.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('Cancel', 'Ghairi'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              child: Text(_tr('Remove', 'Ondoa'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception();
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo.deleteTeamMember(
          uid: user.uid,
          context: ctx,
          memberId: _member.id,
          workerUid: _member.userId);
      unawaited(AuditLogService().log(
        ownerUid: user.uid,
        businessId: ctx.businessId ?? '',
        performedByUid: user.uid,
        performedByName: user.displayName ?? 'Owner',
        action: AuditLogService.memberRemoved,
        targetMemberId: _member.id,
        targetName: _member.name,
      ));
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
            '${_member.name} removed.', '${_member.name} ameondolewa.')),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(_tr('Could not remove member. Please try again.', 'Imeshindikana kuondoa mwanachama. Jaribu tena.'))));
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SheetHandle(),
            // ── Member hero ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                      child: Text(_member.initials,
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: rc)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_member.name,
                            style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(_roleIcon(_member.role),
                                size: 12, color: rc),
                            const SizedBox(width: 4),
                            Text(_member.role.label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: rc)),
                          ],
                        ),
                        if (_member.email.isNotEmpty)
                          Text(_member.email,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted)),
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
                    // ── Change role (owner only) ─────────────────────────
                    if (ps.isOwner) ...[
                      _ActionCard(
                        icon: Icons.swap_horiz_rounded,
                        color: AppColors.navyPrimary,
                        title: _tr('Change Role', 'Badilisha Jukumu'),
                        subtitle: _member.role.label,
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
                        ...TeamRole.values.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RoleCard(
                                role: r,
                                selected: _pendingRole == r,
                                onTap: () =>
                                    setState(() => _pendingRole = r),
                                compact: true,
                              ),
                            )),
                        if (_pendingRole == TeamRole.custom) ...[
                          const SizedBox(height: 8),
                          _PermissionEditor(
                            perms: _pendingPerms,
                            onChanged: (p) =>
                                setState(() => _pendingPerms = p),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    final effectivePerms = _pendingRole == TeamRole.custom
                                        ? _pendingPerms
                                        : defaultPermissionsFor(_pendingRole);
                                    final permNames = effectivePerms.map((p) => p.name).toList();
                                    _updateMember({
                                      'role': _pendingRole.name,
                                      'customPermissions': permNames,
                                      // Keep flat list in sync for isStaffWithAny() rules.
                                      'permissions': permNames,
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.navyPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                                _tr('Save Role', 'Hifadhi Jukumu'),
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700)),
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
                      onTap: () =>
                          setState(() => _showPerms = !_showPerms),
                    ),
                    if (_showPerms) ...[
                      const SizedBox(height: 10),
                      _PermissionSummary(
                          role: _member.role,
                          overridePerms:
                              _member.role == TeamRole.custom
                                  ? _member.customPermissions
                                  : null),
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
                              'Zuia ufikiaji kwa muda'),
                          onTap: () =>
                              _updateMember({'status': 'suspended'}),
                        )
                      else if (_member.status == 'suspended')
                        _ActionCard(
                          icon: Icons.play_circle_outline_rounded,
                          color: AppColors.success,
                          title: _tr(
                              'Activate Member', 'Wezesha Mwanachama'),
                          subtitle:
                              _tr('Restore access', 'Rudisha ufikiaji'),
                          onTap: () => _updateMember({'status': 'active'}),
                        ),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.person_remove_outlined,
                        color: AppColors.error,
                        title: _tr('Remove Member', 'Ondoa Mwanachama'),
                        subtitle: _tr(
                            'Permanently remove from team',
                            'Ondoa kabisa kutoka timu'),
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

class _RolePickerSheet extends StatelessWidget {
  final TeamRole current;

  const _RolePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                _tr('Select Role', 'Chagua Jukumu'),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...TeamRole.values.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RoleCard(
                      role: r,
                      selected: current == r,
                      onTap: () => Navigator.of(context).pop(r),
                    ),
                  )),
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
  final bool compact;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(role);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: compact ? 10 : 14),
        decoration: BoxDecoration(
          color: selected
              ? rc.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? rc.withValues(alpha: 0.5)
                : AppColors.border,
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
                    role.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? rc : AppColors.navyPrimary,
                    ),
                  ),
                  if (!compact)
                    Text(
                      role.description,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted),
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
                    width: 2),
                color: selected ? rc : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permission editor (custom role) ───────────────────────────────────────────

class _PermissionEditor extends StatelessWidget {
  final Set<AppPermission> perms;
  final ValueChanged<Set<AppPermission>> onChanged;

  const _PermissionEditor(
      {required this.perms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AppPermission>>{};
    for (final p in AppPermission.values) {
      groups.putIfAbsent(p.group, () => []).add(p);
    }

    return Column(
      children: groups.entries.map((e) {
        final groupPerms = e.value;
        final allOn =
            groupPerms.every((p) => perms.contains(p));
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text(e.key,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary)),
                      const Spacer(),
                      Text(
                        allOn
                            ? _tr('All on', 'Zote zimewashwa')
                            : _tr(
                                '${groupPerms.where(perms.contains).length}/${groupPerms.length}',
                                '${groupPerms.where(perms.contains).length}/${groupPerms.length}'),
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted),
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
                        activeTrackColor:
                            AppColors.navyPrimary.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                  height: 1, indent: 14, color: AppColors.border),
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
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(p.label,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: on
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted)),
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
                          activeTrackColor: AppColors.tealAccent
                              .withValues(alpha: 0.3),
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
          final granted =
              e.value.where((p) => perms.contains(p)).toList();
          if (granted.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: granted
                      .map((p) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary
                                  .withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p.label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.navyPrimary)),
                          ))
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
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
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
                    Text(title,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 18),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
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
          color: AppColors.textMuted),
    );

