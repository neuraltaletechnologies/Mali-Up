import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Derives the Firebase Auth password used behind the scenes for PIN login.
///
/// A 4-digit PIN only has 10,000 possible values, so this derivation cannot
/// by itself make PIN login resistant to brute force — that protection comes
/// from app-level attempt throttling (see `SecurityService`/`PinAttemptGuard`)
/// and Firebase's own per-account rate limiting. What this function fixes is
/// the previous scheme (`'MaliUp#$pin@2026'`), which was a single fixed
/// template shared by every account: knowing the algorithm let anyone
/// recompute *any* user's password from the PIN alone, with no per-account
/// variation at all. Salting with the phone number ties the derived password
/// to the specific account, and HMAC-SHA256 avoids a literal, greppable
/// password format.
///
/// v2 (current): `HMAC-SHA256(pepper, "digitsOnlyPhone:pin")`.
/// Changing this invalidates existing derived passwords by design — accounts
/// created under the old scheme must go through PIN/password reset.
String buildAuthPasswordFromPin({required String phone, required String pin}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final hmac = Hmac(sha256, utf8.encode(_pepper));
  final digest = hmac.convert(utf8.encode('$digits:$pin'));
  return 'Mu2#${base64Url.encode(digest.bytes).replaceAll('=', '')}';
}

/// App-compiled pepper. Not a secret against a determined reverse-engineer of
/// the client binary — it only prevents casual reuse of the old, fully
/// public template, and the phone-number salt is what removes the
/// one-template-fits-all flaw.
const _pepper = 'MaliUp::Auth::v2::2026::9f3a7c1e2b6d4f81';
