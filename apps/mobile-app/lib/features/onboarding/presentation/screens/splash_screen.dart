import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/phone_auth_service.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../config/routing.dart';

class SplashScreen extends StatefulWidget {
  final bool showLanguageSelection;
  final bool showOnboarding;

  const SplashScreen({
    super.key,
    required this.showLanguageSelection,
    required this.showOnboarding,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _pulseAnim;
  bool _hasNavigated = false;

  static const _navyBg = Color(0xFF003153);
  static const _navyMid = Color(0xFF003153);
  static const _yellowBrand = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _scheduleNavigation();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });
  }

  void _scheduleNavigation() {
    _checkAuthAndNavigate();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && !_hasNavigated) _navigate(authenticated: false);
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _hasNavigated) return;

    try {
      final isLoggedIn = await PhoneAuthService.isUserLoggedIn();
      if (!mounted || _hasNavigated) return;

      if (isLoggedIn && PhoneAuthService.currentUser != null) {
        final path = await DefaultContextRoutingService.resolveInitialAuthenticatedPath();
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.go(path ?? AppRouter.dashboardPath);
        }
      } else {
        _navigate(authenticated: false);
      }
    } catch (_) {
      if (mounted && !_hasNavigated) _navigate(authenticated: false);
    }
  }

  void _navigate({required bool authenticated}) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    if (authenticated) return;
    if (widget.showLanguageSelection) {
      context.go(AppRouter.languageSelectionPath);
    } else if (widget.showOnboarding) {
      context.go(AppRouter.onboardingPath);
    } else {
      context.go(AppRouter.loginPath);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navyBg, _navyMid, Color(0xFF003153)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glow circles
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _yellowBrand.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -60,
              bottom: 100,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with glow
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _pulseController]),
                    builder: (context, _) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow ring
                              Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _yellowBrand.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              // Inner glow ring
                              Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _yellowBrand.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: _yellowBrand.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Logo icon
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _yellowBrand,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _yellowBrand.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(18),
                                child: const MaliUpLogo(size: 52),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // Brand text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              Text(
                                'MALI UP',
                                style: TextStyle(
                                  color: _yellowBrand,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  shadows: [
                                    Shadow(
                                      color: _yellowBrand.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                LocalizationService.tr(
                                  en: 'Run your business with clarity',
                                  sw: 'Endesha biashara yako kwa ufasaha',
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom loading dots
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _LoadingDots(color: _yellowBrand.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final animValue = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (animValue < 0.5
                    ? animValue * 2
                    : (1.0 - animValue) * 2)
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

