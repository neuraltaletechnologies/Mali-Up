// Result types for the PIN-recovery flow (functions/src/pin_recovery.ts).
//
// Hand-rolled so they compile without build_runner, matching the rest of
// lib/features/onboarding/domain/models/.

/// Outcome of asking the backend to email a recovery link.
enum PinResetRequestStatus {
  /// A link was emailed to the address on file.
  sent,

  /// No deliverable email is on file for this number (also covers "no account"
  /// — the two are deliberately indistinguishable).
  noEmail,

  /// Too many recovery requests for this phone / device. Try again later.
  rateLimited,

  /// Network or server error.
  failed,
}

class PinResetRequestResult {
  const PinResetRequestResult(this.status, {this.maskedEmail});

  final PinResetRequestStatus status;

  /// e.g. `j***s@gmail.com` — present only when [status] is
  /// [PinResetRequestStatus.sent].
  final String? maskedEmail;
}

/// Why a recovery token is not usable.
enum PinResetTokenProblem { invalid, used, expired, error }

class PinResetTokenInfo {
  const PinResetTokenInfo.valid({
    required this.phone,
    required this.maskedEmail,
  }) : isValid = true,
       problem = null;

  const PinResetTokenInfo.invalid(this.problem)
    : isValid = false,
      phone = null,
      maskedEmail = null;

  final bool isValid;
  final PinResetTokenProblem? problem;

  /// Canonical phone number tied to the token — the client needs it to derive
  /// the new Firebase Auth password from the new PIN.
  final String? phone;
  final String? maskedEmail;
}

/// Outcome of submitting a new PIN against a recovery token.
enum PinResetConfirmResult {
  ok,

  /// Token expired / already used / not found — request a fresh link.
  linkNoLongerValid,

  /// Too many failed attempts on this token.
  tooManyAttempts,

  /// Network or server error.
  failed,
}

// ── Code-based recovery (requestPinResetOtp / confirmPinResetOtp) ────────────

/// Outcome of asking the backend to SMS (and email) a PIN reset code.
enum PinResetCodeRequestStatus {
  /// A code went out by SMS and/or email.
  sent,

  /// No account is registered with this number.
  notFound,

  /// Too many codes requested for this phone / device. Try again later.
  rateLimited,

  /// Network or server error.
  failed,
}

class PinResetCodeRequestResult {
  const PinResetCodeRequestResult(
    this.status, {
    this.maskedPhone,
    this.maskedEmail,
  });

  final PinResetCodeRequestStatus status;

  /// e.g. `+255 *** *** 678` — present when [status] is `sent`.
  final String? maskedPhone;

  /// Present only when the code was also emailed.
  final String? maskedEmail;
}

enum PinResetCodeConfirmStatus {
  ok,

  /// The code didn't match — [PinResetCodeConfirmResult.remainingAttempts] left.
  wrongCode,

  /// Code expired, already used, or never requested — request a new one.
  expired,

  /// Too many wrong codes — request a new one.
  tooManyAttempts,

  /// Network or server error.
  failed,
}

class PinResetCodeConfirmResult {
  const PinResetCodeConfirmResult(this.status, {this.remainingAttempts});

  final PinResetCodeConfirmStatus status;
  final int? remainingAttempts;
}
