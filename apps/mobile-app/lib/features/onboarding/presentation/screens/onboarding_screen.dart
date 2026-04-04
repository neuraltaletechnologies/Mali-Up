import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/onboarding_colors.dart';
import '../../models/onboarding_model.dart';
import '../widgets/animated_widgets.dart';
import '../../../../core/services/localization_service.dart';

/// Main onboarding experience with 4 screens
/// Includes smooth page transitions and page indicators
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({
    super.key,
    required this.onOnboardingComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _exitAnimationController;
  late final VoidCallback _languageListener;
  late AppLanguage _language;
  
  int _currentIndex = 0;
  late Timer _autoAdvanceTimer;
  bool _timerActive = false;

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
    _pageController = PageController();
    _exitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start auto-advance timer (5 seconds per page)
    _startAutoAdvance();
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  void _startAutoAdvance() {
    _stopAutoAdvance();
    _timerActive = true;
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < onboardingPages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _stopAutoAdvance();
      }
    });
  }

  void _stopAutoAdvance() {
    if (_timerActive) {
      _autoAdvanceTimer.cancel();
      _timerActive = false;
    }
  }

  void _restartAutoAdvanceIfNeeded() {
    if (_currentIndex < onboardingPages.length - 1) {
      _startAutoAdvance();
    } else {
      _stopAutoAdvance();
    }
  }

  void _onSkipTap() {
    HapticFeedback.selectionClick();
    _stopAutoAdvance();
    _pageController.animateToPage(
      onboardingPages.length - 1,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPrimaryTap() {
    HapticFeedback.lightImpact();
    widget.onOnboardingComplete();
  }

  void _onSecondaryTap() {
    HapticFeedback.selectionClick();
    widget.onOnboardingComplete();
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _pageController.dispose();
    _exitAnimationController.dispose();
    _stopAutoAdvance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: Stack(
        children: [
          // Page view for onboarding screens
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _restartAutoAdvanceIfNeeded();
            },
            itemCount: onboardingPages.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? _currentIndex.toDouble())
                      : _currentIndex.toDouble();
                  final delta = (index - page);
                  final parallaxX = (delta * 28).clamp(-28.0, 28.0);

                  return Transform.translate(
                    offset: Offset(parallaxX, 0),
                    child: child,
                  );
                },
                child: _buildOnboardingPage(onboardingPages[index]),
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Icon/Emoji with animation
            EntranceAnimation(
              delay: Duration.zero,
              child: _buildIconSection(page),
            ),
            const SizedBox(height: 40),

            // Dynamic content based on page
            if (page.index == 1)
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: AnimatedChart(),
              )
            else if (page.index == 0)
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: _buildDashboardIllustration(),
              )
            else if (page.index == 2)
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: _buildCloudSyncIllustration(),
              )
            else
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: _buildCTAIllustration(),
              ),

            const SizedBox(height: 50),

            // Text content
            EntranceAnimation(
              delay: const Duration(milliseconds: 400),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildTextContent(page),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection(OnboardingPage page) {
    return Text(
      page.emoji ?? '🚀',
      style: const TextStyle(fontSize: 56),
    );
  }

  Widget _buildDashboardIllustration() {
    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
          width: 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: OnboardingColors.primaryDeep.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Stat boxes
          Row(
            children: [
              Expanded(
                child: _buildStatBox('12,500', 'Sales', Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox('345', 'Clients', OnboardingColors.primaryDeep),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatBox('28', 'Products', OnboardingColors.accentGreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox('92+', 'Orders', Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: OnboardingColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: OnboardingColors.textLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncIllustration() {
    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
          width: 0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cloud_sync_rounded,
            size: 80,
            color: OnboardingColors.accentGreen.withValues(alpha: 0.4),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                color: OnboardingColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: OnboardingColors.accentGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: OnboardingColors.accentGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAIllustration() {
    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
          width: 0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 60,
              color: OnboardingColors.primaryDeep,
            ),
            const SizedBox(height: 16),
            Text(
              _tr(
                'Ready to Launch?',
                'Tayari Kuanza?',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: OnboardingColors.primaryDeep,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'Take control of your business',
                'Chukua udhibiti wa biashara yako',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OnboardingColors.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(OnboardingPage page) {
    final isSwahili = _language == AppLanguage.swahili;
    return Column(
      key: ValueKey<int>(page.index),
      children: [
        Text(
          page.getTitle(isSwahili),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: OnboardingColors.textDark,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          page.getDescription(isSwahili),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: OnboardingColors.textLight,
                height: 1.6,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    bool isLastPage = _currentIndex == onboardingPages.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: OnboardingColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OnboardingColors.divider),
            boxShadow: [
              BoxShadow(
                color: OnboardingColors.primaryDeep.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isLastPage ? _tr('Ready to continue', 'Tayari kuendelea') : _tr('Auto sliding onboarding', 'Kuweka pepe zisizokamatia'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: OnboardingColors.textLight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (!isLastPage)
                    GestureDetector(
                      onTap: _onSkipTap,
                      child: Text(
                        _tr('Skip', 'Ruka'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: OnboardingColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SmoothPageIndicator(
                controller: _pageController,
                count: onboardingPages.length,
                effect: const CustomizableEffect(
                  activeDotDecoration: DotDecoration(
                    width: 28,
                    height: 8,
                    color: OnboardingColors.accentGreen,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  dotDecoration: DotDecoration(
                    width: 8,
                    height: 8,
                    color: OnboardingColors.divider,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  spacing: 6,
                ),
              ),
              const SizedBox(height: 20),
              if (isLastPage) ...[
                _buildPrimaryButton(
                  label: _tr('Register Business', 'Jisajili Biashara'),
                  onTap: _onPrimaryTap,
                ),
                const SizedBox(height: 12),
                _buildSecondaryButton(
                  label: _tr('Already have an account? Login', 'Una akaunti tayari? Ingia'),
                  onTap: _onSecondaryTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OnboardingColors.primaryDeep,
              OnboardingColors.accentGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: OnboardingColors.primaryDeep.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OnboardingColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: OnboardingColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: OnboardingColors.primaryDeep.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OnboardingColors.primaryDeep,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      ),
    );
  }
}
