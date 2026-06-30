import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/services/localization_service.dart';
import '../../core/sync/offline_policy_notifier.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_colors.dart';

/// Subtle connectivity & sync status strip shown just below the app bar.
///
/// Visibility rules:
/// - Hidden when online and no pending changes (idle happy path)
/// - Amber strip  → offline, pending changes ≤ 24 h
/// - Orange strip → offline warning 24–48 h
/// - Red strip    → offline restricted > 48 h (read-only enforced)
/// - Blue strip   → actively syncing
/// - Green strip  → appears for 2 s after sync completes, then hides
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final policy = ref.watch(offlinePolicyProvider);

    final config = _resolveConfig(syncState, pendingCount, policy);

    if (config == null) {
      _controller.reverse();
      return const SizedBox.shrink();
    }

    _controller.forward();

    return FadeTransition(
      opacity: _fade,
      child: _BannerStrip(config: config),
    );
  }

  _BannerConfig? _resolveConfig(
    SyncState syncState,
    int pendingCount,
    OfflinePolicyNotifier policy,
  ) {
    final sw = LocalizationService.isSwahili;

    if (syncState == SyncState.syncing) {
      return _BannerConfig(
        color: AppColors.infoBg,
        textColor: AppColors.info,
        icon: Icons.sync,
        spin: true,
        label: sw ? 'Inasawazisha mabadiliko...' : 'Syncing changes...',
      );
    }

    if (policy.level == OfflineLevel.restricted) {
      return _BannerConfig(
        color: AppColors.errorBg,
        textColor: AppColors.error,
        icon: Icons.wifi_off_rounded,
        spin: false,
        label: sw
            ? 'Hakuna mtandao kwa saa 48+. Huwezi kuandika mpaka uunganike.'
            : 'Offline 48 h+. Read-only until reconnected.',
      );
    }

    if (policy.level == OfflineLevel.warning) {
      final h = policy.offlineDuration.inHours;
      return _BannerConfig(
        color: const Color(0xFFFFF7ED),
        textColor: AppColors.warning,
        icon: Icons.wifi_off_rounded,
        spin: false,
        label: sw
            ? 'Bila mtandao kwa masaa $h. Mabadiliko $pendingCount yanangoja.'
            : 'Offline $h h. $pendingCount change${pendingCount == 1 ? '' : 's'} waiting.',
      );
    }

    if (policy.isOffline || syncState == SyncState.offline) {
      final label = pendingCount > 0
          ? (sw
              ? 'Bila mtandao — mabadiliko $pendingCount yamehifadhiwa.'
              : 'Offline — $pendingCount change${pendingCount == 1 ? '' : 's'} saved locally.')
          : (sw ? 'Bila mtandao — data imehifadhiwa.' : 'Offline — data saved locally.');
      return _BannerConfig(
        color: AppColors.warningBg,
        textColor: AppColors.warning,
        icon: Icons.wifi_off_rounded,
        spin: false,
        label: label,
      );
    }

    if (pendingCount > 0 && syncState == SyncState.idle) {
      return _BannerConfig(
        color: AppColors.warningBg,
        textColor: AppColors.warning,
        icon: Icons.cloud_upload_outlined,
        spin: false,
        label: sw
            ? 'Mabadiliko $pendingCount yanangoja kusawazishwa.'
            : '$pendingCount change${pendingCount == 1 ? '' : 's'} waiting to sync.',
      );
    }

    // All synced, online — banner hidden.
    return null;
  }
}

class _BannerConfig {
  final Color color;
  final Color textColor;
  final IconData icon;
  final bool spin;
  final String label;

  const _BannerConfig({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.spin,
    required this.label,
  });
}

class _BannerStrip extends StatefulWidget {
  final _BannerConfig config;
  const _BannerStrip({required this.config});

  @override
  State<_BannerStrip> createState() => _BannerStripState();
}

class _BannerStripState extends State<_BannerStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.config.spin) _spin.repeat();
  }

  @override
  void didUpdateWidget(_BannerStrip old) {
    super.didUpdateWidget(old);
    if (widget.config.spin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.config.spin && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return Container(
      width: double.infinity,
      color: cfg.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          cfg.spin
              ? RotationTransition(
                  turns: _spin,
                  child: Icon(cfg.icon, size: 14, color: cfg.textColor),
                )
              : Icon(cfg.icon, size: 14, color: cfg.textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cfg.label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: cfg.textColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
