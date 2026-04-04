import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum CompanionMood { calm, focused, excited, celebrating }

class AmbientEmotionBackground extends StatefulWidget {
  final List<Color> palette;
  final double intensity;

  const AmbientEmotionBackground({
    super.key,
    required this.palette,
    this.intensity = 1,
  });

  @override
  State<AmbientEmotionBackground> createState() => _AmbientEmotionBackgroundState();
}

class _AmbientEmotionBackgroundState extends State<AmbientEmotionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return RepaintBoundary(
            child: Stack(
              children: [
                _orb(
                  top: -110 + (18 * t),
                  left: -70,
                  size: 220,
                  color: widget.palette[0].withValues(alpha: 0.12 * widget.intensity),
                ),
                _orb(
                  top: 120,
                  right: -90 + (22 * t),
                  size: 250,
                  color: widget.palette[1].withValues(alpha: 0.1 * widget.intensity),
                ),
                _orb(
                  bottom: -90,
                  left: 70 - (24 * t),
                  size: 210,
                  color: widget.palette[2].withValues(alpha: 0.08 * widget.intensity),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orb({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class EmotionalCompanion extends StatefulWidget {
  final CompanionMood mood;
  final double size;

  const EmotionalCompanion({
    super.key,
    required this.mood,
    this.size = 104,
  });

  @override
  State<EmotionalCompanion> createState() => _EmotionalCompanionState();
}

class _EmotionalCompanionState extends State<EmotionalCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bob = math.sin(_controller.value * math.pi * 2) * 4;
        return Transform.translate(
          offset: Offset(0, bob),
          child: child,
        );
      },
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _moodColors(widget.mood),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _moodColors(widget.mood).first.withValues(alpha: 0.32),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _eye(),
                    const SizedBox(width: 14),
                    _eye(),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: _mouthWidth(widget.mood),
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eye() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  List<Color> _moodColors(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.focused:
        return const [Color(0xFFFEB64C), Color(0xFFF8D45A)];
      case CompanionMood.excited:
        return const [Color(0xFF53C9A8), Color(0xFF7FE7C6)];
      case CompanionMood.celebrating:
        return const [Color(0xFF4FA2FF), Color(0xFF7CC4FF)];
      case CompanionMood.calm:
        return const [Color(0xFFE8BB5A), Color(0xFFF7DCA0)];
    }
  }

  double _mouthWidth(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.focused:
        return 20;
      case CompanionMood.excited:
        return 30;
      case CompanionMood.celebrating:
        return 34;
      case CompanionMood.calm:
        return 24;
    }
  }
}

class EmotionalTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const EmotionalTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<EmotionalTapScale> createState() => _EmotionalTapScaleState();
}

class _EmotionalTapScaleState extends State<EmotionalTapScale> {
  double _scale = 1;

  void _setScale(double value) {
    if (!widget.enabled) return;
    if (_scale != value) {
      setState(() => _scale = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.97),
      onTapCancel: () => _setScale(1),
      onTapUp: (_) => _setScale(1),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
