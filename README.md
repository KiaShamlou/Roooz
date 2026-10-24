# Roooz · روز

[![Conformance](https://github.com/KiaShamlou/Roooz/actions/workflows/ci.yml/badge.svg)](https://github.com/KiaShamlou/Roooz/actions/workflows/ci.yml)

**A Jalali-first calendar toolkit. One date engine, native language APIs, your UI.**

[فارسی](README.fa.md) · [Accuracy contract](docs/accuracy.md) · [Integration](docs/platforms.md) · [Architecture](docs/architecture.md)

Rooz separates calendar arithmetic from rendering. Kotlin, Swift and Dart clients
call the **same C engine**, rather than relying on different OS calendar algorithms.
Build a booking range picker, Persian date field, event calendar or completely
custom calendar surface without coupling business rules to a particular UI toolkit.

**Status: 0.1.0 source alpha.** The repository is **Roooz**; package/module names
remain `rooz_calendar`, `RoozCalendar` and `dev.rooz`. Three runnable demos and a
source-only Flutter native bundler are included. See [verification](docs/verification.md)
and [release checklist](docs/releasing.md) for tested targets and remaining gates.

## What is implemented

- **Jalali first:** Borkowski break-year algorithm, including leap Esfand.
- **Four explicit systems:** Jalali, proleptic Gregorian, Islamic **civil** and Julian.
- Immutable civil dates, conversion, weekday/day-of-year and month length.
- Day/month arithmetic with explicit clamp-or-reject month overflow.
- Single-date and inclusive range selection; reverse taps and restart/clear.
- Bounds, min/max length, disabled weekdays, and blocked dates **inside** a range.
- Custom policy callbacks that reject a candidate without losing selection state.
- Six-week month grids with configurable first weekday.
- UTF-8 formatting, English/Persian/Arabic labels and Latin/Persian/Arabic digits.
- Strict localized numeric parsing; invalid input does not silently roll over.
- Builder-driven SwiftUI and Flutter views, plus a Compose integration example.
- No runtime dependencies in the C, Swift, Kotlin or Dart core bindings.

This is not “every calendar, every language, every platform already certified.”
The C ABI is the extension point for additional languages. The current native
Dart binding does not run in a browser. See the [platform matrix](docs/platforms.md).

## Swift

Add the repository root as a local Swift Package, then:

```swift
import RoozCalendar

let nowruz = try CivilDate(1403, 1, 1)
let gregorian = try nowruz.converted(to: .gregorian) // 2024-03-20
print(try nowruz.formatted("%A %d %B %Y")) // چهارشنبه ۰۱ فروردین ۱۴۰۳

let rules = RangeRules(minimum: nowruz, maximum: try nowruz.adding(days: 90),
                       minLength: 2, maxLength: 14)
var selection = DateSelection()
try selection.tap(nowruz, rules: rules)
try selection.tap(nowruz.adding(days: 4), rules: rules) // 5 inclusive days
```

## Kotlin

Build the Android AAR or JNI library using the [integration guide](docs/platforms.md).

```kotlin
import dev.rooz.*

val nowruz = CivilDate(1403, 1, 1)
val gregorian = nowruz.convertTo(CalendarSystem.GREGORIAN)
val rules = RangeRules(nowruz, nowruz.plusDays(90), minLength = 2, maxLength = 14)
val selection = DateSelection().tap(nowruz, rules).tap(nowruz.plusDays(4), rules)
println(nowruz.format("%A %d %B %Y"))
```

## Dart

Add a path dependency on `bindings/dart`, then load your target's native library:

```dart
import 'package:rooz_calendar/rooz_calendar.dart';

final rooz = Rooz.open('/absolute/path/to/librooz.dylib'); // .so / rooz.dll on other OSes
final nowruz = rooz.date(1403, 1, 1);
final parsed = rooz.parse('۱۴۰۳/۰۱/۰۱');
final rules = RangeRules(minimum: nowruz, maximum: nowruz.addDays(90), maxLength: 14);
final selection = const DateSelection().tap(nowruz, rules).tap(nowruz.addDays(4), rules);
print(parsed.format(pattern: '%A %d %B %Y'));
```

## C / C++

```c
#include "rooz.h"

int32_t nowruz = rc_to_day(RC_JALALI, 1403, 1, 1);
int year = rc_get_field(RC_GREGORIAN, nowruz, RC_YEAR); /* 2024 */
char text[128];
int status = rc_format(RC_JALALI, nowruz, "%Y/%m/%d",
                       rc_builtin_locale(RC_JALALI, 1), RC_PERSIAN, text, sizeof text);
/* Check status == RC_OK before using text. */
```

## Make the UI yours

The views do not own the selected value or navigation. Supply day builders, header,
event badges, theme, label formatter and enabled-state predicate. Select with the
headless reducer in your own state store. `validator` hooks implement custom booking
policy; compare epoch days instead of formatted date strings.

- [SwiftUI macOS / iOS app](examples/swiftui/README.md)
- [Kotlin Android / Compose app](examples/compose/README.md)
- [Flutter native app](examples/flutter/README.md) and [view package](bindings/flutter/README.md)

Pass RTL/LTR explicitly in the host UI. Localized digits do not imply a layout
direction, and choosing an app language does not change the selected calendar.

## Formatting contract

| Token | Meaning |
|---|---|
| `%Y` | Four-digit year |
| `%m`, `%d` | Two-digit month/day |
| `%B`, `%A` | Full month/weekday name |
| `%u` | Monday=1 ... Sunday=7 |
| `%j` | Three-digit day of year |
| `%%` | Literal percent |

Other text is literal UTF-8. Unknown tokens fail. Parsing supports exactly one
each of `%Y`, `%m`, `%d` and literal separators; it accepts all three digit sets
and rejects suffixes, short fields, impossible dates and duplicated fields.
Custom C locale tables or host UI formatters extend names and presentation.

## Correctness, not a badge

```sh
make all test oracle reference sanitize
tools/test_swift.sh
JAVA_HOME=/path/to/jdk KOTLINC=/path/to/kotlinc tools/test_kotlin.sh
dart run bindings/dart/test/smoke.dart /absolute/path/to/librooz.dylib
```

- Exhaustive adjacency and round-trip checks across **12,007,879 valid dates**.
- Independent Node/ICU comparison for every day in **1800–2099**, two calendars.
- **6,354** shared Jalali year-boundary fixtures exercised by Swift, Kotlin and Dart.
- **114,372** first/middle/last-month samples against pinned jalaali-js 1.2.8.
- Boundary, invalid input, parser, buffer, selection and deterministic malformed-byte tests.
- ASan/UBSan and a CI matrix for native builds and binding tests.

Round-trip consistency does not certify an astronomical or official civil calendar.
The extended ICU audit found actual far-future Jalali disagreements; they are
recorded in the [accuracy contract](docs/accuracy.md), not hidden by the test suite.

## Try a demo

```sh
# SwiftUI desktop
swift run --package-path examples/swiftui RoozDemo
# Android (JDK 17 + Android SDK)
./gradlew -p examples/compose :app:assembleDebug
# Flutter (target toolchain required)
cd examples/flutter && flutter pub get && flutter run -d macos
```

Flutter uses `openBundledRooz()` from `bindings/flutter_native`; no manually
copied host dylib. For raw Dart servers/CLI, supply an absolute native-library path.

## Release roadmap

1. Validate Android AAR and iOS simulator/device consumers; run UI/a11y test matrix.
2. Validate the source-bundled Flutter engine on each target and publish registry packages.
3. Add WASM/browser bindings and additional language packages with the same fixtures.
4. Add independently sourced, explicitly named calendar variants (e.g. Umm al-Qura),
   recurrence, week/year views and optional holiday/event providers.

MIT. Algorithm attribution and the upstream test reference license are preserved in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Contributions start with a reproducible
calendar fixture; see [CONTRIBUTING.md](CONTRIBUTING.md).
