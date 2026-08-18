import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/routing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/business_id_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/notification_prefs.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/notification_prefs_provider.dart';
import '../../data/notification_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searchExpanded = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Deliberate user action (opening this screen) is the moment we ask for
    // the OS permission — never at cold start. The in-app list below works
    // regardless of the outcome; only the system tray notification depends
    // on it.
    NotificationService.requestPermission();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    final businessId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
    if (businessId.isEmpty) return;
    await ref
        .read(appDatabaseProvider)
        .notificationLogDao
        .markAllAsRead(businessId);
  }

  Future<void> _onTapItem(NotificationLogTableData item) async {
    await ref.read(appDatabaseProvider).notificationLogDao.markAsRead(item.id);
    if (!mounted) return;
    switch (item.type) {
      case 'low_stock':
        context.go(AppRouter.inventoryPath);
      case 'overdue_debt':
        context.go(AppRouter.debtPath);
      case 'overdue_invoice':
        context.go(AppRouter.salesPath);
      case 'sync_failure':
        context.go(AppRouter.syncDiagnosticsPath);
    }
  }

  void _openSettingsSheet(BuildContext context) {
    showAppSheet<void>(
      context,
      builder: (_) => const _NotificationSettingsSheet(),
    );
  }

  List<NotificationLogTableData> _filter(
      List<NotificationLogTableData> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(notificationLogListProvider);
    final allItems =
        itemsAsync.valueOrNull ?? const <NotificationLogTableData>[];
    final unread = _filter(allItems.where((n) => n.isRead == 0).toList());
    final read = _filter(allItems.where((n) => n.isRead == 1).toList());
    final hasAnyUnread = allItems.any((n) => n.isRead == 0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _NotificationsDarkHeader(
            items: allItems,
            searchCtrl: _searchCtrl,
            query: _query,
            searchExpanded: _searchExpanded,
            onToggleSearch: () => setState(() {
              _searchExpanded = !_searchExpanded;
              if (!_searchExpanded) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
            onSearchChanged: (v) => setState(() => _query = v),
            onSettingsTap: () => _openSettingsSheet(context),
          ),
          const SizedBox(height: HeaderStatsPill.pillHalf + 8),
          if (hasAnyUnread)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _markAllRead,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded,
                          size: 15, color: AppColors.tealAccent),
                      const SizedBox(width: 5),
                      Text(
                        _tr('Mark all read', 'Weka zote kama zimesomwa'),
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: itemsAsync.isLoading && allItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : allItems.isEmpty
                    ? _Empty(query: _query)
                    : (unread.isEmpty && read.isEmpty && _query.isNotEmpty)
                        ? _Empty(query: _query)
                        : CustomScrollView(
                            slivers: [
                              if (unread.isNotEmpty) ...[
                                _SliverSectionLabel(label: _tr('Unread', 'Mapya')),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _NotificationItem(
                                      item: unread[index],
                                      tr: _tr,
                                      isLast: index == unread.length - 1,
                                      onTap: () => _onTapItem(unread[index]),
                                    ),
                                    childCount: unread.length,
                                  ),
                                ),
                              ],
                              if (read.isNotEmpty) ...[
                                _SliverSectionLabel(label: _tr('Earlier', 'Zamani')),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _NotificationItem(
                                      item: read[index],
                                      tr: _tr,
                                      isLast: index == read.length - 1,
                                      onTap: () => _onTapItem(read[index]),
                                    ),
                                    childCount: read.length,
                                  ),
                                ),
                              ],
                              const SliverToBoxAdapter(child: SizedBox(height: 24)),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark Header (mirrors the Inventory/Customer list header: title, search
// toggle in the same position, gear button in the filter button's position
// opening notification settings as a slide-up sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsDarkHeader extends StatelessWidget {
  final List<NotificationLogTableData> items;
  final TextEditingController searchCtrl;
  final String query;
  final bool searchExpanded;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSettingsTap;

  const _NotificationsDarkHeader({
    required this.items,
    required this.searchCtrl,
    required this.query,
    required this.searchExpanded,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onSettingsTap,
  });

  List<HeaderPillStat> _stats() {
    final total = items.length;
    final unread = items.where((n) => n.isRead == 0).length;
    final read = total - unread;

    return [
      HeaderPillStat(
        label: _tr('Jumla', 'Jumla'),
        value: '$total',
        color: AppColors.tealAccent,
      ),
      HeaderPillStat(
        label: _tr('Mapya', 'Mapya'),
        value: '$unread',
        color: unread > 0 ? AppColors.warning : AppColors.success,
      ),
      HeaderPillStat(
        label: _tr('Zamani', 'Zamani'),
        value: '$read',
        color: AppColors.navyPrimary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DarkHeaderShell(
      leading: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _tr('Notifications', 'Arifa'),
        style: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderIconButton(
            icon: searchExpanded ? Icons.close_rounded : Icons.search_rounded,
            active: searchExpanded,
            onTap: onToggleSearch,
          ),
          const SizedBox(width: 10),
          // Settings (gear) button — same position as the Inventory/Customers
          // filter button; opens notification preferences as a slide-up sheet.
          HeaderIconButton(
            icon: Icons.settings_rounded,
            onTap: onSettingsTap,
          ),
        ],
      ),
      expandable: HeaderSearchField(
        controller: searchCtrl,
        autofocus: true,
        onChanged: onSearchChanged,
        hintText: _tr('Search notifications…', 'Tafuta arifa…'),
        showClear: query.isNotEmpty,
      ),
      expanded: searchExpanded,
      pill: HeaderStatsPill(stats: _stats()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification settings — slide-up sheet (moved out of the Settings page)
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationSettingsSheet extends ConsumerWidget {
  const _NotificationSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider).valueOrNull ??
        const NotificationPrefs();
    final controller = ref.read(notificationPrefsControllerProvider);
    void toggle(NotificationPrefs Function(NotificationPrefs) apply) =>
        controller.update(apply);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text(
                _tr('Notification Settings', 'Mipangilio ya Arifa'),
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tr(
                  'Choose which alerts you want to receive',
                  'Chagua arifa unazotaka kupokea',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _SettingCard(
                children: [
                  _SettingTile(
                    icon: Icons.notifications_active_outlined,
                    iconBg: AppColors.tealAccent.withValues(alpha: 0.1),
                    iconColor: AppColors.tealAccent,
                    title: _tr('Enable Notifications', 'Washa Arifa'),
                    subtitle: _tr(
                      'Master switch for all alerts',
                      'Kibadilisha kikuu cha arifa zote',
                    ),
                    trailing: Switch.adaptive(
                      value: prefs.masterEnabled,
                      onChanged: (v) =>
                          toggle((p) => p.copyWith(masterEnabled: v)),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary,
                    ),
                  ),
                  const _TileDivider(),
                  _SettingTile(
                    icon: Icons.inventory_2_outlined,
                    iconBg: AppColors.tealAccent.withValues(alpha: 0.1),
                    iconColor: AppColors.tealAccent,
                    title: _tr('Low Stock Alerts', 'Arifa za Bidhaa Zinazoisha'),
                    trailing: Switch.adaptive(
                      value: prefs.lowStockEnabled,
                      onChanged: prefs.masterEnabled
                          ? (v) => toggle((p) => p.copyWith(lowStockEnabled: v))
                          : null,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary,
                    ),
                  ),
                  const _TileDivider(),
                  _SettingTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconBg: AppColors.warning.withValues(alpha: 0.1),
                    iconColor: AppColors.warning,
                    title: _tr(
                      'Overdue Debt Alerts',
                      'Arifa za Madeni Yaliyochelewa',
                    ),
                    trailing: Switch.adaptive(
                      value: prefs.overdueDebtEnabled,
                      onChanged: prefs.masterEnabled
                          ? (v) =>
                              toggle((p) => p.copyWith(overdueDebtEnabled: v))
                          : null,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary,
                    ),
                  ),
                  const _TileDivider(),
                  _SettingTile(
                    icon: Icons.receipt_long_outlined,
                    iconBg: AppColors.error.withValues(alpha: 0.07),
                    iconColor: AppColors.error,
                    title: _tr(
                      'Overdue Invoice Alerts',
                      'Arifa za Ankara Zilizochelewa',
                    ),
                    trailing: Switch.adaptive(
                      value: prefs.overdueInvoiceEnabled,
                      onChanged: prefs.masterEnabled
                          ? (v) => toggle(
                              (p) => p.copyWith(overdueInvoiceEnabled: v))
                          : null,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary,
                    ),
                  ),
                  const _TileDivider(),
                  _SettingTile(
                    icon: Icons.sync_problem_rounded,
                    iconBg: AppColors.secondary.withValues(alpha: 0.07),
                    iconColor: AppColors.secondary,
                    title: _tr(
                      'Sync Issue Alerts',
                      'Arifa za Matatizo ya Usawazishaji',
                    ),
                    trailing: Switch.adaptive(
                      value: prefs.syncFailureEnabled,
                      onChanged: prefs.masterEnabled
                          ? (v) =>
                              toggle((p) => p.copyWith(syncFailureEnabled: v))
                          : null,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

// ── Divider between tiles ────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

// ── Generic setting row ───────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final String query;
  const _Empty({required this.query});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
            ),
            child: Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery
                ? _tr('No results for "$query"', 'Hakuna matokeo ya "$query"')
                : _tr('No notifications yet', 'Hakuna arifa bado'),
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasQuery
                  ? _tr(
                      'Try searching by a different word.',
                      'Jaribu kutafuta kwa neno tofauti.',
                    )
                  : _tr(
                      "You'll see alerts here for low stock, overdue debts, invoices and sync issues",
                      'Utaona arifa hapa za bidhaa zinazoisha, madeni na ankara zilizochelewa, na matatizo ya usawazishaji',
                    ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverSectionLabel extends StatelessWidget {
  final String label;
  const _SliverSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationLogTableData item;
  final String Function(String en, String sw) tr;
  final bool isLast;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.item,
    required this.tr,
    required this.isLast,
    required this.onTap,
  });

  (IconData, Color) get _iconAndColor {
    switch (item.type) {
      case 'low_stock':
        return (Icons.inventory_2_outlined, AppColors.tealAccent);
      case 'overdue_debt':
        return (Icons.account_balance_wallet_outlined, AppColors.warning);
      case 'overdue_invoice':
        return (Icons.receipt_long_outlined, AppColors.error);
      case 'sync_failure':
        return (Icons.sync_problem_rounded, AppColors.navyPrimary);
      default:
        return (Icons.notifications_outlined, AppColors.textMuted);
    }
  }

  String _relativeTime(int createdAtMs) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return tr('Just now', 'Sasa hivi');
    if (diff.inHours < 1) return tr('${diff.inMinutes}m ago', 'Dakika ${diff.inMinutes} zilizopita');
    if (diff.inDays < 1) return tr('${diff.inHours}h ago', 'Saa ${diff.inHours} zilizopita');
    if (diff.inDays < 7) return tr('${diff.inDays}d ago', 'Siku ${diff.inDays} zilizopita');
    return DateFormat('MMM d, yyyy').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, color) = _iconAndColor;
    final isUnread = item.isRead == 0;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(iconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.yellowBrand,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.body,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _relativeTime(item.createdAt),
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
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 74),
            child: Divider(height: 1, color: AppColors.border, thickness: 0.5),
          ),
      ],
    );
  }
}
