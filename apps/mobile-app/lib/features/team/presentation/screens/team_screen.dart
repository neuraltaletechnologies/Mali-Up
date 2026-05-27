import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../customer/data/customer_providers.dart';
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

  List<TeamMember> _applyFilter(List<TeamMember> all) => switch (_filter) {
        _TeamFilter.all => all,
        _TeamFilter.active =>
          all.where((m) => m.status == 'active').toList(),
        _TeamFilter.pending =>
          all.where((m) => m.status == 'pending').toList(),
        _TeamFilter.suspended =>
          all.where((m) => m.status == 'suspended').toList(),
      };

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.navyPrimary,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          _tr('Add Member', 'Ongeza Mwanachama'),
          style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(_tr('Failed to load team', 'Imeshindikana kupakia timu')),
        ),
        data: (members) {
          final filtered = _applyFilter(members);
          final counts = {
            _TeamFilter.all: members.length,
            _TeamFilter.active:
                members.where((m) => m.status == 'active').length,
            _TeamFilter.pending:
                members.where((m) => m.status == 'pending').length,
            _TeamFilter.suspended:
                members.where((m) => m.status == 'suspended').length,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  _tr('My Team', 'Timu Yangu'),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Stats card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StatsCard(members: members),
              ),
              const SizedBox(height: 14),
              // Filter pills
              _FilterPills(
                selected: _filter,
                counts: counts,
                onSelect: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _MemberCard(
                          member: filtered[i],
                          onTap: () =>
                              _showMemberSheet(context, filtered[i]),
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
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const _InviteMemberSheet(),
    );
  }

  void _showMemberSheet(BuildContext ctx, TeamMember member) {
    showModalBottomSheet<void>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _MemberSheet(member: member),
    );
  }
}

// ── Stats card ─────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final List<TeamMember> members;

  const _StatsCard({required this.members});

  @override
  Widget build(BuildContext context) {
    final active = members.where((m) => m.status == 'active').length;
    final pending = members.where((m) => m.status == 'pending').length;

    // Role breakdown (top 3 roles)
    final roleCount = <TeamRole, int>{};
    for (final m in members) {
      roleCount[m.role] = (roleCount[m.role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyPrimary, AppColors.navySecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatCol(
            label: _tr('Total', 'Jumla'),
            value: '${members.length}',
            color: AppColors.primary,
          ),
          _divider(),
          _StatCol(
            label: _tr('Active', 'Amilifu'),
            value: '$active',
            color: const Color(0xFF6EE7B7),
          ),
          _divider(),
          _StatCol(
            label: _tr('Pending', 'Wanaosubiri'),
            value: '$pending',
            color: pending > 0
                ? const Color(0xFFFCD34D)
                : Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withValues(alpha: 0.12),
      );
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Filter pills ───────────────────────────────────────────────────────────────

class _FilterPills extends StatelessWidget {
  final _TeamFilter selected;
  final Map<_TeamFilter, int> counts;
  final ValueChanged<_TeamFilter> onSelect;

  const _FilterPills(
      {required this.selected,
      required this.counts,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: _TeamFilter.values.map((f) {
          final active = f == selected;
          final count = counts[f] ?? 0;
          final color = f == _TeamFilter.pending
              ? AppColors.warning
              : f == _TeamFilter.suspended
                  ? AppColors.error
                  : f == _TeamFilter.active
                      ? AppColors.success
                      : AppColors.navyPrimary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14),
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? color.withValues(alpha: 0.6)
                        : AppColors.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color:
                              active ? color : AppColors.textMuted,
                        )),
                    if (count > 0 && f != _TeamFilter.all) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: active
                              ? color
                              : AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Member card ────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: rc, width: 3.5),
              top: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rc.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: rc,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
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
                          // Status dot
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
                          Icon(_roleIcon(member.role),
                              size: 12, color: rc),
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
                      // Permission count chip
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
          ),
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.group_outlined,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              filter == _TeamFilter.all
                  ? _tr('No team members yet', 'Bado hakuna wanachama')
                  : _tr('No members in this group',
                      'Hakuna wanachama katika kundi hili'),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr('Tap "Add Member" to invite your first team member.',
                  'Bonyeza "Ongeza Mwanachama" kukaribisha mwanachama wako wa kwanza.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
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

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TeamRole _selectedRole = TeamRole.cashier;
  Set<AppPermission> _customPerms = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customPerms = Set.of(defaultPermissionsFor(TeamRole.cashier));
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(_tr('Enter member name.', 'Ingiza jina la mwanachama.'));
      return;
    }

    final rawPhone = _phoneCtrl.text.trim();
    final normalizedPhone =
        rawPhone.isNotEmpty ? _normalizePhone(rawPhone) : '';

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

      // Write team_member record (for team management UI)
      final memberRef = await repo.addTeamMember(
        uid: user.uid,
        context: ctx,
        data: {
          'name': name,
          'email': _emailCtrl.text.trim(),
          'phone': storedPhone,
          'role': _selectedRole.name,
          'customPermissions': permsToStore.map((p) => p.name).toList(),
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
        final bizName = await repo.getBusinessName(uid: user.uid, context: ctx);
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
          content: Text(_tr(
              'Failed to add member. Try again.',
              'Imeshindikana. Jaribu tena.'))));
    }
  }

  /// Normalises any phone input to E.164 (defaults to Tanzania +255).
  static String _normalizePhone(String raw) {
    final phone = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.isEmpty) return phone;
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('255') && phone.length >= 12) return '+$phone';
    if (phone.startsWith('0') && phone.length >= 9) {
      return '+255${phone.substring(1)}';
    }
    return '+255$phone';
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.95),
      child: Material(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Handle + title
            _handle(),
            _sheetTitle(_tr('Add Team Member', 'Ongeza Mwanachama')),
            const Divider(height: 1, color: AppColors.border),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Name & contact ──────────────────────────────────
                    _sectionLabel(_tr('Member Details', 'Maelezo ya Mwanachama')),
                    const SizedBox(height: 8),
                    _field(
                        ctrl: _nameCtrl,
                        label: _tr('Full Name *', 'Jina Kamili *'),
                        icon: Icons.person_outline_rounded,
                        caps: TextCapitalization.words),
                    const SizedBox(height: 10),
                    _field(
                        ctrl: _emailCtrl,
                        label: _tr('Email', 'Barua pepe'),
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(
                        ctrl: _phoneCtrl,
                        label: _tr('Phone', 'Simu'),
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone),
                    const SizedBox(height: 20),

                    // ── Role selector ───────────────────────────────────
                    _sectionLabel(_tr('Role', 'Jukumu')),
                    const SizedBox(height: 10),
                    ...TeamRole.values.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RoleCard(
                            role: r,
                            selected: _selectedRole == r,
                            onTap: () => _onRoleChanged(r),
                          ),
                        )),
                    const SizedBox(height: 20),

                    // ── Custom permissions ──────────────────────────────
                    if (_selectedRole == TeamRole.custom) ...[
                      _sectionLabel(
                          _tr('Permissions', 'Ruhusa')),
                      const SizedBox(height: 10),
                      _PermissionEditor(
                        perms: _customPerms,
                        onChanged: (p) =>
                            setState(() => _customPerms = p),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Show read-only permission summary
                      _PermissionSummary(
                          role: _selectedRole),
                      const SizedBox(height: 20),
                    ],

                    // ── Notes ───────────────────────────────────────────
                    _field(
                        ctrl: _notesCtrl,
                        label: _tr('Notes (optional)', 'Maelezo (hiari)'),
                        icon: Icons.notes_outlined,
                        maxLines: 2),
                    const SizedBox(height: 24),

                    // ── Save button ─────────────────────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.navyPrimary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
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
                                style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: caps,
        maxLines: maxLines,
        decoration: _dec(label: label, icon: icon),
      );
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
          data: data);
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
          content: Text(_tr('Update failed.', 'Imeshindikana.'))));
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
          uid: user.uid, context: ctx, memberId: _member.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
            '${_member.name} removed.', '${_member.name} ameondolewa.')),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(_tr('Failed to remove.', 'Imeshindikana.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(_member.role);
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      child: Material(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _handle(),
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
                    // ── Change role ──────────────────────────────────────
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
                              : () => _updateMember({
                                    'role': _pendingRole.name,
                                    if (_pendingRole == TeamRole.custom)
                                      'customPermissions': _pendingPerms
                                          .map((p) => p.name)
                                          .toList(),
                                  }),
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

                    // ── View permissions ─────────────────────────────────
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

                    const SizedBox(height: 10),

                    // ── Suspend / Activate ───────────────────────────────
                    if (_member.status == 'active')
                      _ActionCard(
                        icon: Icons.pause_circle_outline_rounded,
                        color: AppColors.warning,
                        title:
                            _tr('Suspend Member', 'Zuia Mwanachama'),
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

                    // ── Remove ───────────────────────────────────────────
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

// ── Shared helpers ─────────────────────────────────────────────────────────────

Widget _handle() => Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(99)),
      ),
    );

Widget _sheetTitle(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(title,
          style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary)),
    );

Widget _sectionLabel(String label) => Text(
      label,
      style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted),
    );

InputDecoration _dec({required String label, required IconData icon}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
