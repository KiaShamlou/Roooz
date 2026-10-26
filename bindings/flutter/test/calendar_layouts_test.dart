import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_layouts.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'PreviewFont': 'PREVIEW_FONT',
      'PreviewLatin': 'PREVIEW_LATIN',
      'MaterialIcons': 'PREVIEW_ICONS'
    }.entries) {
      final path = Platform.environment[entry.value];
      if (path != null) {
        final loader = FontLoader(entry.key);
        loader.addFont(
            Future.value(ByteData.sublistView(await File(path).readAsBytes())));
        await loader.load();
      }
    }
  });
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  final anchor = engine.date(1405, 8, 14);
  final rules = RangeRules(
      minimum: engine.date(1400, 1, 1), maximum: engine.date(1410, 12, 29));
  final selection = const DateSelection().tap(anchor, rules);
  final events = {
    anchor.epochDay: ['۰۹:۳۰ · جلسهٔ تیم', '۱۶:۰۰ · مرور طراحی'],
    anchor.addDays(-13).epochDay: ['۱۰:۰۰ · شروع پروژه']
  };
  Widget host(Widget child,
          {double scale = 1, Color seed = const Color(0xFF41615A)}) =>
      MaterialApp(
          theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: seed),
              fontFamily: Platform.environment['PREVIEW_FONT'] == null
                  ? null
                  : 'PreviewFont',
              fontFamilyFallback: const ['PreviewLatin']),
          home: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(body: SingleChildScrollView(child: child)))));

  for (final layout in RoozCalendarLayout.values) {
    testWidgets('${layout.name}: selection, navigation and structure',
        (tester) async {
      var displayed = anchor;
      CivilDate? tapped;
      await tester.binding.setSurfaceSize(const Size(720, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host(StatefulBuilder(
          builder: (context, setState) => SizedBox(
              width: 640,
              child: RoozCalendarLayouts(
                  date: displayed,
                  selection: selection,
                  layout: layout,
                  events: events,
                  initiallyExpanded: true,
                  onDateTapped: (d) => tapped = d,
                  onNavigate: (d) => setState(() => displayed = d))))));
      if (layout == RoozCalendarLayout.year) {
        expect(find.byType(OutlinedButton), findsNWidgets(12));
        await tester.tap(find.byKey(const ValueKey('year-month-2')));
        await tester.pumpAndSettle();
        expect(displayed.month, 2);
        expect(find.byKey(const ValueKey('back-to-year')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('back-to-year')));
        await tester.pumpAndSettle();
        expect(find.byType(OutlinedButton), findsNWidgets(12));
      } else if (layout == RoozCalendarLayout.agenda) {
        final first = anchor.addDays(1 - anchor.day);
        await tester.tap(find.byKey(ValueKey('agenda-day-${first.epochDay}')));
        expect(tapped, first);
        await tester.drag(
            find.byKey(const ValueKey('agenda-list')), const Offset(0, -600));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.byKey(ValueKey('layout-day-${anchor.epochDay}')));
        expect(tapped, anchor);
      }
      await tester.tap(find.byTooltip('بعدی'));
      await tester.pumpAndSettle();
      expect(
          displayed,
          layout == RoozCalendarLayout.week
              ? anchor.addDays(7)
              : layout == RoozCalendarLayout.year
                  ? engine.date(1406, 2, 1)
                  : anchor.addMonths(1));
      expect(tester.takeException(), isNull);
    });
    testWidgets('${layout.name}: narrow and large text', (tester) async {
      await tester.pumpWidget(host(
          SizedBox(
              width: 320,
              child: RoozCalendarLayouts(
                  date: anchor,
                  selection: selection,
                  layout: layout,
                  events: events,
                  initiallyExpanded: true,
                  onDateTapped: (_) {},
                  onNavigate: (_) {})),
          scale: 2));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('compact disclosure opens and closes', (tester) async {
    await tester.pumpWidget(host(SizedBox(
        width: 440,
        child: RoozCalendarLayouts(
            date: anchor,
            selection: selection,
            layout: RoozCalendarLayout.compact,
            onDateTapped: (_) {}))));
    expect(find.byKey(ValueKey('layout-day-${anchor.epochDay}')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-disclosure')));
    await tester.pump();
    expect(
        find.byKey(ValueKey('layout-day-${anchor.epochDay}')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-disclosure')));
    await tester.pump();
    expect(find.byKey(ValueKey('layout-day-${anchor.epochDay}')), findsNothing);
  });
  testWidgets('caller theme controls selection color and disabled days',
      (tester) async {
    for (final seed in [Colors.indigo, Colors.orange]) {
      CivilDate? tapped;
      await tester.pumpWidget(host(
          SizedBox(
              width: 440,
              child: RoozCalendarLayouts(
                  date: anchor,
                  selection: selection,
                  onDateTapped: (d) => tapped = d,
                  isEnabled: (d) => d != anchor)),
          seed: seed));
      await tester.pumpAndSettle();
      final button = tester.widget<TextButton>(
          find.byKey(ValueKey('layout-day-${anchor.epochDay}')));
      expect(button.style!.backgroundColor!.resolve({}),
          ColorScheme.fromSeed(seedColor: seed).primary);
      await tester.tap(find.byKey(ValueKey('layout-day-${anchor.epochDay}')));
      expect(tapped, isNull);
    }
  });
  testWidgets('six structurally different layouts, one shared theme',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final descriptions = [
      'شبکهٔ کامل ماه، انتخاب مستقیم روز',
      'هفت روز افقی، برنامه‌های روز در پایین',
      'فهرست عمودی قابل اسکرول، جزئیات کنار هر روز',
      'تقویم و جزئیات روز، کنار هم',
      'فیلد کوچک؛ تقویم فقط وقتی لازم است',
      'دوازده ماه؛ ورود به جزئیات با یک لمس'
    ];
    await tester.pumpWidget(host(RepaintBoundary(
        key: const Key('layouts-sheet'),
        child: ColoredBox(
            color: const Color(0xFFF0F1F3),
            child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Text('شش شکل برای روز',
                      style:
                          TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text('تفاوت در چیدمان؛ رنگ، انتخاب شماست.',
                      style: TextStyle(fontSize: 17)),
                  const SizedBox(height: 36),
                  for (var row = 0; row < 3; row++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 34),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Builder(builder: (context) {
                                          final index = row * 2 + col,
                                              layout = RoozCalendarLayout
                                                  .values[index];
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(layout.label,
                                                    style: const TextStyle(
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 6),
                                                Text(descriptions[index],
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                const SizedBox(height: 18),
                                                if (layout ==
                                                    RoozCalendarLayout
                                                        .compact) ...[
                                                  RoozCalendarLayouts(
                                                      date: anchor,
                                                      selection: selection,
                                                      layout: layout,
                                                      onDateTapped: (_) {}),
                                                  const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                      child: Text(
                                                          'پس از باز شدن ↓',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 12))),
                                                ],
                                                RoozCalendarLayouts(
                                                    date: anchor,
                                                    selection: selection,
                                                    layout: layout,
                                                    events: events,
                                                    initiallyExpanded: true,
                                                    onDateTapped: (_) {},
                                                    onNavigate: (_) {}),
                                              ]);
                                        }))),
                            ])),
                ]))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['PREVIEW_FONT'] != null) {
      await expectLater(find.byKey(const Key('layouts-sheet')),
          matchesGoldenFile('goldens/calendar-layouts.png'));
    }
  });
}
