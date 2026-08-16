import 'package:flutter/material.dart';

import '../../core/services/localization_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

/// Bell icon + unread badge for the app shell's top bar. Driven by
/// [NotificationService.unreadCountNotifier], which
/// [notificationAggregatorActivatorProvider] keeps in sync — a plain
/// [ValueListenableBuilder] here avoids a second, independent Riverpod
/// subscription to the same count.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCountNotifier,
      builder: (context, count, _) {
        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            backgroundColor: AppColors.yellowBrand,
            textColor: AppColors.navyPrimary,
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          tooltip: LocalizationService.tr(en: 'Notifications', sw: 'Arifa'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        );
      },
    );
  }
}
