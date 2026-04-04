import 'package:flutter/material.dart';
import '../../core/onboarding_colors.dart';
import '../widgets/animated_widgets.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../core/services/localization_service.dart';

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
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _setupAnimations();
    _scheduleNavigation();
  }

  Future<void> _loadLanguage() async {
    final language = await LocalizationService.getLanguage();
    if (mounted) {
      setState(() => _language = language);
    }
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFFDF3),
            ],
          ),
        ),
        child: SafeArea(
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

                    const SizedBox(height: 34),

                    // Tagline with fade animation
                    _buildTaglineSection(),
                  ],
                ),
              ),

              // Subtle loading cue and bottom accent
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoadingIndicator(),
                      const SizedBox(height: 22),
                      _buildBottomAccent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -72,
          right: -64,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.accentGreen.withOpacity(0.09),
            ),
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -86,
          left: -96,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.primaryDeep.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: 18,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.accentGreen.withOpacity(0.12),
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
                width: 148,
                height: 148,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: OnboardingColors.white,
                  border: Border.all(
                    color: OnboardingColors.accentGreen.withOpacity(0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OnboardingColors.accentGreen.withOpacity(.22),
                      blurRadius: 28,
                      spreadRadius: -8,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: MaliUpLogo(size: 86),
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
                    _tr('MaliUp', 'MaliUp'),
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
                  _tr(
                    'Smart Business Management\nfor Growing Businesses',
                    'Usimamizi Mahususi wa Biashara\nkwa Biashara Zinazokua',
                  )
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
                        color: OnboardingColors.textDark.withOpacity(0.82),
                        fontSize: 16,
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: _animationController.value,
            minHeight: 5,
            backgroundColor: OnboardingColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(
              OnboardingColors.accentGreen,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAccent() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OnboardingColors.accentGreen.withOpacity(0.10),
            OnboardingColors.white.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
