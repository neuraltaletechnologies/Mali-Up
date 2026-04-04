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
    titleEn: 'Manage Your Business Easily',
    titleSw: 'Simamia Biashara Yako Kwa Urahisi',
    descriptionEn: 'Track sales, customers, and daily operations in one place',
    descriptionSw: 'Fuatilia mauzo, wateja, na shughuli za kila siku mahali pamoja',
    emoji: '📊',
    icon: Icons.dashboard_outlined,
  ),
  OnboardingPage(
    index: 1,
    titleEn: 'Track Money & Growth',
    titleSw: 'Fuatilia Pesa na Ukuaji',
    descriptionEn: 'Monitor income, expenses, and profits in real time with smart analytics',
    descriptionSw: 'Angalia mapato, matumizi, na faida kwa wakati halisi kwa nadharia yenye akili',
    emoji: '📈',
    icon: Icons.trending_up_rounded,
  ),
  OnboardingPage(
    index: 2,
    titleEn: 'Control Everything Anywhere',
    titleSw: 'Chagua Kila Kitu Mahali Popote',
    descriptionEn: 'Access your business anytime, anywhere from your mobile device',
    descriptionSw: 'Pata biashara yako wakati wowote, mahali popote kutoka kwenye simu yako',
    emoji: '☁️',
    icon: Icons.cloud_sync_rounded,
  ),
  OnboardingPage(
    index: 3,
    titleEn: 'Get Started with MaliUp',
    titleSw: 'Anza na MaliUp',
    descriptionEn: 'Join thousands of African business owners managing their operations smarter',
    descriptionSw: 'Jiunge na maelfu ya wamiliki wa biashara wa Afrika wakiosimamia shughuli zao kwa akili',
    emoji: '🚀',
    icon: Icons.rocket_launch_rounded,
  ),
];
