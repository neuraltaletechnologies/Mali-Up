import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the "rate us" prompt: tracks happy-path signals (paid invoices,
/// successful sales) and decides when it's a good moment to softly ask the
/// user to rate Mali Up, then hands off to the OS-native review sheet.
///
/// Design goals:
/// - Never ask on a whim — only after the user has had a delightful moment
///   (a confirmed sale) and has used the app for a few days.
/// - Never ask too often — cooldown between asks, hard cap on lifetime asks.
/// - Never route an unhappy user to the Play Store — a "not really" tap
///   is treated as a dead end for that prompt, not an escalation.
class AppRatingService {
  AppRatingService._();

  static const _kFirstLaunchAt = 'rating_first_launch_at';
  static const _kPositiveSignals = 'rating_positive_signals';
  static const _kLastPromptedAt = 'rating_last_prompted_at';
  static const _kPromptCount = 'rating_prompt_count';
  static const _kHasRated = 'rating_has_rated';

  /// Positive signals required before we even consider asking.
  static const _minSignals = 3;

  /// Minimum time since first launch before we ask.
  static const _minAccountAge = Duration(days: 3);

  /// Minimum time between two prompts.
  static const _cooldown = Duration(days: 60);

  /// Never ask more than this many times in the app's lifetime.
  static const _maxPrompts = 3;

  /// Call once, early (e.g. app startup), to seed the install date.
  static Future<void> recordFirstLaunchIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_kFirstLaunchAt) == null) {
      await prefs.setInt(
        _kFirstLaunchAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Call after a moment worth celebrating — a confirmed/paid sale, a
  /// cleared debt, etc. Cheap: just increments a counter in prefs.
  static Future<void> recordPositiveSignal() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kPositiveSignals) ?? 0;
    await prefs.setInt(_kPositiveSignals, current + 1);
  }

  /// Whether this is a good moment to show the soft-ask dialog.
  static Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHasRated) ?? false) return false;

    final promptCount = prefs.getInt(_kPromptCount) ?? 0;
    if (promptCount >= _maxPrompts) return false;

    final signals = prefs.getInt(_kPositiveSignals) ?? 0;
    if (signals < _minSignals) return false;

    final firstLaunch = prefs.getInt(_kFirstLaunchAt);
    if (firstLaunch == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(firstLaunch),
    );
    if (age < _minAccountAge) return false;

    final lastPrompted = prefs.getInt(_kLastPromptedAt);
    if (lastPrompted != null) {
      final since = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPrompted),
      );
      if (since < _cooldown) return false;
    }

    return true;
  }

  /// Marks that a prompt was just shown (call as soon as the dialog opens).
  static Future<void> recordPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastPromptedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    final count = prefs.getInt(_kPromptCount) ?? 0;
    await prefs.setInt(_kPromptCount, count + 1);
  }

  /// User tapped "I love it" — hand off to the native in-app review sheet
  /// (Android's In-App Review API / iOS's SKStoreReviewController), which
  /// never leaves the app and never confirms whether a review was actually
  /// left. Falls back to the Play Store listing if the native flow can't
  /// be shown on this device.
  static Future<void> requestNativeReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasRated, true);

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing(
        
      );
    }
  }
}
