import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_state.freezed.dart';

@freezed
class OtpState with _$OtpState {
  const factory OtpState({
    /// OTP code entered
    required String code,

    /// Number of failed attempts
    required int attempts,

    /// Max allowed attempts before lockout
    @Default(3) int maxAttempts,

    /// Whether account is locked due to too many attempts
    required bool isLocked,

    /// Timestamp when lockout expires (milliseconds since epoch)
    required int lockoutExpiryTime,

    /// Cooldown duration in seconds (30 seconds standard)
    @Default(30) int cooldownDurationSeconds,

    /// OTP expiry time (milliseconds since epoch)
    required int expiryTime,

    /// Whether OTP is expired
    required bool isExpired,

    /// Error message
    required String errorMessage,

    /// Is waiting for server response
    @Default(false) bool isLoading,
  }) = _OtpState;

  const OtpState._();

  /// Check if currently locked
  bool get isCurrentlyLocked =>
      isLocked &&
      DateTime.now().millisecondsSinceEpoch < lockoutExpiryTime;

  /// Get remaining lockout seconds
  int get lockoutRemainingSec {
    if (!isCurrentlyLocked) return 0;
    return ((lockoutExpiryTime - DateTime.now().millisecondsSinceEpoch) / 1000)
        .ceil();
  }

  /// Check if OTP is currently expired
  bool get isCurrentlyExpired =>
      DateTime.now().millisecondsSinceEpoch > expiryTime;

  /// Can user retry
  bool get canRetry => !isCurrentlyLocked && attempts < maxAttempts;

  factory OtpState.initial() {
    final now = DateTime.now();
    return OtpState(
      code: '',
      attempts: 0,
      isLocked: false,
      lockoutExpiryTime: 0,
      expiryTime: now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      isExpired: false,
      errorMessage: '',
    );
  }
}
