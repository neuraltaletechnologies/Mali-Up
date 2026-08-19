import 'package:flutter/material.dart';

/// Pull-to-refresh with no visual "loading" feedback at all — no spinner, no
/// skeleton flash. The pull just re-runs [onRefresh] (a sync pull) in the
/// background; the list updates in place once the underlying Drift stream
/// picks up the change, exactly as it would from any other sync trigger.
///
/// [RefreshIndicator] always paints a Material spinner while its future is
/// pending, which is the "feels like loading" look this widget avoids. This
/// instead watches the scroll's overscroll at the top edge directly: once the
/// user drags past [triggerDistance] and releases, [onRefresh] fires once.
///
/// The wrapped scrollable must use a physics that actually overscrolls at the
/// edge (e.g. [AlwaysScrollableScrollPhysics] wrapping [BouncingScrollPhysics])
/// — Android's default [ClampingScrollPhysics] never overscrolls, so no pull
/// would ever be detected.
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
        _refreshing = true;
        widget.onRefresh().whenComplete(() {
          if (mounted) _refreshing = false;
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
      child: widget.child,
    );
  }
}

/// Scroll physics that always allows overscroll (needed for [SilentRefresh]
/// to detect a pull even on Android, where the default physics clamps at the
/// edge instead of bouncing).
const silentRefreshPhysics = AlwaysScrollableScrollPhysics(
  parent: BouncingScrollPhysics(),
);
