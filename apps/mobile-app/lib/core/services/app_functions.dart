import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloud Functions callables that also work on the Windows desktop build.
///
/// `cloud_functions` has no Windows implementation — any `httpsCallable`
/// there throws a MissingPluginException before a request is ever sent, so
/// every server action (team removal, OTP, PIN reset, payments, account
/// deletion) failed on desktop. Where the plugin exists this simply wraps it;
/// elsewhere it speaks the same HTTPS callable protocol directly (POST
/// `{"data": …}` with the user's ID token, read `result` / `error`), and
/// raises the same [FirebaseFunctionsException] codes, so callers' existing
/// error handling is unchanged.
class AppFunctions {
  AppFunctions._();

  static const defaultRegion = 'us-central1';

  /// Platforms the `cloud_functions` plugin actually implements.
  static bool get _hasPlugin =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// A callable for [name]. Pass [functions] to force a specific plugin
  /// instance (tests); it's ignored on platforms without the plugin.
  static AppCallable callable(
    String name, {
    String region = defaultRegion,
    Duration timeout = const Duration(seconds: 70),
    FirebaseFunctions? functions,
  }) {
    if (_hasPlugin) {
      final fns = functions ?? FirebaseFunctions.instanceFor(region: region);
      return AppCallable._plugin(
        fns.httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: timeout),
        ),
      );
    }
    return AppCallable._http(name, region, timeout);
  }
}

class AppCallableResult<T> {
  final T data;
  const AppCallableResult(this.data);
}

class AppCallable {
  final HttpsCallable? _callable;
  final String _name;
  final String _region;
  final Duration _timeout;

  AppCallable._plugin(HttpsCallable callable)
    : _callable = callable,
      _name = '',
      _region = '',
      _timeout = Duration.zero;

  AppCallable._http(this._name, this._region, this._timeout)
    : _callable = null;

  Future<AppCallableResult<T>> call<T>([Object? parameters]) async {
    final plugin = _callable;
    if (plugin != null) {
      final res = await plugin.call<T>(parameters);
      return AppCallableResult<T>(res.data);
    }
    final raw = await _callHttp(parameters);
    return AppCallableResult<T>(raw as T);
  }

  Future<Object?> _callHttp(Object? parameters) async {
    final projectId = Firebase.app().options.projectId;
    final uri = Uri.parse(
      'https://$_region-$projectId.cloudfunctions.net/$_name',
    );

    final headers = <String, String>{'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
    }
    // Best-effort: App Check isn't enforced on the functions yet, but send
    // a token when one is available so enabling enforcement later doesn't
    // silently break desktop.
    try {
      final appCheck = await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 3),
      );
      if (appCheck != null && appCheck.isNotEmpty) {
        headers['X-Firebase-AppCheck'] = appCheck;
      }
    } catch (_) {}

    final http.Response res;
    try {
      res = await http
          .post(uri, headers: headers, body: jsonEncode({'data': parameters}))
          .timeout(_timeout);
    } on TimeoutException catch (e, st) {
      throw _exception('deadline-exceeded', 'Request timed out.', st, e);
    } catch (e, st) {
      throw _exception('unavailable', 'Could not reach the server.', st, e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    final error = body?['error'];
    if (error is Map) {
      final status = (error['status'] ?? 'INTERNAL').toString();
      throw _exception(
        status.toLowerCase().replaceAll('_', '-'),
        (error['message'] ?? status).toString(),
        StackTrace.current,
        error['details'],
      );
    }
    if (res.statusCode != 200 || body == null) {
      throw _exception(
        'internal',
        'Unexpected response (HTTP ${res.statusCode}).',
        StackTrace.current,
      );
    }
    return body['result'];
  }

  static FirebaseFunctionsException _exception(
    String code,
    String message,
    StackTrace stackTrace, [
    Object? details,
  ]) =>
      // The constructor is @protected only to steer apps toward the plugin;
      // throwing the same type keeps every caller's `on
      // FirebaseFunctionsException` / `.code` handling working unchanged.
      // ignore: invalid_use_of_protected_member
      FirebaseFunctionsException(
        code: code,
        message: message,
        stackTrace: stackTrace,
        details: details,
      );
}
