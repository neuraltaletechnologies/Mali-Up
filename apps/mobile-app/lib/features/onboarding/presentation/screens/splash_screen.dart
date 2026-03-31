import 'package:flutter/material.dart';
import '../../core/onboarding_colors.dart';
import '../widgets/animated_widgets.dart';

/// Premium splash screen with animated gradient background
/// Displays MaliUp branding and smooth transition to onboarding
class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({
    super.key,
    required this.onSplashComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _scheduleNavigation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _taglineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  void _scheduleNavigation() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onSplashComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: OnboardingColors.white,
        ),
        child: Stack(
          children: [
            // Animated background circles (decorative)
            _buildBackgroundDecorations(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo area with pulsing glow
                  _buildLogoSection(),

                  const SizedBox(height: 40),

                  // Tagline with fade animation
                  _buildTaglineSection(),
                ],
              ),
            ),

            // Bottom accent
            _buildBottomAccent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.accentGreen.withOpacity(0.08),
            ),
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.primaryDeep.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * _logoAnimation.value),
          child: Opacity(
            opacity: _logoAnimation.value,
            child: PulsingGlowWidget(
              glowColor: OnboardingColors.accentGreen,
              duration: const Duration(milliseconds: 2000),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      OnboardingColors.white,
                      Color(0xFFFAF6F0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          OnboardingColors.accentGreen.withOpacity(.15),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '📱',
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontSize: 60,
                            ) ??
                            const TextStyle(fontSize: 60),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaglineSection() {
    return AnimatedBuilder(
      animation: _taglineAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // App name
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        OnboardingColors.primaryDeep,
                        OnboardingColors.accentGreen,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'MaliUp',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: OnboardingColors.primaryDeep,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          letterSpacing: 1,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  'Smart Business Management\nfor Growing Businesses',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: OnboardingColors.textDark,
                        fontSize: 16,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAccent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OnboardingColors.accentGreen.withOpacity(0.08),
              OnboardingColors.white.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
