import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/motion_service.dart';

class AnimatedChart extends StatefulWidget {
  const AnimatedChart({super.key});

  @override
  State<AnimatedChart> createState() => _AnimatedChartState();
}

class _AnimatedChartState extends State<AnimatedChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        final chart = Container(
          width: 280,
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F1FE), Color(0xFFDEE4F5)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF003153).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Revenue',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16C47F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+23%',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16C47F),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(0.4, reducedMotion),
                  _buildBar(0.6, reducedMotion),
                  _buildBar(0.5, reducedMotion),
                  _buildBar(0.8, reducedMotion),
                  _buildBar(0.7, reducedMotion),
                ],
              ),
            ],
          ),
        );

        if (reducedMotion) {
          return chart;
        }

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, -20 * _animation.value),
              child: Opacity(
                opacity: _animation.value,
                child: chart,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBar(double baseHeightFactor, bool reducedMotion) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: reducedMotion ? baseHeightFactor * 80 : baseHeightFactor * 80 * _animationController.value,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16C47F), Color(0xFF0EA85D)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class AnimatedFloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AnimatedFloatingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  State<AnimatedFloatingIcon> createState() => _AnimatedFloatingIconState();
}

class _AnimatedFloatingIconState extends State<AnimatedFloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _floatAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        final icon = Container(
          width: widget.size + 20,
          height: widget.size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.15),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );

        if (reducedMotion) {
          return icon;
        }

        return AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, _) {
            final offsetY = 10 * (2 * (0.5 - (_floatAnimation.value - 0.5).abs()) - 1);
            return Transform.translate(offset: Offset(0, offsetY), child: icon);
          },
        );
      },
    );
  }
}

class PulsingGlowWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final Duration duration;

  const PulsingGlowWidget({
    super.key,
    required this.child,
    required this.glowColor,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulsingGlowWidget> createState() => _PulsingGlowWidgetState();
}

class _PulsingGlowWidgetState extends State<PulsingGlowWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _glowAnimation = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return widget.child;
        }

        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, _) {
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return RadialGradient(
                  radius: _glowAnimation.value,
                  colors: [
                    widget.glowColor.withValues(alpha: 0.3),
                    widget.glowColor.withValues(alpha: 0),
                  ],
                ).createShader(bounds);
              },
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.decelerate),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _started = true);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return widget.child;
        }

        if (!_started) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            );
          },
        );
      },
    );
  }
}

