import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Window behaviour for the Windows desktop build: the app opens in true
/// full screen (no title bar, covering the taskbar), and F11 toggles full
/// screen on and off. Escape is deliberately not used — it already closes
/// dialogs and side panels. No-op on every other platform.
class DesktopWindowService {
  DesktopWindowService._();

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> initialize() async {
    if (!_isWindows) return;
    try {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          title: 'Mali Up',
          minimumSize: Size(420, 640),
        ),
        () async {
          await windowManager.setFullScreen(true);
          await windowManager.show();
          await windowManager.focus();
        },
      );
      HardwareKeyboard.instance.addHandler(_onKey);
    } catch (e) {
      // Never let window setup block startup — the app still runs windowed.
      debugPrint('[DesktopWindowService] initialize failed: $e');
    }
  }

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.f11) {
      return false;
    }
    toggleFullScreen();
    return true;
  }

  static Future<void> toggleFullScreen() async {
    if (!_isWindows) return;
    try {
      final isFull = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFull);
    } catch (e) {
      debugPrint('[DesktopWindowService] toggle failed: $e');
    }
  }
}
