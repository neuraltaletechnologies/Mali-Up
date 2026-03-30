import 'package:flutter/material.dart';

/// Model representing each onboarding screen
class OnboardingPage {
  final int index;
  final String title;
  final String description;
  final String? emoji; // Using emojis instead of heavy assets
  final IconData? icon;
  final Color? backgroundColor;

  OnboardingPage({
    required this.index,
    required this.title,
    required this.description,
    this.emoji,
    this.icon,
    this.backgroundColor,
  });
}

/// Onboarding screens configuration
final List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    index: 0,
    title: 'Manage Your Business Easily',
    description: 'Track sales, customers, and daily operations in one place',
    emoji: '📊',
    icon: Icons.dashboard_outlined,
  ),
  OnboardingPage(
    index: 1,
    title: 'Track Money & Growth',
    description: 'Monitor income, expenses, and profits in real time with smart analytics',
    emoji: '📈',
    icon: Icons.trending_up_rounded,
  ),
  OnboardingPage(
    index: 2,
    title: 'Control Everything Anywhere',
    description: 'Access your business anytime, anywhere from your mobile device',
    emoji: '☁️',
    icon: Icons.cloud_sync_rounded,
  ),
  OnboardingPage(
    index: 3,
    title: 'Get Started with Malix',
    description: 'Join thousands of African business owners managing their operations smarter',
    emoji: '🚀',
    icon: Icons.rocket_launch_rounded,
  ),
];
