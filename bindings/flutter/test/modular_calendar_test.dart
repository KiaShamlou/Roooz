import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';

void main() {
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  CivilDate d(int day, {int month = 8, int year = 1405}) =>
      engine.date(year, month, day);
  RoozSelectionPolicy policy(
          {int max = 30,
          int min = 1,
          int weekdays = 0,
          SelectionMode mode = SelectionMode.range,
          List<int> blocked = const [],
          bool Function(CivilDate)? allowed}) =>
      RoozSelectionPolicy(
          minimum: engine.date(1400, 1, 1),
          maximum: engine.date(1410, 12, 29),
          maxDays: max,
          minDays: min,
          mode: mode,
          disabledWeekdays: weekdays,
          blockedDays: blocked,
          isSelectable: allowed);
  RoozCalendarController create({RoozSelectionPolicy? rules}) =>
      RoozCalendarController(initialDate: d(14), policy: rules ?? policy());
  test('reverse, inclusive, next tap restarts, same day and cross-month', () {
    final c = create();
    addTearDown(c.dispose);
    expect(c.select(d(18)), true);
    expect(c.select(d(10)), true);
    expect(c.selection.start, d(10));
    expect(c.inclusiveDays, 9);
    c.select(d(21));
    expect(c.selection.end, null);
    c.select(d(21));
    expect(c.inclusiveDays, 1);
    expect(c.setRange(d(28), d(2, month: 9)), true);
    expect(c.inclusiveDays, 5);
  });
  test('native and predicate interior exclusions reject atomically', () {
    for (final p in [
      policy(blocked: [d(12).epochDay]),
      policy(allowed: (x) => x != d(12))
    ]) {
      final c = create(rules: p);
      c.select(d(10));
      final before = c.selection;
      expect(c.select(d(18)), false);
      expect(identical(before, c.selection), true);
      expect(c.error, isNotNull);
      c.dispose();
    }
  });
  test('min/max range length, weekdays, blackout and single selection', () {
    final c = create(rules: policy(min: 3, max: 5));
    addTearDown(c.dispose);
    expect(c.select(d(10)), true);
    expect(c.select(d(11)), false);
    expect(c.select(d(14)), true);
    expect(c.inclusiveDays, 5);
    expect(c.setRange(d(10), d(15)), false);
    expect(c.inclusiveDays, 5);
    c.updatePolicy(policy(mode: SelectionMode.single));
    expect(c.selection.start, null);
    c.select(d(10));
    expect(c.inclusiveDays, 1);
    c.updatePolicy(policy(weekdays: 1 << (d(10).weekday - 1)));
    expect(c.isEnabled(d(10)), false);
    expect(c.selection.start, null);
  });
  test(
      'lower limit clears selection with one callback; navigation preserves it',
      () {
    var changes = 0, errors = 0;
    final c = RoozCalendarController(
        initialDate: d(14),
        policy: policy(),
        onSelectionChanged: (_) => changes++,
        onError: (_) => errors++);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    final selected = c.selection;
    c.navigateMonths(4);
    expect(identical(c.selection, selected), true);
    expect(c.month.year, 1405);
    expect(c.month.month, 12);
    c.navigateMonths(1);
    expect(c.month.year, 1406);
    expect(c.month.month, 1);
    expect(changes, 1);
    expect(errors, 0);
  });
  test(
      'policy replacement revalidates, clears, relocates; callbacks reflect state',
      () {
    var changes = 0, errors = 0, navigations = 0;
    final c = RoozCalendarController(
        initialDate: d(14),
        policy: policy(),
        onSelectionChanged: (_) => changes++,
        onError: (_) => errors++,
        onNavigate: (_) => navigations++);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    c.updatePolicy(policy(max: 3));
    expect(c.selection.start, null);
    expect(changes, 2);
    expect(errors, 1);
    c.updatePolicy(RoozSelectionPolicy(
        minimum: d(1, year: 1406), maximum: d(30, year: 1406)));
    expect(c.anchor.year, 1406);
    expect(navigations, 1);
  });
  test('native year boundaries and unsupported days never wrap', () {
    final c = RoozCalendarController(
        initialDate: engine.date(1, 1, 1),
        policy: RoozSelectionPolicy(
            minimum: engine.date(1, 1, 1), maximum: engine.date(3177, 12, 29)));
    addTearDown(c.dispose);
    expect(c.monthOffset(-1), null);
    c.goTo(engine.date(3177, 12, 1));
    expect(c.monthOffset(1), null);
    expect(() => engine.date(1405, 12, 30), throwsA(isA<RoozException>()));
    expect(
        engine.date(1405, 1, 1).convertTo(CalendarSystem.gregorian).toString(),
        '2026/03/21');
  });
  test('invalid policy input is rejected', () {
    expect(() => policy(max: 0), throwsArgumentError);
    expect(() => policy(min: 5, max: 2), throwsArgumentError);
    expect(() => policy(weekdays: 128), throwsArgumentError);
  });
  Widget host(Widget child, {double width = 520, double scale = 1}) =>
      MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: MediaQuery(
                      data:
                          MediaQueryData(textScaler: TextScaler.linear(scale)),
                      child: SizedBox(width: width, child: child)))));
  final variants = <RoozCalendarOptions>[
    for (final design in RoozMonthDesign.values)
      RoozCalendarOptions(design: design),
    for (final layout in RoozCalendarLayout.values)
      RoozCalendarOptions(group: RoozPresentationGroup.layouts, layout: layout),
    for (final style in RoozCalendarStyle.values)
      RoozCalendarOptions(group: RoozPresentationGroup.original, style: style),
  ];
  testWidgets('all 16 retain identical selection; custom accent stays exact',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    final selected = c.selection;
    for (final o in variants) {
      await tester.pumpWidget(host(RoozCalendar(controller: c, options: o)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      expect(identical(c.selection, selected), true);
      final context = tester.element(find.byType(RoozCalendarCustomization));
      expect(Theme.of(context).colorScheme.primary, const Color(0xFF28766D));
    }
  });
  testWidgets('all 16 narrow, RTL/LTR, large text, Sunday start',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    for (final o in variants) {
      await tester.pumpWidget(host(
          RoozCalendar(
              controller: c,
              options: RoozCalendarOptions(
                  group: o.group,
                  design: o.design,
                  layout: o.layout,
                  style: o.style,
                  dark: true,
                  firstWeekday: 7,
                  direction: TextDirection.ltr,
                  weekdayLabels: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])),
          width: 320,
          scale: 1.8));
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    }
  });
  testWidgets('custom day/badge/header/footer keep validation and callback',
      (tester) async {
    final c = create(rules: policy(blocked: [d(10).epochDay]));
    addTearDown(c.dispose);
    for (final group in RoozPresentationGroup.values) {
      await tester.pumpWidget(host(RoozCalendar(
          controller: c,
          options: RoozCalendarOptions(group: group),
          events: {
            d(11).epochDay: ['work']
          },
          dayBuilder: (context, day) => Text('D${day.date.day}'),
          badgeBuilder: (context, day) =>
              day.events.isEmpty ? const SizedBox() : const Text('!'),
          headerBuilder: (context, date, child) =>
              Column(children: [const Text('MY HEADER'), child]),
          footerBuilder: (context, state) => const Text('MY FOOTER'))));
      await tester.pumpAndSettle();
      expect(find.text('MY HEADER'), findsOneWidget);
      expect(find.text('MY FOOTER'), findsOneWidget);
      expect(find.text('!'), findsOneWidget);
      c.clear();
      await tester.tap(find.byKey(ValueKey('custom-day-${d(10).epochDay}')));
      expect(c.selection.start, null);
      await tester.tap(find.byKey(ValueKey('custom-day-${d(11).epochDay}')));
      expect(c.selection.start, d(11));
    }
  });
  testWidgets('controlled compact expansion and year month callback',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    bool? expanded;
    await tester.pumpWidget(host(RoozCalendar(
        controller: c,
        options: const RoozCalendarOptions(
            group: RoozPresentationGroup.layouts,
            layout: RoozCalendarLayout.compact),
        compactExpanded: false,
        onExpandedChanged: (v) => expanded = v)));
    await tester.tap(find.byKey(const ValueKey('calendar-disclosure')));
    await tester.pump();
    expect(expanded, true);
    expect(find.byKey(ValueKey('layout-day-${d(14).epochDay}')), findsNothing);
    CivilDate? picked;
    await tester.pumpWidget(host(RoozCalendar(
        controller: c,
        options: const RoozCalendarOptions(
            group: RoozPresentationGroup.layouts,
            layout: RoozCalendarLayout.year),
        onMonthSelected: (d) => picked = d)));
    await tester.tap(find.byKey(const ValueKey('year-month-2')));
    expect(picked!.month, 2);
  });
  testWidgets('confirmation only after completed range and clear resets',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    var confirms = 0;
    await tester.pumpWidget(
        host(RoozCalendar(controller: c, onConfirm: (_) => confirms++)));
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('rooz-confirm')))
            .onPressed,
        null);
    c.setRange(d(10), d(18));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('rooz-confirm')));
    await tester.tap(find.byKey(const Key('rooz-confirm')));
    expect(confirms, 1);
    await tester.tap(find.byKey(const Key('rooz-clear')));
    expect(c.selection.start, null);
  });
  testWidgets('custom day retains keyboard focus and selection semantics',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    await tester.pumpWidget(host(RoozCalendar(
        controller: c,
        dayBuilder: (_, day) => Text(day.date.day.toString(),
            key: ValueKey('content-${day.date.epochDay}')))));
    final semantics = tester.ensureSemantics();

    await tester.tap(find.byKey(ValueKey('custom-day-${d(10).epochDay}')));
    await tester.pump();
    expect(
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true),
        findsOneWidget);
    Focus.of(tester.element(find.byKey(ValueKey('content-${d(11).epochDay}'))))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(c.selection.isComplete, true);
    semantics.dispose();
  });
}
