import 'dart:io';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';

void main() {
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  CivilDate d(int day) => engine.date(1405, 8, day);
  RoozCalendarController create({List<int> blocked = const [], int max = 30}) =>
      RoozCalendarController(
          initialDate: d(14),
          policy: RoozSelectionPolicy(
              minimum: d(1),
              maximum: engine.date(1405, 9, 10),
              maxDays: max,
              blockedDays: blocked));
  Finder target(int day) =>
      find.byKey(ValueKey('range-drop-${d(day).epochDay}'));
  Future<void> render(WidgetTester tester, RoozCalendarController c,
      {RoozCalendarOptions options = const RoozCalendarOptions(),
      RoozCalendarMotion motion = const RoozCalendarMotion(),
      bool custom = false,
      bool reduceMotion = false}) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: RoozCalendar(
                        controller: c,
                        compactExpanded: true,
                        options: options,
                        motion: motion,
                        dayBuilder: custom
                            ? (_, day) => Text('${day.date.day}')
                            : null))))));
    await tester.pumpAndSettle();
  }

  Future<TestGesture> hold(WidgetTester tester, int end) async {
    final gesture =
        await tester.startGesture(tester.getCenter(target(end).first));
    await tester.pump(const Duration(milliseconds: 400));
    return gesture;
  }

  test(
      'resize fixes start, rejects reversal, bounds, interior blocks and lengths',
      () {
    final c = create(blocked: [d(20).epochDay], max: 12);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    expect(c.resizeEnd(d(15)), true);
    expect(c.selection.start, d(10));
    final before = c.selection;
    for (final end in [d(9), d(25), d(21)]) {
      expect(c.canResizeEnd(end), false);
      expect(c.resizeEnd(end), false);
      expect(identical(c.selection, before), true);
    }
    expect(c.resizeEnd(d(10)), true);
    expect(c.inclusiveDays, 1);
    c.clear();
    expect(c.resizeEnd(d(18)), false);
  });
  test('resize obeys custom validators, minimum length and Jalali Nowruz', () {
    final start = engine.date(1404, 12, 28);
    final end = engine.date(1405, 1, 2);
    final c = RoozCalendarController(
        initialDate: start,
        policy: RoozSelectionPolicy(
            minimum: start,
            maximum: d(30),
            minDays: 2,
            isSelectable: (day) => day != engine.date(1405, 1, 4),
            rangeValidator: (_, end) {
              if (end == engine.date(1405, 1, 3))
                throw ArgumentError('Reserved');
            }));
    addTearDown(c.dispose);
    expect(c.setRange(start, end), true);
    expect(c.inclusiveDays, 4);
    expect(c.resizeEnd(start), false);
    expect(c.resizeEnd(engine.date(1405, 1, 3)), false);
    expect(c.resizeEnd(engine.date(1405, 1, 5)), false);
    expect(c.resizeEnd(engine.date(1405, 1, 1)), true);
    expect(c.inclusiveDays, 3);
    expect(c.selection.start, start);
  });

  test('default range has no length cap; explicit caps still apply', () {
    final minimum = engine.date(1400, 1, 1);
    final maximum = engine.date(1410, 12, 29);
    final c = RoozCalendarController(
        initialDate: d(14),
        policy: RoozSelectionPolicy(minimum: minimum, maximum: maximum));
    addTearDown(c.dispose);
    expect(c.policy.maxDays, RoozSelectionPolicy.unlimitedDays);
    expect(c.setRange(engine.date(1402, 1, 1), engine.date(1405, 1, 1)), true);
    expect(c.inclusiveDays!, greaterThan(1000));
    expect(c.resizeStart(engine.date(1401, 1, 1)), true);
    expect(c.resizeEnd(engine.date(1406, 1, 1)), true);
    c.updatePolicy(
        RoozSelectionPolicy(minimum: minimum, maximum: maximum, maxDays: 30));
    expect(c.selection.start, isNull);
    expect(c.setRange(d(1), d(1).addDays(30)), false);
  });
  test(
      'start edit preserves end and rejects crossing, interior blocks and min length',
      () {
    final c = create(blocked: [d(8).epochDay]);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    expect(c.resizeStart(d(12)), true);
    expect(c.selection.end, d(18));
    final saved = c.selection;
    expect(c.resizeStart(d(19)), false);
    expect(c.resizeStart(d(6)), false);
    expect(identical(c.selection, saved), true);
    c.updatePolicy(
        RoozSelectionPolicy(minimum: d(1), maximum: d(30), minDays: 3));
    expect(c.resizeStart(d(17)), false);
    expect(c.resizeStart(d(16)), true);
    expect(c.inclusiveDays, 3);
  });
  testWidgets('start drag works with mouse and held touch', (tester) async {
    final c = create();
    addTearDown(c.dispose);
    for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
      c.setRange(d(10), d(18));
      await render(tester, c);
      final gesture =
          await tester.startGesture(tester.getCenter(target(10)), kind: kind);
      if (kind == PointerDeviceKind.touch)
        await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(target(5)));
      await tester.pump();
      expect(c.selection.start, d(10));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.selection.start, d(5));
      expect(c.selection.end, d(18));
    }
  });
  testWidgets(
      'collapsed range can expand either endpoint; flags are independent',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    for (final destination in [16, 23]) {
      c.setRange(d(18), d(18));
      await render(tester, c);
      final gesture = await tester.startGesture(tester.getCenter(target(18)),
          kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(target(destination)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.selection.start, d(destination == 16 ? 16 : 18));
      expect(c.selection.end, d(destination == 16 ? 18 : 23));
    }
    c.setRange(d(10), d(18));
    await render(tester, c,
        motion: const RoozCalendarMotion(dragRangeStart: false));
    expect(
        find.byWidgetPredicate(
            (w) => w is Draggable && w.key.toString().contains('mouse-start')),
        findsNothing);
    await render(tester, c,
        motion: const RoozCalendarMotion(dragRangeEnd: false));
    final gesture = await hold(tester, 10);
    await gesture.moveTo(tester.getCenter(target(12)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.start, d(12));
    expect(c.selection.end, d(18));
  });

  testWidgets('mouse endpoint drag without hold preserves start',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    await render(tester, c);
    final gesture = await tester.startGesture(tester.getCenter(target(18)),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.start, d(10));
    expect(c.selection.end, d(23));
  });

  testWidgets('mouse hold option, cancellation and secondary button',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    await render(tester, c);
    var gesture = await tester.startGesture(tester.getCenter(target(18)),
        kind: PointerDeviceKind.mouse);
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(18));
    gesture = await tester.startGesture(tester.getCenter(target(18)),
        kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(18));
    await render(tester, c,
        motion: const RoozCalendarMotion(immediateMouseDrag: false));
    gesture = await tester.startGesture(tester.getCenter(target(18)),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(23));
    expect(c.selection.start, d(10));
  });

  testWidgets('ordinary mouse click still selects a date', (tester) async {
    final c = create();
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    await render(tester, c);
    final gesture = await tester.startGesture(tester.getCenter(target(18)),
        kind: PointerDeviceKind.mouse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.start, d(18));
    expect(c.selection.end, isNull);
  });

  testWidgets('long press previews, commits once, preserves start',
      (tester) async {
    var changes = 0;
    final c = RoozCalendarController(
        initialDate: d(14),
        policy: RoozSelectionPolicy(minimum: d(1), maximum: d(30)),
        onSelectionChanged: (_) => changes++);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    await render(tester, c);
    final gesture = await hold(tester, 18);
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pumpAndSettle();
    expect(c.selection.end, d(18));
    final border = tester.widget<AnimatedContainer>(target(23));
    expect((border.foregroundDecoration! as BoxDecoration).border, isNotNull);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.start, d(10));
    expect(c.selection.end, d(23));
    expect(changes, 2);
  });
  testWidgets(
      'invalid drop, cancel, stale edit and disabled gesture preserve state',
      (tester) async {
    final c = create(blocked: [d(20).epochDay]);
    addTearDown(c.dispose);
    c.setRange(d(10), d(18));
    await render(tester, c);
    var gesture = await hold(tester, 18);
    await gesture.moveTo(tester.getCenter(target(23)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(18));
    gesture = await hold(tester, 18);
    await gesture.moveTo(tester.getCenter(target(15)));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(18));
    gesture = await hold(tester, 18);
    c.setRange(d(2), d(5));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target(15)));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.selection.end, d(5));
    await render(tester, c,
        motion: const RoozCalendarMotion(
            dragRangeEnd: false, dragRangeStart: false));
    expect(find.byWidgetPredicate((w) => w is Draggable), findsNothing);
  });
  testWidgets(
      'all day-based presentations support end drag including custom slots',
      (tester) async {
    final c = create();
    addTearDown(c.dispose);
    final variants = [
      for (final design in RoozMonthDesign.values)
        RoozCalendarOptions(design: design),
      for (final style in RoozCalendarStyle.values)
        RoozCalendarOptions(
            group: RoozPresentationGroup.original, style: style),
      for (final layout in [
        RoozCalendarLayout.month,
        RoozCalendarLayout.week,
        RoozCalendarLayout.agenda,
        RoozCalendarLayout.split,
        RoozCalendarLayout.compact
      ])
        RoozCalendarOptions(
            group: RoozPresentationGroup.layouts, layout: layout)
    ];
    for (final options in variants) {
      c.setRange(d(10), d(14));
      await render(tester, c,
          options: options, custom: true, reduceMotion: true);
      if (options.group == RoozPresentationGroup.layouts &&
          options.layout == RoozCalendarLayout.agenda) {
        await tester.scrollUntilVisible(target(14), 200,
            scrollable: find.descendant(
                of: find.byKey(const ValueKey('agenda-list')),
                matching: find.byType(Scrollable)));
      }
      final end = target(14).first, destination = target(13).first;
      if (options.group == RoozPresentationGroup.layouts &&
          options.layout == RoozCalendarLayout.agenda) {
        await tester.drag(
            find.byKey(const ValueKey('agenda-list')), const Offset(0, 100));
      } else {
        await tester.ensureVisible(end);
      }
      await tester.pumpAndSettle();
      final gesture = await hold(tester, 14);
      await gesture.moveTo(tester.getCenter(destination));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.selection.end, d(13),
          reason:
              '${options.group}/${options.layout}/${options.style}/${options.design}');
      c.setRange(d(12), d(14));
      await tester.pumpAndSettle();
      final startGesture = await hold(tester, 12);
      await startGesture.moveTo(tester.getCenter(target(13).first));
      await tester.pump();
      await startGesture.up();
      await tester.pumpAndSettle();
      expect(c.selection.start, d(13),
          reason: 'start handle ${options.group}/${options.layout}');
      expect(c.selection.end, d(14));
      expect(tester.takeException(), isNull);
    }
  });
}
