import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotionService {
  static const String _reducedMotionKey = 'reduced_motion_enabled';
  static final ValueNotifier<bool> reducedMotionNotifier = ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    reducedMotionNotifier.value = await getReducedMotionEnabled();
  }

  static Future<void> initializeWithPrefs(SharedPreferences prefs) async {
    reducedMotionNotifier.value = prefs.getBool(_reducedMotionKey) ?? false;
  }

  static Future<void> setReducedMotionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedMotionKey, enabled);
    reducedMotionNotifier.value = enabled;
  }

  static Future<bool> getReducedMotionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reducedMotionKey) ?? false;
  }
}