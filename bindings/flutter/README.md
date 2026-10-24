# Roooz Flutter view

A controlled `RoozMonthView` over `rooz_calendar` native dates. Pass the selected
state, date-tap callback and your day builder. Place it in a constrained-width
parent with the desired `Directionality`. Add your own header/weekday labels.

This monorepo package depends on `../dart`. Add `../flutter_native` to build and
bundle the C engine automatically, or inject your own Rooz instance. See the
runnable app in `examples/flutter`. Native platforms only; not a web implementation.

```dart
RoozMonthView(
  month: month,
  selection: selection,
  onDateTapped: (date) {
    try {
      final candidate = selection.tap(date, rules);
      setState(() => selection = candidate);
    } on RoozException catch (error) {
      // Display a localized message for error.code; keep the old state.
    }
  },
  dayBuilder: (context, date, selected, inMonth, enabled) =>
      Text(date.format(pattern: '%d')),
)
```

Run the supplied widget tests with `ROOZ_LIBRARY` pointing to the host native
library. The native date engine, not Flutter's Gregorian DateTime APIs, supplies
the cells and selection behavior.
