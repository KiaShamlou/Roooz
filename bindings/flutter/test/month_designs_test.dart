import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_month_designs.dart';

void main() {
  setUpAll(() async {
    for (final e in {
      'PreviewFont': 'PREVIEW_FONT',
      'PreviewLatin': 'PREVIEW_LATIN',
      'MaterialIcons': 'PREVIEW_ICONS'
    }.entries) {
      final path = Platform.environment[e.value];
      if (path != null) {
        final l = FontLoader(e.key);
        l.addFont(
            Future.value(ByteData.sublistView(await File(path).readAsBytes())));
        await l.load();
      }
    }
  });
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  final month = engine.date(1405, 8, 1),
      rules = RangeRules(
          minimum: engine.date(1400, 1, 1), maximum: engine.date(1410, 12, 29));
  final selection = const DateSelection()
      .tap(month.addDays(9), rules)
      .tap(month.addDays(17), rules);
  Widget host(Widget child,
          {double scale = 1,
          Color seed = Colors.teal,
          TextDirection direction = TextDirection.rtl}) =>
      MaterialApp(
          theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: seed),
              fontFamily: Platform.environment['PREVIEW_FONT'] == null
                  ? null
                  : 'PreviewFont',
              fontFamilyFallback: const ['PreviewLatin']),
          home: Directionality(
              textDirection: direction,
              child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(body: SingleChildScrollView(child: child)))));
  for (final design in RoozMonthDesign.values) {
    testWidgets(
        '${design.name}: same 42 dates, range, taps, theme and navigation',
        (tester) async {
      CivilDate? tapped;
      var previous = 0, next = 0;
      for (final seed in [Colors.teal, Colors.deepOrange]) {
        await tester.pumpWidget(host(
            SizedBox(
                width: 480,
                child: RoozMonthDesignView(
                    month: month,
                    selection: selection,
                    design: design,
                    onDateTapped: (d) => tapped = d,
                    isEnabled: (d) => d != month,
                    onPreviousMonth: () => previous++,
                    onNextMonth: () => next++)),
            seed: seed));
        await tester.pumpAndSettle();
        expect(
            find.byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>)
                    .value
                    .startsWith('month-design-day-')),
            findsNWidgets(42));
        expect(
            find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.selected == true),
            findsNWidgets(9));
        expect(
            find.byWidgetPredicate((w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.onTap != null),
            findsNWidgets(41));
        tapped = null;
        await tester
            .tap(find.byKey(ValueKey('month-design-day-${month.epochDay}')));
        expect(tapped, isNull);
        await tester.tap(
            find.byKey(ValueKey('month-design-day-${month.epochDay + 1}')));
        expect(tapped, month.addDays(1));
        await tester.tap(find.byTooltip('ماه قبل'));
        await tester.tap(find.byTooltip('ماه بعد'));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(RoozMonthDesignView));
        expect(Theme.of(context).colorScheme.primary,
            ColorScheme.fromSeed(seedColor: seed).primary);
        expect(tester.takeException(), isNull);
      }
      expect([previous, next], [2, 2]);
    });
    testWidgets('${design.name}: narrow LTR large text', (tester) async {
      await tester.pumpWidget(host(
          SizedBox(
              width: 320,
              child: RoozMonthDesignView(
                  month: month,
                  selection: selection,
                  design: design,
                  onDateTapped: (_) {},
                  onPreviousMonth: () {},
                  onNextMonth: () {})),
          scale: 2,
          direction: TextDirection.ltr));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('boundary blanks stay noninteractive', (tester) async {
    final boundary = engine.date(1, 1, 1);
    await tester.pumpWidget(host(RoozMonthDesignView(
        month: boundary,
        selection: const DateSelection(),
        onDateTapped: (_) {})));
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('month-design-day-')),
        findsNWidgets(
            boundary.monthGrid(firstWeekday: 6).whereType<CivilDate>().length));
  });
  testWidgets('six monthly designs with identical dates range and color',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1360, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final descriptions = [
      'هدر مرکزی · روزهای گرد · بازهٔ نواری',
      'هدر تایپوگرافیک · خانه‌های خط‌کشی · بازهٔ زیرخط‌دار',
      'هدر دوطبقه · کاشی‌های جدا · بازهٔ خانه‌به‌خانه',
      'هدر یکپارچه · روزهای ساده · بازهٔ محصور',
      'خلاصهٔ بازه در هدر · دو سر برجسته · روزهای میانی نقطه‌دار',
      'هدر نشانه‌دار · خانه‌های باز · بازه با براکت و خط کوتاه'
    ];
    await tester.pumpWidget(host(RepaintBoundary(
        key: const Key('sheet'),
        child: ColoredBox(
            color: const Color(0xFFF0F1F3),
            child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(children: [
                  const Text('یک ماه، شش طراحی',
                      style:
                          TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text('تاریخ یکسان · بازهٔ یکسان · رنگ یکسان',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 36),
                  for (var row = 0; row < 3; row++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Builder(builder: (context) {
                                          final i = row * 2 + col,
                                              d = RoozMonthDesign.values[i];
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(d.label,
                                                    style: const TextStyle(
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 6),
                                                Text(descriptions[i],
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                                const SizedBox(height: 16),
                                                RoozMonthDesignView(
                                                    month: month,
                                                    selection: selection,
                                                    design: d,
                                                    today: month.addDays(2),
                                                    onDateTapped: (_) {},
                                                    onPreviousMonth: () {},
                                                    onNextMonth: () {}),
                                              ]);
                                        })))
                            ])),
                ]))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['PREVIEW_FONT'] != null)
      await expectLater(find.byKey(const Key('sheet')),
          matchesGoldenFile('goldens/month-designs.png'));
  });
}
