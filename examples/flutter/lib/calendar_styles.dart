import 'package:flutter/material.dart';
import 'package:rooz_calendar_flutter/rooz_calendar_layouts.dart';

class CalendarStylesPage extends StatefulWidget {
  final Rooz engine;
  final Color seedColor;
  const CalendarStylesPage(
      {super.key,
      required this.engine,
      this.seedColor = const Color(0xFF41615A)});
  @override
  State<CalendarStylesPage> createState() => _CalendarStylesPageState();
}

class _CalendarStylesPageState extends State<CalendarStylesPage> {
  late CivilDate date = widget.engine.date(1405, 8, 14);
  DateSelection selection = const DateSelection();
  RoozCalendarLayout layout = RoozCalendarLayout.month;
  late Color seed = widget.seedColor;
  void select(CivilDate day) => setState(() => selection = selection.tap(
      day,
      RangeRules(
          minimum: widget.engine.date(1400, 1, 1),
          maximum: widget.engine.date(1410, 12, 29))));
  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          textTheme: Theme.of(context).textTheme),
      child: Builder(
          builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                appBar: AppBar(title: const Text('روز · انتخاب چیدمان')),
                body: SafeArea(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 760),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('شش شکل، رنگ دلخواه تو.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 20),
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final item
                                                in RoozCalendarLayout.values)
                                              ChoiceChip(
                                                  key: ValueKey(
                                                      'layout-${item.name}'),
                                                  label: Text(item.label),
                                                  selected: layout == item,
                                                  onSelected: (_) => setState(
                                                      () => layout = item))
                                          ]),
                                      const SizedBox(height: 18),
                                      Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 8,
                                          children: [
                                            const Text('رنگ مستقل از چیدمان:'),
                                            for (final entry in {
                                              'سبز': const Color(0xFF41615A),
                                              'آبی': Colors.indigo,
                                              'گرم': Colors.deepOrange
                                            }.entries)
                                              IconButton(
                                                  key: ValueKey(
                                                      'theme-${entry.key}'),
                                                  tooltip: entry.key,
                                                  onPressed: () => setState(
                                                      () => seed = entry.value),
                                                  icon: Icon(
                                                      seed == entry.value
                                                          ? Icons.check_circle
                                                          : Icons.circle,
                                                      color: entry.value)),
                                          ]),
                                      const SizedBox(height: 24),
                                      RoozCalendarLayouts(
                                          date: date,
                                          selection: selection,
                                          layout: layout,
                                          onDateTapped: select,
                                          onNavigate: (next) =>
                                              setState(() => date = next),
                                          isEnabled: (d) =>
                                              d.epochDay >=
                                                  widget.engine
                                                      .date(1400, 1, 1)
                                                      .epochDay &&
                                              d.epochDay <=
                                                  widget.engine
                                                      .date(1410, 12, 29)
                                                      .epochDay,
                                          events: {
                                            widget.engine
                                                .date(1405, 8, 14)
                                                .epochDay: [
                                              '۰۹:۳۰ · جلسهٔ تیم',
                                              '۱۶:۰۰ · مرور طراحی'
                                            ]
                                          }),
                                      const SizedBox(height: 24),
                                      FilledButton(
                                          onPressed: selection.isComplete
                                              ? () => showDialog<void>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                          title: const Text(
                                                              'بازهٔ انتخاب‌شده'),
                                                          content: Text(
                                                              '${selection.start!.format()} — ${selection.end!.format()}'),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child:
                                                                    const Text(
                                                                        'تمام'))
                                                          ]))
                                              : null,
                                          child: const Padding(
                                              padding: EdgeInsets.all(14),
                                              child: Text('تأیید بازه'))),
                                    ]))))),
              ))));
}
