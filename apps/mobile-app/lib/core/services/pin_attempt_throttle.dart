import 'package:shared_preferences/shared_preferences.dart';

/// Tracks consecutive failed PIN attempts per namespace+key and enforces an
/// increasing lockout window after too many failures in a row.
///
/// This is a client-side speed bump against automated/scripted PIN guessing
/// through the app UI (there was previously no cooldown at all, so a 4-digit
/// PIN's ~10,000 combinations could be tried back-to-back). It does not
/// replace server-side protection — for Firebase Auth sign-in, Firebase's own
/// per-account rate limiting is the real backstop once this local throttle is
/// bypassed (e.g. by a rooted device clearing app storage).
class PinAttemptThrottle {
  const PinAttemptThrottle(this._namespace);

  final String _namespace;

  static const int maxAttempts = 5;
  static const List<Duration> _lockoutSteps = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  String _attemptsKey(String key) => '${_namespace}_attempts_$key';
  String _lockoutKey(String key) => '${_namespace}_lockout_$key';

  /// Returns how long the caller must still wait, or null if not locked out.
  Future<Duration?> lockoutRemaining([String key = '_default']) async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_lockoutKey(key));
    if (untilMs == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      untilMs,
    ).difference(DateTime.now());
    if (remaining.isNegative) {
      await prefs.remove(_lockoutKey(key));
      await prefs.remove(_attemptsKey(key));
      return null;
    }
    return remaining;
  }

  Future<void> recordFailure([String key = '_default']) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey(key)) ?? 0) + 1;
    await prefs.setInt(_attemptsKey(key), attempts);
    if (attempts >= maxAttempts) {
      final stepIndex = (attempts - maxAttempts).clamp(
        0,
        _lockoutSteps.length - 1,
      );
      final until = DateTime.now().add(_lockoutSteps[stepIndex]);
      await prefs.setInt(_lockoutKey(key), until.millisecondsSinceEpoch);
    }
  }

  Future<void> recordSuccess([String key = '_default']) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey(key));
    await prefs.remove(_lockoutKey(key));
  }
}
