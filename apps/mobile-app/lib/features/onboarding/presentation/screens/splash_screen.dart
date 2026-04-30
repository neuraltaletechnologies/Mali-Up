import 'package:flutter/material.dart';
import '../../core/onboarding_colors.dart';
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
  late final VoidCallback _languageListener;
  AppLanguage _language = AppLanguage.english;
  bool _initializedAnimations = false;

  @override
  void initState() {
    super.initState();
    _language = LocalizationService.languageNotifier.value;
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
    _setupAnimationsIfNeeded();
    _scheduleNavigation();
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  void _setupAnimationsIfNeeded() {
    if (_initializedAnimations) return;
    _initializedAnimations = true;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
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
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      widget.onSplashComplete();
    });
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    if (_initializedAnimations) {
      _animationController.dispose();
    }
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
        Positioned(
          top: 150,
          left: 18,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingColors.accentGreen.withValues(alpha: 0.08),
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
          scale: 0.88 + (0.12 * _logoAnimation.value),
          child: Opacity(
            opacity: _logoAnimation.value,
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: OnboardingColors.white,
                border: Border.all(
                  color: OnboardingColors.accentGreen.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: OnboardingColors.accentGreen.withValues(alpha: 0.10),
                    blurRadius: 16,
                    spreadRadius: -10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: MaliUpLogo(size: 64),
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
                Text(
                  _tr('MaliUp', 'MaliUp'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: OnboardingColors.primaryDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 42,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  _tr(
                    'Run your business with clarity, every day.',
                    'Endesha biashara yako kwa ufasaha, kila siku.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OnboardingColors.textDark.withValues(alpha: 0.82),
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
            OnboardingColors.accentGreen.withValues(alpha: 0.10),
            OnboardingColors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
