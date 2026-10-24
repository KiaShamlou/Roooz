# Flutter native demo

From this directory, with Flutter 3.27.4 and target toolchains installed:

```sh
flutter pub get
flutter run -d macos    # or a listed iOS/Android/Windows/Linux device
flutter test integration_test/bundled_engine_test.dart -d macos
```

`rooz_native` builds and bundles the C engine for the target, while
`rooz_calendar_flutter` renders controlled cells. No host-library paths in the app.
Apple targets require CocoaPods. The browser is deliberately not targeted.

Headless tests use an explicitly injected **host** library:

```sh
# From repository root:
make all
cd examples/flutter
ROOZ_LIBRARY=/absolute/path/to/build/librooz.dylib flutter test
```

Features: four calendar choices, Persian digits, RTL, responsive scrolling,
light/dark theme, custom cell builder, month navigation, reverse range,
30-inclusive-day validation with error feedback, reset. Initial date is fixed
for reproducible tests; apps can provide their own clock/time-zone policy.
