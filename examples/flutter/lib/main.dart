import 'package:flutter/material.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_flutter.dart';
import 'package:rooz_native/rooz_native.dart' show openBundledRooz;

void main() => runApp(BookingApp(engine: openBundledRooz()));

class BookingApp extends StatelessWidget {
  final Rooz engine;
  const BookingApp({super.key, required this.engine});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true),
        home: BookingPage(engine: engine),
      );
}

class BookingPage extends StatefulWidget {
  final Rooz engine;
  const BookingPage({super.key, required this.engine});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late CivilDate month = widget.engine.date(1403, 1, 1);
  DateSelection selection = const DateSelection();
  String message = 'شروع و پایان بازه را انتخاب کنید';
  late final minimum = widget.engine.date(1400, 1, 1);
  late final maximum = widget.engine.date(1410, 12, 29);
  late final rules =
      RangeRules(minimum: minimum, maximum: maximum, maxLength: 30);
  void select(CivilDate date) {
    setState(() {
      try {
        selection = selection.tap(date, rules);
        message = selection.isComplete
            ? '${selection.start!.format()} ← ${selection.end!.format()}'
            : 'تاریخ پایان را انتخاب کنید';
      } on RoozException {
        message = 'این بازه معتبر نیست؛ حداکثر ۳۰ روز';
      }
    });
  }

  void navigate(int amount) => setState(() {
        month = month.addMonths(amount);
      });
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('روز · Roooz',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    const Text('یک هسته، تقویم‌های مختلف · انتخاب بازه'),
                    const SizedBox(height: 24),
                    DropdownButton<CalendarSystem>(
                      key: const Key('calendar-system'),
                      value: month.calendar,
                      isExpanded: true,
                      items: [
                        for (final entry in const {
                          CalendarSystem.jalali: 'جلالی',
                          CalendarSystem.gregorian: 'میلادی',
                          CalendarSystem.islamicCivil: 'هجری قمری محاسباتی',
                          CalendarSystem.julian: 'ژولینی',
                        }.entries)
                          DropdownMenuItem(
                              value: entry.key, child: Text(entry.value))
                      ],
                      onChanged: (calendar) {
                        if (calendar != null)
                          setState(() {
                            final converted = month.convertTo(calendar);
                            month = widget.engine.date(
                                converted.year, converted.month, 1,
                                calendar: calendar);
                            selection = const DateSelection();
                            message = 'شروع و پایان بازه را انتخاب کنید';
                          });
                      },
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              key: const Key('previous-month'),
                              onPressed: () => navigate(-1),
                              child: const Text('ماه قبل')),
                          Flexible(
                              child: Text(month.format(pattern: '%B %Y'),
                                  key: const Key('month-title'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          TextButton(
                              key: const Key('next-month'),
                              onPressed: () => navigate(1),
                              child: const Text('ماه بعد')),
                        ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      for (final day in ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'])
                        Expanded(child: Center(child: Text(day)))
                    ]),
                    RoozMonthView(
                      month: month,
                      selection: selection,
                      isEnabled: (d) =>
                          d.epochDay >= minimum.epochDay &&
                          d.epochDay <= maximum.epochDay,
                      onDateTapped: select,
                      dayBuilder: (_, date, selected, inMonth, enabled) => Text(
                        date.format(pattern: '%d'),
                        key: Key('day-${date.epochDay}'),
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: inMonth
                                ? null
                                : Theme.of(context).disabledColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(message,
                        key: const Key('selection-status'),
                        textAlign: TextAlign.center),
                    TextButton(
                        key: const Key('clear-selection'),
                        onPressed: () => setState(() {
                              selection = const DateSelection();
                              message = 'شروع و پایان بازه را انتخاب کنید';
                            }),
                        child: const Text('پاک کردن انتخاب')),
                    const Divider(),
                    const Text(
                        'جلالی: الگوریتم Borkowski • بازه شامل هر دو روز ابتدا و انتهاست',
                        textAlign: TextAlign.center),
                  ],
                )),
          )),
        ))),
      );
}
