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
