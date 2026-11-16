import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization_service.dart';

/// Welcome-popup copy for the free reverse trial, edited by admins on the
/// admin portal's "Free Trial" page (`platform_config/trial`). The trial
/// itself, the reminder push and the end-date SMS are all server-side
/// (functions/src/trial.ts); the app only renders this popup.
///
/// Placeholders: {name} {businessName} {days} {daysLeft} {endDate}.
/// Defaults mirror DEFAULT_TRIAL_CONFIG in trial.ts so an unconfigured doc
/// (or an offline first launch) still shows sensible text.
class TrialMessages {
  final String titleSw;
  final String bodySw;
  final String titleEn;
  final String bodyEn;
  final String ownerName;

  const TrialMessages({
    this.titleSw = _defaultTitleSw,
    this.bodySw = _defaultBodySw,
    this.titleEn = _defaultTitleEn,
    this.bodyEn = _defaultBodyEn,
    this.ownerName = '',
  });

  static const _defaultTitleSw = 'Zawadi yako ya siku {days}! 🎁';
  static const _defaultBodySw =
      'Hongera {name}! Tumekupa kifurushi cha Growth BURE kwa siku {days}. '
      'Tumia ripoti kamili, mtiririko wa fedha, madeni na mauzo bila kikomo. '
      'Kifurushi kitaisha tarehe {endDate} (siku {daysLeft} zimebaki).';
  static const _defaultTitleEn = 'Your {days}-day gift! 🎁';
  static const _defaultBodyEn =
      "Congratulations {name}! We've gifted you the Growth package FREE for {days} days. "
      'Enjoy full reports, cash flow, debt tracking and unlimited sales. '
      'It ends on {endDate} ({daysLeft} days left).';

  factory TrialMessages.fromFirestore(
    Map<String, dynamic> data, {
    String ownerName = '',
  }) {
    String pick(String key, String def) {
      final v = data[key];
      return v is String && v.trim().isNotEmpty ? v : def;
    }

    return TrialMessages(
      titleSw: pick('welcomeTitleSw', _defaultTitleSw),
      bodySw: pick('welcomeBodySw', _defaultBodySw),
      titleEn: pick('welcomeTitleEn', _defaultTitleEn),
      bodyEn: pick('welcomeBodyEn', _defaultBodyEn),
      ownerName: ownerName,
    );
  }

  String get title => LocalizationService.tr(en: titleEn, sw: titleSw);
  String get body => LocalizationService.tr(en: bodyEn, sw: bodySw);
}

/// dd/MM/yyyy — the format used in the SMS and push too.
String formatTrialDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Replaces `{key}` / `{{key}}` placeholders; unknown keys are left as-is.
String fillTrialTemplate(String template, Map<String, Object> vars) {
  return template.replaceAllMapped(
    RegExp(r'\{\{?\s*(\w+)\s*\}\}?'),
    (m) => vars.containsKey(m[1]) ? '${vars[m[1]]}' : m[0]!,
  );
}

final trialMessagesProvider =
    FutureProvider.autoDispose<TrialMessages>((ref) async {
  final db = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  var ownerName = '';
  if (uid != null) {
    try {
      final u = await db.collection('users').doc(uid).get();
      final data = u.data() ?? {};
      ownerName = ((data['firstName'] as String?)?.trim().isNotEmpty == true
              ? data['firstName'] as String
              : (data['name'] as String?) ?? '')
          .trim()
          .split(' ')
          .first;
    } catch (_) {
      // Name is cosmetic.
    }
  }
  try {
    final snap = await db.collection('platform_config').doc('trial').get();
    return TrialMessages.fromFirestore(snap.data() ?? {}, ownerName: ownerName);
  } catch (_) {
    return TrialMessages(ownerName: ownerName);
  }
});

/// Remembers per device and per business which trial's welcome popup has
/// already been shown, so it appears once after the gift lands — not on
/// every launch, business switch or re-login.
class TrialGiftTracker {
  TrialGiftTracker._();

  static const _keyPrefix = 'trial_gift_shown_';
  static final Set<String> _inFlight = {};

  /// True (once) when the trial identified by [trialStartedAt] hasn't been
  /// shown on this device yet. Marks it shown before returning, so a burst of
  /// plan-status emissions can't open two popups.
  static Future<bool> claim(String businessId, DateTime trialStartedAt) async {
    final key = '$_keyPrefix$businessId';
    final stamp = trialStartedAt.millisecondsSinceEpoch;
    final memoKey = '$key:$stamp';
    if (_inFlight.contains(memoKey)) return false;
    _inFlight.add(memoKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(key) == stamp) return false;
      await prefs.setInt(key, stamp);
      return true;
    } catch (_) {
      return false;
    }
  }
}
