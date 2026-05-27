import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _taglineCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring2Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  bool _hasNavigated = false;

  static const _bg         = Color(0xFF0D1B3E);
  static const _bgMid      = Color(0xFF0F2048);
  static const _yellow     = Color(0xFFFFC107);
  static const _teal       = Color(0xFF1A6E8A);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _initAnimations();
    _scheduleNavigation();
  }

  void _initAnimations() {
    _logoCtrl = AnimationController(
        duration: const Duration(milliseconds: 950), vsync: this);
    _textCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _taglineCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 2400), vsync: this)
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _ring1Scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.1, 0.85, curve: Curves.easeOutCubic)),
    );
    _ring1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.1, 0.6, curve: Curves.easeOut)),
    );
    _ring2Scale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic)),
    );
    _ring2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.2, 0.65, curve: Curves.easeOut)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward().then((_) {
      if (mounted) {
        _textCtrl.forward().then((_) {
          if (mounted) _taglineCtrl.forward();
        });
      }
    });
  }

  void _scheduleNavigation() {
    _checkAuthAndRoute();
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted && !_hasNavigated) _route(authenticated: false);
    });
  }

  Future<void> _checkAuthAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted || _hasNavigated) return;
    try {
      final loggedIn = await PhoneAuthService.isUserLoggedIn();
      if (!mounted || _hasNavigated) return;
      if (loggedIn && PhoneAuthService.currentUser != null) {
        final path =
            await DefaultContextRoutingService.resolveInitialAuthenticatedPath();
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.go(path ?? AppRouter.dashboardPath);
        }
      } else {
        _route(authenticated: false);
      }
    } catch (_) {
      if (mounted && !_hasNavigated) _route(authenticated: false);
    }
  }

  void _route({required bool authenticated}) {
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
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background depth layer
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgMid, _bg],
              ),
            ),
          ),

          // Decorative orb — top right
          Positioned(
            right: -90,
            top: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _teal.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Decorative orb — bottom left
          Positioned(
            left: -70,
            bottom: 60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _yellow.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ─────────────────────────────────────────────────────
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_logoCtrl, _pulseCtrl]),
                  builder: (context, _) {
                    final pulse = _pulseCtrl.value;
                    return FadeTransition(
                      opacity: _logoOpacity,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer breathing ring
                              Opacity(
                                opacity:
                                    (_ring2Opacity.value * (0.4 - pulse * 0.25))
                                        .clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: _ring2Scale.value *
                                      (1.0 + pulse * 0.06),
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _yellow,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Middle glow ring
                              Opacity(
                                opacity: _ring1Opacity.value,
                                child: Transform.scale(
                                  scale: _ring1Scale.value,
                                  child: Container(
                                    width: 124,
                                    height: 124,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _yellow.withValues(alpha: 0.08),
                                      border: Border.all(
                                        color:
                                            _yellow.withValues(alpha: 0.22),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Logo circle
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _yellow,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          _yellow.withValues(alpha: 0.38),
                                      blurRadius: 32,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color:
                                          _yellow.withValues(alpha: 0.15),
                                      blurRadius: 64,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: MaliUpLogo(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 44),

                // ── Brand name ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Text(
                      'Mali Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Tagline ────────────────────────────────────────────────────
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: Text(
                        LocalizationService.tr(
                          en: 'Everything your business needs in one place.',
                          sw: 'Kila kitu biashara yako inahitaji mahali pamoja.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading dots ───────────────────────────────────────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: _LoadingDots(color: _yellow.withValues(alpha: 0.55)),
          ),

          // ── Version badge ──────────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v2.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.18),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading dots ─────────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 1300),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = i / 3.0;
            final t = ((_ctrl.value - phase) % 1.0).clamp(0.0, 1.0);
            final scale = 0.55 + (t < 0.5 ? t : 1.0 - t) * 0.9;
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
