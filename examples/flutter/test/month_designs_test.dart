import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_month_designs.dart';
import '../lib/month_designs.dart';

void main() {
  testWidgets('six monthly skins preserve dates and range while color changes',
      (tester) async {
    final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
    final month = engine.date(1405, 8, 1);
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(MaterialApp(home: MonthDesignsPage(engine: engine)));
    for (final offset in [9, 17]) {
      final cell =
          find.byKey(ValueKey('month-design-day-${month.epochDay + offset}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
    }
    for (final design in RoozMonthDesign.values) {
      final chip = find.byKey(ValueKey('design-${design.name}'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      final view =
          tester.widget<RoozMonthDesignView>(find.byType(RoozMonthDesignView));
      expect(view.month, month);
      expect(view.design, design);
      expect(view.selection.start, month.addDays(9));
      expect(view.selection.end, month.addDays(17));
    }
    final color = find.byKey(const ValueKey('color-آبی'));
    await tester.ensureVisible(color);
    await tester.tap(color);
    await tester.pumpAndSettle();
    expect(
        Theme.of(tester.element(find.byType(RoozMonthDesignView)))
            .colorScheme
            .primary,
        ColorScheme.fromSeed(seedColor: Colors.indigo).primary);
    final clear = find.text('پاک کردن انتخاب');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RoozMonthDesignView>(find.byType(RoozMonthDesignView))
            .selection
            .start,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
