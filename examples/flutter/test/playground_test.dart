import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';
import '../lib/playground.dart';

void main() {
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  final fonts = Platform.environment['PREVIEW_FONT'];
  setUpAll(() async {
    if (fonts != null) {
      final loader = FontLoader('PreviewFont')
        ..addFont(
            Future.value(ByteData.sublistView(File(fonts).readAsBytesSync())));
      await loader.load();
      final icons = Platform.environment['PREVIEW_ICONS'];
      if (icons != null) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(
              ByteData.sublistView(File(icons).readAsBytesSync())));
        await loader.load();
      }
    }
  });
  Future<void> launch(WidgetTester tester, {double width = 1200}) async {
    tester.view.physicalSize = Size(width, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('capture'),
        child: RoozPlaygroundApp(
            engine: engine, fontFamily: fonts == null ? null : 'PreviewFont')));
    await tester.pumpAndSettle();
  }

  Future<void> click(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
  }

  testWidgets('all sixteen choices keep one controller and selected range',
      (tester) async {
    await launch(tester);
    for (final group in RoozPresentationGroup.values) {
      await click(tester, ValueKey('group-${group.name}'));
      final names = switch (group) {
        RoozPresentationGroup.monthly =>
          RoozMonthDesign.values.map((e) => e.name),
        RoozPresentationGroup.layouts =>
          RoozCalendarLayout.values.map((e) => e.name),
        RoozPresentationGroup.original =>
          RoozCalendarStyle.values.map((e) => e.name),
      };
      for (final name in names) {
        await click(tester, ValueKey('option-$name'));
        final state =
            tester.widget<RoozCalendar>(find.byType(RoozCalendar)).controller;
        expect(state.inclusiveDays, 9);
        expect(state.selection.start!.day, 10);
        expect(state.selection.end!.day, 18);
      }
    }
    await click(tester, const ValueKey('group-monthly'));
    await click(tester, const Key('dark-toggle'));
    await click(tester, const Key('narrow-toggle'));
    final calendar = tester.widget<RoozCalendar>(find.byType(RoozCalendar));
    expect(calendar.controller.inclusiveDays, 9);
    expect(calendar.options.dark, true);
  });
  testWidgets('custom HEX never changes design; reduced limit clears range',
      (tester) async {
    await launch(tester);
    await tester.enterText(find.byKey(const Key('accent-hex')), '#a64b31');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    var calendar = tester.widget<RoozCalendar>(find.byType(RoozCalendar));
    expect(calendar.options.accent, const Color(0xFFa64b31));
    expect(calendar.options.design, RoozMonthDesign.ribbon);
    await click(tester, const Key('limit-range-toggle'));
    final slider = tester.widget<Slider>(find.byKey(const Key('max-days')));
    slider.onChanged!(3);
    await tester.pumpAndSettle();
    calendar = tester.widget<RoozCalendar>(find.byType(RoozCalendar));
    expect(calendar.controller.selection.start, null);
    expect(find.byKey(const Key('rooz-error')), findsOneWidget);
  });
  testWidgets(
      'demo defaults to unlimited length and explicit cap is reversible',
      (tester) async {
    await launch(tester);
    final c = tester.widget<RoozCalendar>(find.byType(RoozCalendar)).controller;
    expect(c.policy.maxDays, RoozSelectionPolicy.unlimitedDays);
    expect(tester.widget<Slider>(find.byKey(const Key('max-days'))).onChanged,
        isNull);
    expect(c.setRange(engine.date(1405, 1, 1), engine.date(1406, 1, 1)), true);
    await click(tester, const Key('limit-range-toggle'));
    expect(c.policy.maxDays, 30);
    expect(c.selection.start, isNull);
    await click(tester, const Key('limit-range-toggle'));
    expect(c.setRange(engine.date(1405, 1, 1), engine.date(1406, 1, 1)), true);
  });
  testWidgets('phone viewport has no overflow', (tester) async {
    await launch(tester, width: 360);
    expect(tester.takeException(), null);
  });
  testWidgets('render reference-inspired gallery screenshots', (tester) async {
    if (Platform.environment['ROOZ_SCREENSHOTS'] == null) return;
    await launch(tester);
    final directory = Directory(Platform.environment['ROOZ_SCREENSHOTS']!)
      ..createSync(recursive: true);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('capture')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${directory.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('ribbon-light');
    await click(tester, const ValueKey('option-ledger'));
    await capture('ledger-light');
    await click(tester, const ValueKey('option-tiles'));
    await click(tester, const Key('dark-toggle'));
    await capture('tiles-dark');
  });
}
