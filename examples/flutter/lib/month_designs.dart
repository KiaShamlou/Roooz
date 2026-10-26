import 'package:flutter/material.dart';
import 'package:rooz_calendar_flutter/rooz_month_designs.dart';

/// Separate gallery; the existing layout gallery is retained unchanged.
class MonthDesignsPage extends StatefulWidget {
  final Rooz engine;
  final Color seedColor;
  const MonthDesignsPage(
      {super.key, required this.engine, this.seedColor = Colors.teal});
  @override
  State<MonthDesignsPage> createState() => _MonthDesignsPageState();
}

class _MonthDesignsPageState extends State<MonthDesignsPage> {
  late CivilDate month = widget.engine.date(1405, 8, 1);
  DateSelection selection = const DateSelection();
  RoozMonthDesign design = RoozMonthDesign.ribbon;
  late Color seed = widget.seedColor;
  void select(CivilDate d) => setState(() => selection = selection.tap(
      d,
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
                  appBar: AppBar(title: const Text('طراحی تقویم ماهانه')),
                  body: SafeArea(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 600),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text('یک ماه، شش طراحی',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium),
                                        const SizedBox(height: 20),
                                        Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (final d
                                                  in RoozMonthDesign.values)
                                                ChoiceChip(
                                                    key: ValueKey(
                                                        'design-${d.name}'),
                                                    label: Text(d.label),
                                                    selected: design == d,
                                                    onSelected: (_) => setState(
                                                        () => design = d))
                                            ]),
                                        const SizedBox(height: 16),
                                        Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 8,
                                            children: [
                                              const Text('رنگ دلخواه:'),
                                              for (final e in {
                                                'سبز': Colors.teal,
                                                'آبی': Colors.indigo,
                                                'گرم': Colors.deepOrange
                                              }.entries)
                                                IconButton(
                                                    key: ValueKey(
                                                        'color-${e.key}'),
                                                    tooltip: e.key,
                                                    onPressed: () => setState(
                                                        () => seed = e.value),
                                                    icon: Icon(
                                                        seed == e.value
                                                            ? Icons.check_circle
                                                            : Icons.circle,
                                                        color: e.value))
                                            ]),
                                        const SizedBox(height: 24),
                                        RoozMonthDesignView(
                                            month: month,
                                            selection: selection,
                                            design: design,
                                            onDateTapped: select,
                                            isEnabled: (d) =>
                                                d.epochDay >=
                                                    widget.engine
                                                        .date(1400, 1, 1)
                                                        .epochDay &&
                                                d.epochDay <=
                                                    widget.engine
                                                        .date(1410, 12, 29)
                                                        .epochDay,
                                            onPreviousMonth: month.year ==
                                                        1400 &&
                                                    month.month == 1
                                                ? null
                                                : () => setState(() => month =
                                                    month.addMonths(-1)),
                                            onNextMonth: month.year == 1410 &&
                                                    month.month == 12
                                                ? null
                                                : () => setState(() =>
                                                    month = month.addMonths(1))),
                                        const SizedBox(height: 20),
                                        TextButton(
                                            onPressed: selection.start == null
                                                ? null
                                                : () => setState(() =>
                                                    selection =
                                                        const DateSelection()),
                                            child:
                                                const Text('پاک کردن انتخاب')),
                                      ])))))))));
}
