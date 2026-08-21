import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import 'app_notification.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Pull-to-refresh with none of [RefreshIndicator]'s "page is loading" feel —
/// no full-width Material spinner, no skeleton flash. Pulling past
/// [triggerDistance] and releasing re-runs [onRefresh] (a sync pull) in the
/// background; the list itself updates in place once the underlying Drift
/// stream picks up the change, same as any other sync trigger. The only
/// feedback is a small badge-sized spinner near the top edge while the pull
/// is in flight — see [triggerSilentSync] for the toast shown on completion.
///
/// This watches the scroll's overscroll at the top edge directly instead of
/// wrapping [RefreshIndicator]. The wrapped scrollable must use a physics
/// that actually overscrolls at the edge — see [silentRefreshPhysics] —
/// since Android's default [ClampingScrollPhysics] never overscrolls, so no
/// pull would ever be detected.
class SilentRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;

  const SilentRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 80,
  });

  @override
  State<SilentRefresh> createState() => _SilentRefreshState();
}

class _SilentRefreshState extends State<SilentRefresh> {
  double _pulled = 0;
  bool _armed = false;
  bool _refreshing = false;

  bool _onNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // Negative overscroll = dragging down past the top edge.
      if (notification.overscroll < 0) {
        _pulled -= notification.overscroll;
        if (!_armed && _pulled >= widget.triggerDistance) {
          _armed = true;
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_armed && !_refreshing) {
        setState(() => _refreshing = true);
        widget.onRefresh().whenComplete(() {
          if (mounted) setState(() => _refreshing = false);
        });
      }
      _pulled = 0;
      _armed = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _refreshing ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    width: 26,
                    height: 26,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.navyPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.yellowBrand),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scroll physics that always allows overscroll (needed for [SilentRefresh]
/// to detect a pull even on Android, where the default physics clamps at the
/// edge instead of bouncing).
const silentRefreshPhysics = AlwaysScrollableScrollPhysics(
  parent: BouncingScrollPhysics(),
);

/// Runs a sync cycle for a [SilentRefresh.onRefresh] callback and reports the
/// outcome via [AppNotification] — the small spinner shows the pull is doing
/// something, this toast confirms what happened once it's done: new data
/// pulled in, already up to date, or the sync failed (offline).
Future<void> triggerSilentSync(BuildContext context, WidgetRef ref) async {
  final service = ref.read(syncServiceProvider);
  await service.syncNow();
  if (!context.mounted) return;

  if (service.lastError != null) {
    AppNotification.error(
      context,
      _tr(
        "Couldn't refresh — check your connection.",
        'Imeshindwa kusasisha — angalia mtandao wako.',
      ),
    );
    return;
  }

  if (service.lastPulledCount > 0) {
    AppNotification.success(
      context,
      _tr(
        'Updated with the latest changes.',
        'Imesasishwa na mabadiliko mapya.',
      ),
    );
  } else {
    AppNotification.info(
      context,
      _tr('Already up to date.', 'Tayari iko sawa.'),
    );
  }
}
