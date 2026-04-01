import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _taglineAnimationController;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    // Logo animation: scale and fade in
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeOutBack,
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.7),
      ),
    );

    // Tagline animation: slide up and fade in
    _taglineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _taglineAnimationController,
        curve: const Interval(0.2, 1.0),
      ),
    );

    // Start animations with a delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _logoAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _taglineAnimationController.forward();
          }
        });
      }
    });
  }

  void _navigateToNextScreen() {
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.go(AppRouter.onboardingPath);
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _taglineAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 24),
              _buildTaglineSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: const MaliUpLogo(
          size: 120,
          light: true, // Use light version of the logo for dark background
        ),
      ),
    );
  }

  Widget _buildTaglineSection() {
    return FadeTransition(
      opacity: _taglineFadeAnimation,
      child: SlideTransition(
        position: _taglineSlideAnimation,
        child: const Text(
          'Your Business, Simplified.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
