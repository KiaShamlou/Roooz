import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';
import 'package:rooz_native/rooz_native.dart' show openBundledRooz;
import 'package:rooz_demo/playground.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('packaged native engine and modular playground', (tester) async {
    final engine = openBundledRooz();
    expect(
        engine.date(1405, 1, 1).convertTo(CalendarSystem.gregorian).toString(),
        '2026/03/21');
    expect(() => engine.date(1405, 12, 30), throwsA(isA<RoozException>()));
    await tester.pumpWidget(RoozPlaygroundApp(engine: engine));
    await tester.pumpAndSettle();
    final controller =
        tester.widget<RoozCalendar>(find.byType(RoozCalendar)).controller;
    controller.clear();
    controller.select(engine.date(1405, 8, 18));
    controller.select(engine.date(1405, 8, 10));
    await tester.pumpAndSettle();
    expect(controller.inclusiveDays, 9);
    for (final key in [
      const ValueKey('group-original'),
      const ValueKey('option-glass')
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<RoozCalendar>(find.byType(RoozCalendar)).options.style,
        RoozCalendarStyle.glass);
    expect(controller.inclusiveDays, 9);
    final source =
        find.byKey(ValueKey('range-drop-${engine.date(1405, 8, 18).epochDay}'));
    final destination =
        find.byKey(ValueKey('range-drop-${engine.date(1405, 8, 23).epochDay}'));
    await tester.ensureVisible(source);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveTo(tester.getCenter(destination));
    await tester.pumpAndSettle();
    expect(controller.selection.end!.day, 18);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection.start!.day, 10);
    expect(controller.selection.end!.day, 23);
    expect(controller.inclusiveDays, 14);
    expect(tester.takeException(), null);
  });
}
