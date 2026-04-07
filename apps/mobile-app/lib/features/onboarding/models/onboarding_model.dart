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
    titleEn: 'Everything your business needs, in one place',
    titleSw: 'Kila unachohitaji kwa biashara yako, sehemu moja',
    descriptionEn: 'Sales, stock, and customers, all together and easy to track.',
    descriptionSw: 'Mauzo, stoo na wateja, vyote pamoja na rahisi kufuatilia.',
    icon: Icons.dashboard_outlined,
  ),
  OnboardingPage(
    index: 1,
    titleEn: 'See where every shilling goes',
    titleSw: 'Ona kila shilingi inaenda wapi',
    descriptionEn: 'Follow income, expenses, and cash flow in real time.',
    descriptionSw: 'Fuatilia mapato, matumizi na mzunguko wa fedha kwa wakati halisi.',
    emoji: '📈',
    icon: Icons.trending_up_rounded,
  ),
  OnboardingPage(
    index: 2,
    titleEn: 'Make confident moves with clear insights',
    titleSw: 'Fanya maamuzi kwa kujiamini ukitumia taarifa wazi',
    descriptionEn: 'See what is working and what needs attention.',
    descriptionSw: 'Ona kinachofanya kazi na kinachohitaji kuangaliwa.',
    emoji: '☁️',
    icon: Icons.cloud_sync_rounded,
  ),
  OnboardingPage(
    index: 3,
    titleEn: 'Let\'s get your workspace ready',
    titleSw: 'Tukusaidie kuandaa workspace yako',
    descriptionEn: 'Tell us what matters most in your business, we\'ll set it up.',
    descriptionSw: 'Tuambie kilicho muhimu zaidi kwenye biashara yako, tukuwekee mipangilio.',
    emoji: '🚀',
    icon: Icons.rocket_launch_rounded,
  ),
];
