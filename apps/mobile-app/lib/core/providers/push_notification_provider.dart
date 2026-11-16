import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/rbac/data/rbac_providers.dart'
    show userProfileStreamProvider;
import '../services/localization_service.dart';
import '../services/push_notification_service.dart';
import 'auth_provider.dart';
import 'business_id_provider.dart';

/// Bridges [LocalizationService.languageNotifier] (the single source of
/// truth for app language) into Riverpod so topic subscriptions follow it.
final _pushLanguageProvider = Provider<AppLanguage>((ref) {
  final notifier = LocalizationService.languageNotifier;
  void onChange() => ref.invalidateSelf();
  notifier.addListener(onChange);
  ref.onDispose(() => notifier.removeListener(onChange));
  return notifier.value;
});

/// Sets up push for the signed-in user and keeps this device's FCM topic
/// subscriptions matched to their active business + app language. Public
/// activation hook — watch exactly once, high in the authenticated app shell
/// (mirrors notificationAggregatorActivatorProvider's shape).
final pushTokenRegistrarProvider = Provider<void>((ref) {
  ref.watch(_pushSessionProvider);
  ref.watch(_pushTopicsProvider);
});

/// One per signed-in uid: initialize on sign-in, drop the token (and with it
/// every topic subscription) on sign-out or account switch.
final _pushSessionProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;
  // firebase_messaging has no Windows/Linux implementation — the desktop
  // build gets only the on-device alerts from NotificationService.
  if (!PushNotificationService.isSupported) return;

  // ignore: unawaited_futures — fire-and-forget, never blocks UI.
  PushNotificationService.initialize(uid);
  // ignore: unawaited_futures
  ref.onDispose(() => PushNotificationService.dispose());
});

final _pushTopicsProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || !PushNotificationService.isSupported) return;
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull;
  // Still resolving — don't unsubscribe from the business topic just
  // because the id is momentarily unknown.
  if (businessId == null) return;
  // Owner vs team member decides the owner-only channels. Unknown while the
  // profile loads — wait rather than briefly dropping an owner's channels.
  final profileAsync = ref.watch(userProfileStreamProvider);
  if (profileAsync.isLoading && !profileAsync.hasValue) return;
  final isOwner = profileAsync.valueOrNull?['isTeamMember'] != true;
  final language = ref.watch(_pushLanguageProvider);

  // ignore: unawaited_futures — queued behind initialize(), never blocks UI.
  PushNotificationService.setTopics(
    uid,
    PushTopics.forUser(
      businessId: businessId,
      language: language,
      isOwner: isOwner,
    ),
  );
});

/// Emits an in-app route whenever a push notification carrying a `route`
/// data field is tapped — the shell listens to this and navigates.
final pushNotificationRouteProvider = StreamProvider<String>((ref) {
  return PushNotificationService.routeStream;
});
