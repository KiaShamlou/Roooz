import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_styled_calendar.dart';

void main() {
  setUpAll(() async {
    final icons = Platform.environment['PREVIEW_ICONS'];
    if (icons != null) {
      final loader = FontLoader('MaterialIcons');
      loader.addFont(
          Future.value(ByteData.sublistView(await File(icons).readAsBytes())));
      await loader.load();
    }
    final latin = Platform.environment['PREVIEW_LATIN'];
    if (latin != null) {
      final loader = FontLoader('PreviewLatin');
      loader.addFont(
          Future.value(ByteData.sublistView(await File(latin).readAsBytes())));
      await loader.load();
    }
    final font = Platform.environment['PREVIEW_FONT'];
    if (font != null) {
      final loader = FontLoader('PreviewFont');
      loader.addFont(
          Future.value(ByteData.sublistView(await File(font).readAsBytes())));
      await loader.load();
    }
  });
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  final month = engine.date(1405, 8, 1);
  final rules = RangeRules(minimum: month, maximum: month.addDays(29));
  final range = const DateSelection()
      .tap(month.addDays(9), rules)
      .tap(month.addDays(13), rules);
  Widget host(Widget child,
          {double scale = 1, TextDirection direction = TextDirection.rtl}) =>
      MaterialApp(
          theme: ThemeData(
              fontFamilyFallback: const ['PreviewLatin'],
              cupertinoOverrideTheme: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                      actionTextStyle: TextStyle(
                          fontFamily:
                              Platform.environment['PREVIEW_FONT'] == null
                                  ? null
                                  : 'PreviewFont',
                          fontFamilyFallback: const ['PreviewLatin']),
                      textStyle: TextStyle(
                          fontFamily:
                              Platform.environment['PREVIEW_FONT'] == null
                                  ? null
                                  : 'PreviewFont',
                          fontFamilyFallback: const ['PreviewLatin']))),
              fontFamily:
                  Platform.environment['PREVIEW_FONT'] == null ? null : 'PreviewFont'),
          home: Directionality(textDirection: direction, child: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: Scaffold(body: SingleChildScrollView(child: child)))));

  for (final style in RoozCalendarStyle.values) {
    testWidgets('${style.name}: selection, disabled dates and navigation',
        (tester) async {
      CivilDate? tapped;
      var previous = 0, next = 0, cleared = 0;
      await tester.pumpWidget(host(SizedBox(
          width: 360,
          child: RoozStyledCalendar(
            month: month,
            selection: range,
            style: style,
            today: month.addDays(2),
            onDateTapped: (d) => tapped = d,
            isEnabled: (d) => d.epochDay != month.epochDay,
            onPreviousMonth: () => previous++,
            onNextMonth: () => next++,
            onClear: () => cleared++,
          ))));
      expect(find.byType(CupertinoButton), findsNWidgets(45));
      expect(
          find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.selected == true),
          findsNWidgets(5));
      await tester.tap(find.byKey(ValueKey('rooz-day-${month.epochDay}')));
      expect(tapped, isNull);
      await tester.tap(find.byKey(ValueKey('rooz-day-${month.epochDay + 1}')));
      expect(tapped, month.addDays(1));
      await tester.tap(find.byTooltip('ماه قبل'));
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.tap(find.text('پاک کردن'));
      expect([previous, next, cleared], [1, 1, 1]);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('narrow, large text and LTR do not overflow', (tester) async {
    await tester.pumpWidget(host(
        SizedBox(
            width: 320,
            child: RoozStyledCalendar(
              month: month,
              selection: range,
              onDateTapped: (_) {},
              onClear: () {},
            )),
        scale: 2,
        direction: TextDirection.ltr));
    expect(tester.takeException(), isNull);
  });
  testWidgets('boundary blanks and empty selection', (tester) async {
    final boundary = engine.date(1, 1, 1);
    await tester.pumpWidget(host(RoozStyledCalendar(
        month: boundary,
        selection: const DateSelection(),
        onDateTapped: (_) {},
        onClear: () {})));
    expect(
        find.byType(CupertinoButton),
        findsNWidgets(
            boundary.monthGrid(firstWeekday: 6).whereType<CivilDate>().length +
                3));
    expect(
        tester
            .widget<CupertinoButton>(
                find.widgetWithText(CupertinoButton, 'پاک کردن'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('four original style contact sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1060, 1560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final styles = [
      RoozCalendarStyle.classic,
      RoozCalendarStyle.glass,
      RoozCalendarStyle.midnight,
      RoozCalendarStyle.minimal
    ];
    final titles = ['کلاسیک', 'شیشه‌ای', 'نیمه‌شب', 'فقط روزها'];
    await tester.pumpWidget(host(RepaintBoundary(
        key: const Key('sheet'),
        child: ColoredBox(
            color: const Color(0xFFE9E9EF),
            child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(children: [
                  const Text('روز، به سبک تو',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 10),
                  const Text('چهار طراحی برای یک تقویم',
                      style: TextStyle(fontSize: 15, color: Color(0xFF74747C))),
                  const SizedBox(height: 32),
                  for (var row = 0; row < 2; row++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Builder(builder: (context) {
                                          final i = row * 2 + col;
                                          final style = styles[i];
                                          final p =
                                              RoozCalendarPalette.of(style);
                                          return Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      22, 24, 22, 24),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(38),
                                                  color: style ==
                                                          RoozCalendarStyle
                                                              .midnight
                                                      ? const Color(0xFF000000)
                                                      : style ==
                                                              RoozCalendarStyle
                                                                  .minimal
                                                          ? const Color(
                                                              0xFFFFFFFF)
                                                          : const Color(
                                                              0xFFF5F5FA),
                                                  gradient: style ==
                                                          RoozCalendarStyle
                                                              .glass
                                                      ? const LinearGradient(
                                                          colors: [
                                                              Color(0xFFE5DEFB),
                                                              Color(0xFFD9EAF6),
                                                              Color(0xFFEFE4F2)
                                                            ],
                                                          begin: Alignment
                                                              .topRight,
                                                          end: Alignment
                                                              .bottomLeft)
                                                      : null),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Row(children: [
                                                      Expanded(
                                                          child: Text(titles[i],
                                                              style: TextStyle(
                                                                  fontSize: 24,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color:
                                                                      p.ink))),
                                                      Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          size: 20,
                                                          color: p.accent)
                                                    ]),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                        'زمانی برای آنچه دوست داری',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: p.muted)),
                                                    const SizedBox(height: 24),
                                                    RoozStyledCalendar(
                                                        month: month,
                                                        selection: range,
                                                        style: style,
                                                        today: month.addDays(2),
                                                        onDateTapped: (_) {},
                                                        onPreviousMonth: () {},
                                                        onNextMonth: () {},
                                                        onClear: () {}),
                                                    const SizedBox(height: 20),
                                                    CupertinoButton(
                                                        color: p.accent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        onPressed: () {},
                                                        child: Text(
                                                            'تأیید بازه',
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color:
                                                                    p.onAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600))),
                                                  ]));
                                        }))),
                            ])),
                ]))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['PREVIEW_FONT'] != null) {
      await expectLater(find.byKey(const Key('sheet')),
          matchesGoldenFile('goldens/calendar-styles.png'));
    }
  });
}
