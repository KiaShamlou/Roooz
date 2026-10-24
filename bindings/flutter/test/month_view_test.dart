import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_flutter.dart';

void main() {
  testWidgets('renders 42 cells, forwards taps, respects disabled days',
      (tester) async {
    final path = Platform.environment['ROOZ_LIBRARY'];
    if (path == null)
      throw StateError('Set ROOZ_LIBRARY to the built native library');
    final engine = Rooz.open(path);
    final month = engine.date(1403, 1, 1);
    CivilDate? tapped;
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
                body: SizedBox(
                    width: 420,
                    child: RoozMonthView(
                      month: month,
                      selection: const DateSelection(),
                      isEnabled: (d) => d.epochDay != month.epochDay,
                      onDateTapped: (d) => tapped = d,
                      dayBuilder: (_, date, selected, inMonth, enabled) =>
                          Text('day-${date.epochDay}'),
                    ))))));
    expect(find.byType(TextButton), findsNWidgets(42));
    await tester.tap(find.text('day-${month.epochDay}'));
    expect(tapped, isNull);
    await tester.tap(find.text('day-${month.epochDay + 1}'));
    expect(tapped, month.addDays(1));
  });

  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  Widget host(Widget child, {TextDirection direction = TextDirection.rtl}) =>
      MaterialApp(
          home: Directionality(
              textDirection: direction,
              child: Scaffold(body: SizedBox(width: 420, child: child))));

  testWidgets('selected range is semantic and custom cells receive flags',
      (tester) async {
    final month = engine.date(1403, 1, 1);
    final rules = RangeRules(minimum: month, maximum: month.addDays(30));
    final selection =
        const DateSelection().tap(month.addDays(2), rules).tap(month, rules);
    final flags = <int, bool>{};
    await tester.pumpWidget(host(RoozMonthView(
        month: month,
        selection: selection,
        onDateTapped: (_) {},
        dayBuilder: (_, d, selected, inMonth, enabled) {
          flags[d.epochDay] = inMonth;
          return Text('cell-${d.epochDay}');
        })));
    expect(
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true),
        findsNWidgets(3));
    expect(flags[month.epochDay], isTrue);
    expect(flags[month.epochDay - 1], isFalse);
  });

  testWidgets('boundary blanks do not become tappable dates', (tester) async {
    final month = engine.date(1, 1, 1);
    final days = month.monthGrid(firstWeekday: 1);
    await tester.pumpWidget(host(RoozMonthView(
        month: month,
        selection: const DateSelection(),
        firstWeekday: 1,
        onDateTapped: (_) {})));
    expect(find.byType(TextButton),
        findsNWidgets(days.whereType<CivilDate>().length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LTR first weekday and explicit labels remain customizable',
      (tester) async {
    final month = engine.date(1403, 1, 1);
    CivilDate? tap;
    await tester.pumpWidget(host(
        RoozMonthView(
            month: month,
            firstWeekday: 1,
            selection: const DateSelection(),
            onDateTapped: (d) => tap = d,
            labelBuilder: (d) => 'booking-${d.epochDay}',
            dayBuilder: (_, d, __, ___, ____) => Text('cell-${d.epochDay}')),
        direction: TextDirection.ltr));
    final first = month.monthGrid(firstWeekday: 1).first!;
    await tester.tap(find.text('cell-${first.epochDay}'));
    expect(tap, first);
    expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'booking-${first.epochDay}'),
        findsOneWidget);
  });

  testWidgets('wide text scaling preserves a scrollable narrow host',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: SizedBox(
                        width: 320,
                        child: RoozMonthView(
                            month: engine.date(1403, 1, 1),
                            selection: const DateSelection(),
                            onDateTapped: (_) {})))))));
    expect(find.byType(TextButton), findsNWidgets(42));
    expect(tester.takeException(), isNull);
  });
}
