import 'dart:async';

import 'package:flutter/material.dart';

/// Size-aware image providers shared by the onboarding flow.
///
/// Some source files are several thousand pixels wide. Decoding them at their
/// original size can take long enough for the screen to paint before the image
/// is ready, and consumes considerably more memory than a phone display needs.
/// Using the same resized providers everywhere lets Flutter reuse the decoded
/// images from its image cache.
abstract final class OnboardingImages {
  static const signUpPath = 'assets/Picture/sign_up.webp';

  static const introOfflinePath = 'assets/Picture/offline1.webp';
  static const introInsightsPath = 'assets/Picture/offline2.webp';
  static const introAutomationPath = 'assets/Picture/offline3.webp';
  static const introDebtPath = 'assets/Picture/offline4.webp';
  static const introSecurityPath = 'assets/Picture/offline5.webp';

  static const introPaths = <String>[
    introOfflinePath,
    introInsightsPath,
    introAutomationPath,
    introDebtPath,
    introSecurityPath,
  ];

  // Large enough for a crisp full-screen image on common phones while keeping
  // the decoded carousel set small enough to remain in Flutter's image cache.
  static const cacheWidth = 1440;

  static ImageProvider<Object> provider(String path) =>
      ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(path));

  static ImageProvider<Object> get signUpProvider => provider(signUpPath);

  /// Starts decoding onboarding images without extending the splash duration.
  static void warmCache(BuildContext context) {
    for (final path in <String>[signUpPath, ...introPaths]) {
      unawaited(precacheImage(provider(path), context));
    }
  }
}
