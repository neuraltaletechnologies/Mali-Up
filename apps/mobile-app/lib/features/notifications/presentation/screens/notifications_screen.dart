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
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  void initState() {
    super.initState();
    // Deliberate user action (opening this screen) is the moment we ask for
    // the OS permission — never at cold start. The in-app list below works
    // regardless of the outcome; only the system tray notification depends
    // on it.
    NotificationService.requestPermission();
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

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(notificationLogListProvider);
    final items = itemsAsync.valueOrNull ?? const <NotificationLogTableData>[];
    final unread = items.where((n) => n.isRead == 0).toList();
    final read = items.where((n) => n.isRead == 1).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppColors.navyPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _tr('Notifications', 'Arifa'),
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            actions: [
              if (unread.isNotEmpty)
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(
                    _tr('Mark all read', 'Weka zote kama zimesomwa'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ),
            ],
          ),
          if (itemsAsync.isLoading && items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
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
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tr('No notifications yet', 'Hakuna arifa bado'),
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
                        _tr(
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
              ),
            )
          else ...[
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
