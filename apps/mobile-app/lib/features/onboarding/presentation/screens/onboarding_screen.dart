import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/onboarding_colors.dart';
import '../../models/onboarding_model.dart';
import '../widgets/animated_widgets.dart';

/// Main onboarding experience with 4 screens
/// Includes smooth page transitions and page indicators
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({
    Key? key,
    required this.onOnboardingComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            },
            itemCount: onboardingPages.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(onboardingPages[index]);
            },
          ),

          // Header with skip button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
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

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Empty space for balance
            const SizedBox(width: 40),
            // Page indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: onboardingPages.length,
              effect: const CustomizableEffect(
                activeDotDecoration: DotDecoration(
                  width: 28,
                  height: 8,
                  color: OnboardingColors.primaryDeep,
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
            // Skip button
            if (_currentIndex < onboardingPages.length - 1)
              GestureDetector(
                onTap: () {
                  _pageController.jumpToPage(onboardingPages.length - 1);
                },
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: OnboardingColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else
              const SizedBox(width: 40),
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
              child: _buildTextContent(page),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection(OnboardingPage page) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: page.index.isEven
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OnboardingColors.lightBlue,
                  Color(0xFFFFFFFF),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OnboardingColors.lightGreen,
                  Color(0xFFFFFDF0),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: (page.index.isEven
                    ? OnboardingColors.primaryDeep
                    : OnboardingColors.accentGreen)
                .withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          page.emoji ?? '🚀',
          style: const TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  Widget _buildDashboardIllustration() {
    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingColors.lightBlue,
            Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: OnboardingColors.primaryDeep.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: OnboardingColors.primaryDeep.withOpacity(0.3),
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
          color: color.withOpacity(0.2),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingColors.lightGreen,
            Color(0xFFFFFDF0),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: OnboardingColors.accentGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud icon
          Icon(
            Icons.cloud_sync_rounded,
            size: 80,
            color: OnboardingColors.accentGreen.withOpacity(0.4),
          ),
          // Mobile device
          Positioned(
            bottom: 20,
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                color: OnboardingColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: OnboardingColors.accentGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF0),
            Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: OnboardingColors.primaryDeep.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 60,
            color: OnboardingColors.primaryDeep,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Launch?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: OnboardingColors.primaryDeep,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take control of your business',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: OnboardingColors.textLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(OnboardingPage page) {
    return Column(
      children: [
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: OnboardingColors.textDark,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          page.description,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Action buttons
            if (isLastPage) ...[
              // Register button
              _buildPrimaryButton(
                label: 'Register Business',
                onTap: () {
                  // Navigate to registration
                  widget.onOnboardingComplete();
                },
              ),
              const SizedBox(height: 12),
              // Login button
              _buildSecondaryButton(
                label: 'Already have an account? Login',
                onTap: () {
                  // Navigate to login
                  widget.onOnboardingComplete();
                },
              ),
            ] else ...[
              // Next button
              _buildPrimaryButton(
                label: 'Continue',
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ],
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
              color: OnboardingColors.primaryDeep.withOpacity(0.25),
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
            color: OnboardingColors.primaryDeep.withOpacity(0.3),
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
