import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration _kThreshold = Duration(milliseconds: 250);
const Duration _kFade = Duration(milliseconds: 180);

/// Intelligently delays skeleton display to prevent flash-of-loading.
///
/// Rules:
///   - If [isLoading] resolves within [threshold], no skeleton is ever shown.
///   - If [hasExistingData] is true (cached / background-refresh), never shows
///     skeleton — displays [child] immediately.
///   - Once skeleton appears, fades smoothly into [child] when data arrives.
class SmartSkeleton extends StatefulWidget {
  const SmartSkeleton({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.hasExistingData = false,
    this.threshold = _kThreshold,
    this.fadeDuration = _kFade,
  });

  final bool isLoading;
  final bool hasExistingData;
  final Widget skeleton;
  final Widget child;
  final Duration threshold;
  final Duration fadeDuration;

  @override
  State<SmartSkeleton> createState() => _SmartSkeletonState();
}

class _SmartSkeletonState extends State<SmartSkeleton> {
  Timer? _timer;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  @override
  void didUpdateWidget(SmartSkeleton old) {
    super.didUpdateWidget(old);
    _evaluate();
  }

  void _evaluate() {
    final needsSkeleton = widget.isLoading && !widget.hasExistingData;

    if (!needsSkeleton) {
      _timer?.cancel();
      _timer = null;
      if (_showSkeleton) setState(() => _showSkeleton = false);
      return;
    }

    if (_timer != null || _showSkeleton) return;

    _timer = Timer(widget.threshold, () {
      _timer = null;
      if (mounted && widget.isLoading && !widget.hasExistingData) {
        setState(() => _showSkeleton = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showSkeleton
          ? KeyedSubtree(key: const ValueKey('sk'), child: widget.skeleton)
          : KeyedSubtree(key: const ValueKey('ct'), child: widget.child),
    );
  }
}

/// Extension on [AsyncValue] for perceived-performance loading UX.
///
/// Replaces [when] with intelligent skeleton timing:
///   - Data arrives in <250 ms → content shown instantly, no skeleton ever appears.
///   - Data is already cached ([hasValue] while reloading) → show cached content,
///     refresh silently in background, no skeleton.
///   - Data takes >250 ms with no cache → skeleton fades in, then fades out to content.
extension AsyncValueSmartX<T> on AsyncValue<T> {
  Widget smartWhen({
    required Widget Function(T) data,
    Widget Function(Object, StackTrace)? onError,
    required Widget Function() skeleton,
    Duration threshold = _kThreshold,
    Duration fadeDuration = _kFade,
  }) {
    Widget content;

    if (hasValue) {
      content = data(requireValue);
    } else if (hasError) {
      content = onError != null
          ? onError(error!, stackTrace!)
          : const SizedBox.shrink();
    } else {
      content = const SizedBox.shrink();
    }

    return SmartSkeleton(
      isLoading: isLoading,
      hasExistingData: hasValue,
      skeleton: skeleton(),
      threshold: threshold,
      fadeDuration: fadeDuration,
      child: content,
    );
  }
}
