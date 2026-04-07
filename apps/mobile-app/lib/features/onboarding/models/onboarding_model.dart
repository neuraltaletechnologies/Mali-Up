import 'package:flutter/material.dart';

/// Model representing each onboarding screen with bilingual support
class OnboardingPage {
  final int index;
  final String titleEn;
  final String titleSw;
  final String descriptionEn;
  final String descriptionSw;
  final String? emoji; // Using emojis instead of heavy assets
  final IconData? icon;
  final Color? backgroundColor;

  OnboardingPage({
    required this.index,
    required this.titleEn,
    required this.titleSw,
    required this.descriptionEn,
    required this.descriptionSw,
    this.emoji,
    this.icon,
    this.backgroundColor,
  });

  /// Get title based on language
  String getTitle(bool isSwahili) => isSwahili ? titleSw : titleEn;

  /// Get description based on language
  String getDescription(bool isSwahili) => isSwahili ? descriptionSw : descriptionEn;
}

/// Onboarding screens configuration with bilingual content
final List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    index: 0,
    titleEn: 'Run Your Business In One Place',
    titleSw: 'Endesha Biashara Yako Mahali Pamoja',
    descriptionEn: 'Sales, stock, and customers. All in one workspace.',
    descriptionSw: 'Mauzo, stoo, na wateja. Yote katika sehemu moja.',
    emoji: '📊',
    icon: Icons.dashboard_outlined,
  ),
  OnboardingPage(
    index: 1,
    titleEn: 'Track Every Shilling',
    titleSw: 'Fuatilia Kila Shilingi',
    descriptionEn: 'See income, expenses, and cash flow in real time.',
    descriptionSw: 'Ona mapato, matumizi, na mzunguko wa fedha kwa wakati halisi.',
    emoji: '📈',
    icon: Icons.trending_up_rounded,
  ),
  OnboardingPage(
    index: 2,
    titleEn: 'Grow With Smart Insights',
    titleSw: 'Kua Kwa Taarifa Za Akili',
    descriptionEn: 'Discover trends and make better decisions faster.',
    descriptionSw: 'Gundua mwelekeo na fanya maamuzi bora kwa haraka.',
    emoji: '☁️',
    icon: Icons.cloud_sync_rounded,
  ),
  OnboardingPage(
    index: 3,
    titleEn: 'Welcome to Malix',
    titleSw: 'Karibu Malix',
    descriptionEn: 'Let us personalize your workspace in under a minute.',
    descriptionSw: 'Tukupangie workspace yako binafsi ndani ya dakika moja.',
    emoji: '🚀',
    icon: Icons.rocket_launch_rounded,
  ),
];
