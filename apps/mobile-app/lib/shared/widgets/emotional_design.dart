import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../core/services/motion_service.dart';
import '../../core/theme/app_colors.dart';

enum CompanionMood { calm, focused, excited, celebrating }
enum TapHapticStyle { none, selection, light, medium }
enum EmotionalStatusTone { neutral, success, warning, error }
enum EmotionalLottieScene { onboarding, authWelcome, authVerify, celebrate, dashboard }

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
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        return IgnorePointer(
          child: TickerMode(
            enabled: !reducedMotion,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = reducedMotion ? 0.35 : _controller.value;
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
          ),
        );
      },
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
          boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 10)],
        ),
      ),
    );
  }
}

class EmotionalLottieSpot extends StatelessWidget {
  final EmotionalLottieScene scene;
  final double size;
  final bool repeat;
  final CompanionMood fallbackMood;

  const EmotionalLottieSpot({
    super.key,
    required this.scene,
    this.size = 120,
    this.repeat = true,
    this.fallbackMood = CompanionMood.calm,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return Center(
            child: Icon(
              _staticIcon(scene),
              color: AppColors.primary,
              size: size * 0.5,
            ),
          );
        }

        return SizedBox(
          width: size,
          height: size,
          child: RepaintBoundary(
            child: (_primaryLocalAssetForScene(scene) != null)
                ? Lottie.asset(
                    _primaryLocalAssetForScene(scene)!,
                    repeat: repeat,
                    fit: BoxFit.contain,
                  )
                : Lottie.network(
                    _urlForScene(scene),
                    repeat: repeat,
                    fit: BoxFit.contain,
                    frameRate: FrameRate.max,
                    errorBuilder: (context, error, stackTrace) => Lottie.asset(
                      _fallbackAssetForScene(scene),
                      repeat: repeat,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
        );
      },
    );
  }

  String? _primaryLocalAssetForScene(EmotionalLottieScene scene) {
    switch (scene) {
      case EmotionalLottieScene.dashboard:
        return 'assets/lottie/Appointment booking with smartphone.json';
      case EmotionalLottieScene.onboarding:
        return 'assets/lottie/Revenue.json';
      case EmotionalLottieScene.authVerify:
        return 'assets/lottie/Assistant-Bot.json';
      case EmotionalLottieScene.celebrate:
        return 'assets/lottie/DATA.json';
      case EmotionalLottieScene.authWelcome:
        return null;
    }
  }

  String _urlForScene(EmotionalLottieScene scene) {
    switch (scene) {
      case EmotionalLottieScene.onboarding:
        return 'https://assets9.lottiefiles.com/packages/lf20_xvrofzfk.json';
      case EmotionalLottieScene.authWelcome:
        return 'https://assets10.lottiefiles.com/packages/lf20_puciaact.json';
      case EmotionalLottieScene.authVerify:
        return 'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json';
      case EmotionalLottieScene.celebrate:
        return 'https://assets1.lottiefiles.com/packages/lf20_touohxv0.json';
      case EmotionalLottieScene.dashboard:
        return 'https://app.lottiefiles.com/animation/6a8b31f5-f8e1-4719-a797-62dbb4c21a33';
    }
  }

  String _fallbackAssetForScene(EmotionalLottieScene scene) {
    switch (scene) {
      case EmotionalLottieScene.celebrate:
        return 'assets/lottie/fallback_celebrate.json';
      case EmotionalLottieScene.onboarding:
      case EmotionalLottieScene.authWelcome:
      case EmotionalLottieScene.authVerify:
      case EmotionalLottieScene.dashboard:
        return 'assets/lottie/fallback_minimal.json';
    }
  }

  IconData _staticIcon(EmotionalLottieScene scene) {
    switch (scene) {
      case EmotionalLottieScene.celebrate:
        return Icons.celebration_rounded;
      case EmotionalLottieScene.authVerify:
        return Icons.verified_rounded;
      case EmotionalLottieScene.dashboard:
        return Icons.auto_graph_rounded;
      case EmotionalLottieScene.authWelcome:
      case EmotionalLottieScene.onboarding:
        return Icons.waving_hand_rounded;
    }
  }
}

class EmotionalTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final TapHapticStyle hapticStyle;

  const EmotionalTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.hapticStyle = TapHapticStyle.light,
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
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        return GestureDetector(
          onTapDown: (_) {
            if (!reducedMotion) {
              _setScale(0.97);
            }
            _triggerHaptic(widget.hapticStyle);
          },
          onTapCancel: () => _setScale(1),
          onTapUp: (_) => _setScale(1),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            scale: reducedMotion ? 1 : _scale,
            child: widget.child,
          ),
        );
      },
    );
  }

  void _triggerHaptic(TapHapticStyle style) {
    switch (style) {
      case TapHapticStyle.selection:
        HapticFeedback.selectionClick();
        break;
      case TapHapticStyle.light:
        HapticFeedback.lightImpact();
        break;
      case TapHapticStyle.medium:
        HapticFeedback.mediumImpact();
        break;
      case TapHapticStyle.none:
        break;
    }
  }
}

class EmotionalStatusChip extends StatefulWidget {
  final bool visible;
  final String text;
  final EmotionalStatusTone tone;

  const EmotionalStatusChip({
    super.key,
    required this.visible,
    required this.text,
    this.tone = EmotionalStatusTone.neutral,
  });

  @override
  State<EmotionalStatusChip> createState() => _EmotionalStatusChipState();
}

class _EmotionalStatusChipState extends State<EmotionalStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    final chip = RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _palette(widget.tone).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _palette(widget.tone).withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(widget.tone), size: 16, color: _palette(widget.tone)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _palette(widget.tone),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return chip;
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = 0.88 + (_controller.value * 0.12);
            return Opacity(opacity: pulse, child: child);
          },
          child: chip,
        );
      },
    );
  }

  IconData _icon(EmotionalStatusTone tone) {
    switch (tone) {
      case EmotionalStatusTone.success:
        return Icons.check_circle;
      case EmotionalStatusTone.warning:
        return Icons.bolt;
      case EmotionalStatusTone.error:
        return Icons.error_outline;
      case EmotionalStatusTone.neutral:
        return Icons.circle;
    }
  }

  Color _palette(EmotionalStatusTone tone) {
    switch (tone) {
      case EmotionalStatusTone.success:
        return AppColors.success;
      case EmotionalStatusTone.warning:
        return AppColors.warning;
      case EmotionalStatusTone.error:
        return AppColors.error;
      case EmotionalStatusTone.neutral:
        return AppColors.info;
    }
  }
}

class EmotionalSuccessBurst extends StatefulWidget {
  final int trigger;
  final Color color;

  const EmotionalSuccessBurst({
    super.key,
    required this.trigger,
    this.color = AppColors.success,
  });

  @override
  State<EmotionalSuccessBurst> createState() => _EmotionalSuccessBurstState();
}

class _EmotionalSuccessBurstState extends State<EmotionalSuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant EmotionalSuccessBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MotionService.reducedMotionNotifier,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return IgnorePointer(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withValues(alpha: 0.35), width: 2),
              ),
              child: Icon(Icons.check_rounded, size: 16, color: widget.color),
            ),
          );
        }

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_controller.value);
              final fade = (1 - t).clamp(0.0, 1.0);
              return Opacity(
                opacity: fade,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ring(28 + (24 * t), fade * 0.7),
                    _ring(18 + (16 * t), fade * 0.9),
                    for (final offset in const [
                      Offset(0, -24),
                      Offset(20, -14),
                      Offset(24, 8),
                      Offset(-22, 10),
                      Offset(-18, -16),
                    ])
                      Transform.translate(
                        offset: Offset(offset.dx * (0.6 + t * 0.5), offset.dy * (0.6 + t * 0.5)),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: widget.color.withValues(alpha: fade),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _ring(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.color.withValues(alpha: alpha), width: 2),
      ),
    );
  }
}
