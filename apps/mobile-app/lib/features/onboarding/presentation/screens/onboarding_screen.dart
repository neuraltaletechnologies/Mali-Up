import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/onboarding_colors.dart';
import '../../models/onboarding_model.dart';
import '../widgets/animated_widgets.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';

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
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  void _onSkipTap() {
    HapticFeedback.selectionClick();
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

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _pageController.dispose();
    _exitAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: OnboardingColors.background,
        body: Stack(
          children: [
            const AmbientEmotionBackground(
              palette: [
                OnboardingColors.primaryDeep,
                OnboardingColors.accentGreen,
                AppColors.primaryLight,
              ],
              intensity: 1.1,
            ),
            // Page view for onboarding screens
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
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
            const SizedBox(height: 20),
            EntranceAnimation(
              delay: const Duration(milliseconds: 60),
              child: EmotionalLottieSpot(
                scene: _lottieSceneForPage(page.index),
                size: 160,
                fallbackMood: CompanionMood.calm,
              ),
            ),
            const SizedBox(height: 40),

            // Text content
            EntranceAnimation(
              delay: const Duration(milliseconds: 200),
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
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Container(
          key: ValueKey<bool>(isLastPage),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
         
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey<int>(_currentIndex),
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (!isLastPage)
                      EmotionalTapScale(
                        hapticStyle: TapHapticStyle.selection,
                        onTap: _onSkipTap,
                        child: Text(
                          _tr('Skip', 'Ruka'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isLastPage)
                  _buildPrimaryButton(
                    label: _tr('Let\'s get started', 'Tuanze'),
                    onTap: _onPrimaryTap,
                  ),
                if (isLastPage)
                  const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: ExpandingDotsEffect(
                      expansionFactor: 2.2,
                      spacing: 6,
                      radius: 99,
                      dotHeight: 6,
                      dotWidth: 6,
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return EmotionalTapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  EmotionalLottieScene _lottieSceneForPage(int index) {
    switch (index) {
      case 0:
        return EmotionalLottieScene.dashboard;
      case 1:
        return EmotionalLottieScene.onboarding;
      case 2:
        return EmotionalLottieScene.authVerify;
      case 3:
        return EmotionalLottieScene.celebrate;
      default:
        return EmotionalLottieScene.authWelcome;
    }
  }
}

