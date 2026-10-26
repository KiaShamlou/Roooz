# Roooz: modular UI and selection

## Three independent layers

1. **Native C engine / Dart binding:** unchanged calendar conversion, parsing,
   leap years and inclusive range validation. No JS date fixture replaces it.
2. **`RoozCalendarController` + `RoozSelectionPolicy`:** optional state owner and
   policy. Public low-level controlled widgets still work without this layer.
3. **`RoozCalendar` + `RoozCalendarOptions` + customization slots:** presentation.
   Styling does not mutate controller state. Dispose a controller that you own.

This UI module is Flutter (Android, iOS and desktop hosts). Existing Kotlin and
Swift bindings remain intact; this change does not add sixteen native Compose
or SwiftUI implementations.

## Preserve every design, independently of color

| Group | Options |
| --- | --- |
| `monthly` | `ribbon`, `ledger`, `tiles`, `frame`, `floating`, `brackets` |
| `layouts` | `month`, `week`, `agenda`, `split`, `compact`, `year` |
| `original` | `classic`, `glass`, `midnight`, `minimal` |

These are three alternative groups, not 6 × 6 × 4 combinations. Month designs
have distinct header/cell/range geometry. Midnight uses a dark surface but keeps
the caller's accent. Set `colorScheme` for complete palette control. Existing
imports and constructors still work. Weekdays consistently use **Monday=1,
Sunday=7**; the earlier presentation assertions incorrectly permitted zero and
excluded seven and have been corrected.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';

// `engine` is the application's already opened Rooz engine.
final controller = RoozCalendarController(
  initialDate: engine.date(1405, 8, 14),
  policy: RoozSelectionPolicy(
    minimum: engine.date(1400, 1, 1),
    maximum: engine.date(1410, 12, 29),
    minDays: 1,
    // Optional: maxDays: 30, // omitted => no extra length cap
    mode: SelectionMode.range,
    disabledWeekdays: 1 << 4, // Friday; Monday is bit zero.
    blockedDays: [engine.date(1405, 8, 20).epochDay],
    isSelectable: (date) => availability.contains(date.epochDay),
    rangeValidator: (start, end) {
      if (!canBook(start, end)) throw ArgumentError('Unavailable booking');
    },
  ),
  onSelectionChanged: (selection) => saveDraft(selection),
  onNavigate: (date) => loadEvents(date),
  onError: (error) => logRejectedSelection(error),
);

RoozCalendar(
  controller: controller,
  options: const RoozCalendarOptions(
    group: RoozPresentationGroup.monthly,
    design: RoozMonthDesign.ribbon,
    accent: Color(0xFF28766D),
    dark: false,
    direction: TextDirection.rtl,
    firstWeekday: 6,
    weekdayLabels: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    showOutsideDays: true,
  ),
  minDayHeight: 52,
  cardRadius: 24,
  contentPadding: const EdgeInsets.all(16),
  events: eventTitlesByEpochDay,
  today: todayInTheChosenTimeZone,
  headerBuilder: (context, month, defaultHeader) => defaultHeader,
  badgeBuilder: (context, day) => day.events.isEmpty
      ? const SizedBox() : const Icon(Icons.circle, size: 5),
  errorBuilder: (error) => 'این بازه قابل انتخاب نیست',
  onConfirm: (selection) => submitBooking(selection),
);
```

The application supplies `availability`, booking functions, event map and
`today`; no network, persistence or implicit time-zone policy is introduced.
Use `dayBuilder(context, RoozDayDetails)` to replace day contents. The library
retains its semantic button, selected/enabled state, focus and keyboard action.
`headerBuilder` receives the default header so apps can wrap it or replace it.
`footerBuilder` replaces the optional clear/confirm area. A caller-provided
header/footer owns any replacement navigation/actions. `labelBuilder` supplies
localized full accessibility labels. All action labels, locale, digit set,
weekday labels and RTL/LTR are parameters; automatic weekday labels use native
formatting. Custom color, font family/text theme, radius and padding are separate
from design identity. Custom builders are responsible for their own layout and
contrast. Use an externally owned controller for programmatic control.

## State and policy contract

- First range tap starts selection; second completes it. Reversed endpoints
  normalize; same-day range is one inclusive day. Third tap starts a new range.
- `setRange(start, end)` is atomic; invalid presets leave old selection intact.
- Native rules inspect interior blocked dates and disabled weekdays. A custom
  `isSelectable` also runs on **every interior day**; keep it pure, synchronous,
  fast, and bound `maxDays`. `rangeValidator` can throw `ArgumentError` or
  `RoozException` to reject; unrelated programming errors are not swallowed.
- `updatePolicy` revalidates existing selection; incompatible selection clears
  once and reports the error. Navigation clamps to the new permitted month when
  needed. A calendar-system change requires a new controller. In single mode,
  `minDays` must be 1.
- `clear`, `goTo`, `navigateMonths` and `monthOffset` support external controls.
  Date engine limits are checked; invalid dates never wrap into another year.
- Change presentation values without recreating the controller to preserve the
  selection. `compactExpanded` / `onExpandedChanged` make disclosure controlled.
  `onMonthSelected` lets the host implement year-to-month drill-down. Without
  these overrides, the old widgets retain their local disclosure/drill-down.
- Confirmation is an explicit callback and stays disabled until selection is
  complete. No server request occurs automatically.

## Demo

From `examples/flutter`, run `flutter run -t lib/playground.dart` on a configured
native device. The demo offers all 16 options, HEX accent, dark/light, phone width,
custom day contents, hide adjacent month days, range/single, maximum length,
Friday blocking, sample range, clear, confirm and JSON copy. JSON export is an
example application snapshot, **not** an import/persistence API. The demo's
bounds are 1400–1410 and initial view is Aban 1405; library bounds are parameters.
No 11-year fixture drives the actual dates. Older BookingApp and galleries remain.

## Validation commands

```sh
# ROOZ_LIBRARY must point to a host-built Rooz shared library.
cd bindings/flutter
flutter analyze
flutter test
cd ../../examples/flutter
flutter analyze
flutter test
```

Widget coverage includes all 16 options, identical retained range, custom HEX,
RTL/LTR, Sunday start, 320px with large text, callbacks, custom slots, keyboard
activation, bounds and policy changes. Native exhaustive tests remain separate.

## Both range endpoints and motion

Both the **start** and **end** of a completed range are draggable by default.
Dragging one endpoint keeps the other fixed. Crossing the other endpoint,
dropping outside a visible date, invalid ranges, cancellation and stale external
edits leave the selection unchanged. On a collapsed one-day range, dragging to
an earlier date edits the start; dragging to a later date edits the end.

```dart
RoozCalendar(
  controller: controller,
  motion: const RoozCalendarMotion(
    dragRangeStart: true,
    dragRangeEnd: true,
    immediateMouseDrag: true,
    holdDelay: Duration(milliseconds: 350),
    duration: Duration(milliseconds: 160),
    hoverScale: 1.06,
    curve: Curves.easeOutCubic,
    hapticFeedback: false,
    startHandleHint: 'Drag to change the start; hold first on touch screens',
    endHandleHint: 'Drag to change the end; hold first on touch screens',
  ),
)
```

Primary-button mouse drag starts after normal drag slop, without the hold timer.
Touch/stylus use `holdDelay`. `immediateMouseDrag: false` also requires a hold
for mouse. Ordinary clicks still select dates. Both endpoint flags can be set
independently. Single-selection mode has no range handles. Motion respects
`MediaQuery.disableAnimations`; durations must be nonnegative. Drop targets
highlight validity; selection commits once on drop, not while hovering.

`canResizeStart` / `resizeStart` and `canResizeEnd` / `resizeEnd` expose the same
operations for custom controls. Policy checks include date bounds, weekday and
interior exclusions, explicit length caps, and custom validators. Validators
must be pure because hovering can invoke them repeatedly.

`RoozSelectionPolicy.maxDays` now defaults to `unlimitedDays` (the native int32
maximum), meaning **no extra length cap within the supported calendar and the
explicit minimum/maximum dates**. Set `maxDays` to impose a business rule. The
demo starts with its length-limit switch OFF, its slider disabled, and JSON
`maxDays: null`. Enabling the switch opts into the displayed slider limit.
The demo's date bounds remain 1400–1410; these are separate from range length.

All visible day cells support the gesture, including custom day content, six
monthly designs, four styles, week/agenda/split and expanded compact. Year and
collapsed compact have no day cells. There is no drag auto-scroll/month paging;
navigate to the needed month first. Adjacent-month cells are valid targets.
