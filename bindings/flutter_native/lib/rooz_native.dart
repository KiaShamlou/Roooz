import 'dart:io';
import 'package:rooz_calendar/rooz_calendar.dart';
export 'package:rooz_calendar/rooz_calendar.dart';

/// Loads the engine built and bundled by this source-only Flutter FFI plugin.
/// Widget tests should inject Rooz.open(hostLibraryPath) instead.
Rooz openBundledRooz() {
  if (Platform.isMacOS || Platform.isIOS) {
    return Rooz.open('rooz_native.framework/rooz_native');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return Rooz.open('librooz_native.so');
  }
  if (Platform.isWindows) return Rooz.open('rooz_native.dll');
  throw UnsupportedError('Native Rooz does not target the browser');
}
