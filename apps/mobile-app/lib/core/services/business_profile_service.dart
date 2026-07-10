import 'package:flutter/foundation.dart';

/// Fired whenever the active business's profile (name, logo, plan) is edited,
/// so screens holding a cached copy — e.g. the dashboard Hero card, which
/// only refetches from Firestore once every 24h — know to refresh immediately.
class BusinessProfileService {
  BusinessProfileService._();

  static final ValueNotifier<int> updatedNotifier = ValueNotifier<int>(0);

  static void notifyUpdated() => updatedNotifier.value++;
}
