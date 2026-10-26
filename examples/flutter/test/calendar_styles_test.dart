import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_layouts.dart';
import '../lib/calendar_styles.dart';

void main() {
  testWidgets('six layouts and independent theme keep selection',
      (tester) async {
    final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
    final anchor = engine.date(1405, 8, 14);
    await tester.binding.setSurfaceSize(const Size(850, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(MaterialApp(home: CalendarStylesPage(engine: engine)));
    for (final offset in [0, 2]) {
      final cell =
          find.byKey(ValueKey('layout-day-${anchor.epochDay + offset}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
    }
    for (final layout in RoozCalendarLayout.values) {
      final choice = find.byKey(ValueKey('layout-${layout.name}'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      final view =
          tester.widget<RoozCalendarLayouts>(find.byType(RoozCalendarLayouts));
      expect(view.layout, layout);
      expect(view.selection.start, anchor);
      expect(view.selection.end, anchor.addDays(2));
    }
    final theme = find.byKey(const ValueKey('theme-آبی'));
    await tester.ensureVisible(theme);
    await tester.tap(theme);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(RoozCalendarLayouts));
    expect(Theme.of(context).colorScheme.primary,
        ColorScheme.fromSeed(seedColor: Colors.indigo).primary);
    final confirm = find.widgetWithText(FilledButton, 'تأیید بازه');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('تمام'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
