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

  /// Positive signals (completed sales) required before we even consider
  /// asking — enough that the user has actually got value from the app,
  /// not just finished setup.
  static const _minSignals = 3;

  /// The app must have been installed at least this long — never on day one.
  static const _minAgeForSalesPath = Duration(days: 2);

  /// The "never asked yet" path for long-term users who don't record sales
  /// (e.g. expense/stock-only) — only once they've clearly stuck around.
  static const _minAgeForReturningPath = Duration(days: 7);

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

  /// True once the install is at least [age] old.
  static bool _installedFor(SharedPreferences prefs, Duration age) {
    final first = prefs.getInt(_kFirstLaunchAt);
    if (first == null) return false;
    return DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(first),
        ) >=
        age;
  }

  /// Whether to prompt a returning / continuing user on app open.
  ///
  /// Fires **once** for a user who has never seen the review dialog, even
  /// with fewer sales than [shouldPrompt] needs — but only after
  /// [_minAgeForReturningPath] of use, so a brand-new user finishing setup
  /// is never asked. After it fires it is subject to the normal cooldown
  /// and prompt-count cap.
  static Future<bool> shouldPromptReturningUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHasRated) ?? false) return false;
    if (!_installedFor(prefs, _minAgeForReturningPath)) return false;

    final promptCount = prefs.getInt(_kPromptCount) ?? 0;
    // Only fire this path if they have *never* been prompted at all.
    if (promptCount > 0) return false;

    // Also skip if the cooldown is still active (belt-and-suspenders).
    final lastPrompted = prefs.getInt(_kLastPromptedAt);
    if (lastPrompted != null) {
      final since = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPrompted),
      );
      if (since < _cooldown) return false;
    }

    return true;
  }

  /// Whether this is a good moment to show the soft-ask dialog.
  static Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHasRated) ?? false) return false;

    final promptCount = prefs.getInt(_kPromptCount) ?? 0;
    if (promptCount >= _maxPrompts) return false;

    final signals = prefs.getInt(_kPositiveSignals) ?? 0;
    if (signals < _minSignals) return false;
    if (!_installedFor(prefs, _minAgeForSalesPath)) return false;

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
      // No appStoreId passed: Android resolves the Play listing from the
      // package name alone. Add appStoreId once the iOS App Store id exists.
      await inAppReview.openStoreListing();
    }
  }
}
