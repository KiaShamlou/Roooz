import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_flutter.dart';
import 'package:rooz_demo/main.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  final engine = Rooz.open(Platform.environment['ROOZ_LIBRARY']!);
  testWidgets('RTL reverse range, navigation, rejection and clear',
      (tester) async {
    await tester.pumpWidget(BookingApp(engine: engine));
    await tester.tap(find.byKey(const Key('day-19807')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('day-19804')));
    await tester.pump();
    expect(find.text('۱۴۰۳/۰۱/۰۳ ← ۱۴۰۳/۰۱/۰۶'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('clear-selection')));
    await tester.tap(find.byKey(const Key('clear-selection')));
    await tester.pump();
    expect(find.text('شروع و پایان بازه را انتخاب کنید'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('day-19802')));
    await tester.tap(find.byKey(const Key('day-19802')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('next-month')));
    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pump();
    expect(find.text('اردیبهشت ۱۴۰۳'), findsOneWidget);
    await tester.tap(find.byKey(const Key('day-19833')));
    await tester.pump();
    expect(find.text('این بازه معتبر نیست؛ حداکثر ۳۰ روز'), findsOneWidget);
    await tester.tap(find.byKey(const Key('previous-month')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('day-19803')));
    await tester.pump();
    expect(find.text('۱۴۰۳/۰۱/۰۱ ← ۱۴۰۳/۰۱/۰۲'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('all four calendar systems are selectable', (tester) async {
    await tester.pumpWidget(BookingApp(engine: engine));
    await tester.tap(find.byKey(const Key('calendar-system')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('میلادی').last);
    await tester.pumpAndSettle();
    expect(find.text('مارس ۲۰۲۴'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
