import 'package:posthog_flutter/posthog_flutter.dart';

/// Dedicated PostHog Logs facade for purpose-written, non-sensitive app logs.
///
/// This intentionally does not attach to the app's existing [debugPrint] or
/// other logging paths, so only lines added for PostHog Logs leave the device.
class PostHogLog {
  const PostHogLog._();

  void info(String body, {Map<String, Object>? attributes}) {
    Posthog().logger.info(body, attributes);
  }
}

const posthogLog = PostHogLog._();
