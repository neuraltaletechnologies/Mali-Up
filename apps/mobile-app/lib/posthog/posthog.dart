import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Configures PostHog once before the Flutter app starts.
///
/// Native release builds embed the public project token so analytics remains
/// configured when `--dart-define` values are not available. Development
/// builds can override both values with `--dart-define`.
class PosthogEnv {
  static const projectToken = String.fromEnvironment(
    'POSTHOG_PROJECT_TOKEN',
    defaultValue: 'phc_rQRHhC2rHQeYmNtXsyhkPk3fHTcqAwbXznpR2dhRme63',
  );
  static const host = String.fromEnvironment('POSTHOG_HOST');
}

Future<void> setupPostHog() async {
  // Flutter Web is initialized by the posthog-js snippet in web/index.html.
  if (kIsWeb) return;

  final platform = defaultTargetPlatform;
  if (platform != TargetPlatform.android &&
      platform != TargetPlatform.iOS &&
      platform != TargetPlatform.macOS) {
    return;
  }

  if (PosthogEnv.projectToken.isEmpty) {
    if (kDebugMode) {
      throw StateError(
        'POSTHOG_PROJECT_TOKEN variable required by PostHog is missing or '
        'un-configured, this causes events to be silently missed. This error '
        'stops appearing once POSTHOG_PROJECT_TOKEN is configured',
      );
    }
    return;
  }

  final config = PostHogConfig(PosthogEnv.projectToken);
  if (PosthogEnv.host.isNotEmpty) config.host = PosthogEnv.host;
  config.debug = kDebugMode;

  // Logs are manually emitted through the dedicated PostHog log helper.
  // Existing debugPrint and application log output remains local-only.
  config.logsConfig.serviceName = 'mali-up';

  // Capture uncaught Flutter, Dart platform, and native exceptions globally.
  // Existing app-level error reporting hooks chain to these SDK handlers.
  config.errorTrackingConfig.captureFlutterErrors = true;
  config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
  config.errorTrackingConfig.captureNativeExceptions = true;

  await Posthog().setup(config);
}
