import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rooz_calendar_flutter/rooz_calendar.dart';
import 'package:rooz_native/rooz_native.dart' show openBundledRooz;

String colorHex(Color c) => [c.r, c.g, c.b]
    .map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0'))
    .join();

void main() => runApp(RoozPlaygroundApp(engine: openBundledRooz()));

class RoozPlaygroundApp extends StatelessWidget {
  final Rooz engine;
  final String? fontFamily;
  const RoozPlaygroundApp({super.key, required this.engine, this.fontFamily});
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF28766D),
          fontFamily: fontFamily),
      home: RoozPlaygroundPage(engine: engine, fontFamily: fontFamily));
}

/// App controls intentionally live outside the library: this is a consumer of
/// the same parameter API available to every developer, not a special renderer.
class RoozPlaygroundPage extends StatefulWidget {
  final Rooz engine;
  final String? fontFamily;
  const RoozPlaygroundPage({super.key, required this.engine, this.fontFamily});
  @override
  State<RoozPlaygroundPage> createState() => _RoozPlaygroundPageState();
}

class _RoozPlaygroundPageState extends State<RoozPlaygroundPage> {
  late final RoozCalendarController calendar;
  RoozPresentationGroup group = RoozPresentationGroup.monthly;
  RoozMonthDesign design = RoozMonthDesign.ribbon;
  RoozCalendarLayout layout = RoozCalendarLayout.month;
  RoozCalendarStyle style = RoozCalendarStyle.classic;
  Color accent = const Color(0xFF28766D);
  bool dark = false,
      narrow = false,
      expanded = false,
      single = false,
      fridayDisabled = false,
      outside = true,
      custom = false,
      dragEnd = true,
      dragStart = true,
      limitRange = false,
      animate = true;
  int maxDays = 30;
  late final TextEditingController colorText;
  String? colorError;
  RoozSelectionPolicy policy() => RoozSelectionPolicy(
      minimum: widget.engine.date(1400, 1, 1),
      maximum: widget.engine.date(1410, 12, 29),
      maxDays: limitRange ? maxDays : RoozSelectionPolicy.unlimitedDays,
      mode: single ? SelectionMode.single : SelectionMode.range,
      disabledWeekdays: fridayDisabled ? 1 << 4 : 0);
  @override
  void initState() {
    super.initState();
    colorText = TextEditingController(text: '#28766d');
    calendar = RoozCalendarController(
        initialDate: widget.engine.date(1405, 8, 14), policy: policy());
    calendar.setRange(
        widget.engine.date(1405, 8, 10), widget.engine.date(1405, 8, 18));
  }

  @override
  void dispose() {
    calendar.dispose();
    colorText.dispose();
    super.dispose();
  }

  void changePolicy(VoidCallback change) => setState(() {
        change();
        calendar.updatePolicy(policy());
      });
  void setAccent(Color color) => setState(() {
        accent = color;
        colorError = null;
        colorText.text = '#${colorHex(color)}';
      });
  String get title => switch (group) {
        RoozPresentationGroup.monthly => design.label,
        RoozPresentationGroup.layouts => layout.label,
        RoozPresentationGroup.original => switch (style) {
            RoozCalendarStyle.classic => 'کلاسیک',
            RoozCalendarStyle.glass => 'شیشه‌ای',
            RoozCalendarStyle.midnight => 'نیمه‌شب',
            RoozCalendarStyle.minimal => 'مینیمال',
          }
      };
  Future<void> exportConfig(BuildContext context) async {
    final state = {
      'schemaVersion': 1,
      'group': group.name,
      'designs': {
        'monthly': design.name,
        'layouts': layout.name,
        'original': style.name
      },
      'anchorEpochDay': calendar.anchor.epochDay,
      'selection': {
        'start': calendar.selection.start?.epochDay,
        'end': calendar.selection.end?.epochDay
      },
      'theme': {'accent': colorText.text, 'dark': dark},
      'maxDays': limitRange ? maxDays : null,
      'mode': single ? 'single' : 'range',
      'disabledWeekdays': fridayDisabled ? 16 : 0,
      'showOutsideDays': outside,
      'compactExpanded': expanded,
      'dragRangeEnd': dragEnd,
      'dragRangeStart': dragStart,
      'animateDropTarget': animate,
    };
    await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(state)));
    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تنظیمات JSON کپی شد')));
  }

  Widget section(String title, List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 14),
        ...children,
        const SizedBox(height: 20),
        const Divider(),
      ]);
  Widget controls(BuildContext context) => Card.outlined(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            section('۱ · مجموعه و طراحی', [
              for (final entry in const {
                RoozPresentationGroup.monthly: 'طراحی‌های ماهانه · ۶',
                RoozPresentationGroup.layouts: 'حالت‌های نمایش · ۶',
                RoozPresentationGroup.original: 'استایل‌ها · ۴'
              }.entries)
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ChoiceChip(
                        key: ValueKey('group-${entry.key.name}'),
                        label: Text(entry.value),
                        selected: group == entry.key,
                        onSelected: (_) => setState(() => group = entry.key))),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (group == RoozPresentationGroup.monthly)
                  for (final d in RoozMonthDesign.values)
                    ChoiceChip(
                        key: ValueKey('option-${d.name}'),
                        label: Text(d.label),
                        selected: design == d,
                        onSelected: (_) => setState(() => design = d)),
                if (group == RoozPresentationGroup.layouts)
                  for (final l in RoozCalendarLayout.values)
                    ChoiceChip(
                        key: ValueKey('option-${l.name}'),
                        label: Text(l.label),
                        selected: layout == l,
                        onSelected: (_) => setState(() => layout = l)),
                if (group == RoozPresentationGroup.original)
                  for (final entry in const {
                    RoozCalendarStyle.classic: 'کلاسیک',
                    RoozCalendarStyle.glass: 'شیشه‌ای',
                    RoozCalendarStyle.midnight: 'نیمه‌شب',
                    RoozCalendarStyle.minimal: 'مینیمال'
                  }.entries)
                    ChoiceChip(
                        key: ValueKey('option-${entry.key.name}'),
                        label: Text(entry.value),
                        selected: style == entry.key,
                        onSelected: (_) => setState(() => style = entry.key)),
              ]),
              const SizedBox(height: 12),
              const Text('انتخاب بازه با تغییر طراحی حفظ می‌شود.',
                  style: TextStyle(fontSize: 12)),
            ]),
            section('۲ · ظاهر قابل تنظیم', [
              Wrap(spacing: 8, children: [
                for (final color in const [
                  Color(0xFF28766D),
                  Color(0xFF6263A7),
                  Color(0xFF865A84),
                  Color(0xFFAE643F),
                  Color(0xFF343B42)
                ])
                  IconButton(
                      key: ValueKey('accent-${colorHex(color)}'),
                      tooltip: '#${colorHex(color)}',
                      onPressed: () => setAccent(color),
                      icon: Icon(
                          color == accent ? Icons.check_circle : Icons.circle,
                          color: color))
              ]),
              TextField(
                  controller: colorText,
                  key: const Key('accent-hex'),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                      labelText: 'رنگ دلخواه HEX', errorText: colorError),
                  onSubmitted: (value) {
                    final hex = value.trim().replaceFirst('#', '');
                    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex))
                      setAccent(Color(int.parse('ff$hex', radix: 16)));
                    else
                      setState(() => colorError = 'شش رقم رنگ وارد کنید');
                  }),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('زمینهٔ تیره'),
                  value: dark,
                  key: const Key('dark-toggle'),
                  onChanged: (v) => setState(() => dark = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض موبایل'),
                  value: narrow,
                  key: const Key('narrow-toggle'),
                  onChanged: (v) => setState(() => narrow = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('روزهای ماه مجاور'),
                  value: outside,
                  onChanged: (v) => setState(() => outside = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('محتوای سفارشی روز'),
                  value: custom,
                  onChanged: (v) => setState(() => custom = v)),
            ]),
            section('۳ · رفتار و محدودیت‌ها', [
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('کشیدن شروع بازه'),
                  value: dragStart,
                  onChanged: (v) => setState(() => dragStart = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('کشیدن پایان بازه'),
                  value: dragEnd,
                  onChanged: (v) => setState(() => dragEnd = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('انیمیشن مقصد'),
                  value: animate,
                  onChanged: (v) => setState(() => animate = v)),
              const Text(
                  'ماوس: هر سر بازه را بکشید. لمس: نگه دارید و بکشید. سر دیگر ثابت می‌ماند.'),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('انتخاب تک‌روز'),
                  value: single,
                  onChanged: (v) => changePolicy(() => single = v)),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('غیرفعال کردن جمعه‌ها'),
                  value: fridayDisabled,
                  onChanged: (v) => changePolicy(() => fridayDisabled = v)),
              SwitchListTile(
                  key: const Key('limit-range-toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('محدودیت طول بازه'),
                  value: limitRange,
                  onChanged: (v) => changePolicy(() => limitRange = v)),
              Text(limitRange
                  ? 'حداکثر طول بازه: $maxDays روز (با احتساب دو سر)'
                  : 'طول بازه: بدون محدودیت'),
              Slider(
                  key: const Key('max-days'),
                  value: maxDays.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  onChanged: limitRange
                      ? (v) => changePolicy(() => maxDays = v.round())
                      : null),
              OutlinedButton(
                  key: const Key('sample-range'),
                  onPressed: () {
                    final first = calendar.month.addDays(9);
                    calendar.setRange(first, first.addDays(single ? 0 : 8));
                  },
                  child: const Text('بازهٔ نمونه')),
              TextButton(
                  onPressed: () =>
                      calendar.goTo(widget.engine.date(1405, 8, 14)),
                  child: const Text('بازگشت به آبان ۱۴۰۵')),
            ]),
          ])));
  Widget preview(BuildContext context) => AnimatedBuilder(
      animation: calendar,
      builder: (context, _) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('موشن ۳ · تغییر هر دو سر بازه · بدون سقف طول پیش‌فرض'),
            const SizedBox(height: 20),
            Container(
                padding: EdgeInsets.all(narrow ? 8 : 20),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(28)),
                child: Center(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: narrow ? 360 : 620),
                        child: RoozCalendar(
                          controller: calendar,
                          motion: RoozCalendarMotion(
                              dragRangeStart: dragStart,
                              dragRangeEnd: dragEnd,
                              duration:
                                  Duration(milliseconds: animate ? 160 : 0),
                              hoverScale: animate ? 1.06 : 1),
                          options: RoozCalendarOptions(
                              group: group,
                              design: design,
                              layout: layout,
                              style: style,
                              accent: accent,
                              dark: dark,
                              showOutsideDays: outside,
                              weekdayLabels: const [
                                'ش',
                                'ی',
                                'د',
                                'س',
                                'چ',
                                'پ',
                                'ج'
                              ]),
                          compactExpanded: expanded,
                          onExpandedChanged: (v) =>
                              setState(() => expanded = v),
                          onMonthSelected: (m) {
                            calendar.goTo(m);
                            setState(() => layout = RoozCalendarLayout.month);
                          },
                          events: {
                            widget.engine.date(1405, 8, 11).epochDay: [
                              'رویداد نمونه'
                            ],
                            widget.engine.date(1405, 8, 18).epochDay: [
                              'تحویل نمونه'
                            ]
                          },
                          dayBuilder: custom
                              ? (context, day) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(day.date.format(pattern: '%d'),
                                            style: TextStyle(
                                                fontWeight: day.selected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal)),
                                        Icon(
                                            day.selected
                                                ? Icons.check
                                                : Icons.remove,
                                            size: 10),
                                      ])
                              : null,
                          errorBuilder: (_) => (limitRange
                              ? 'انتخاب معتبر نیست؛ محدودیت روزها و حداکثر $maxDays روز را بررسی کنید.'
                              : 'انتخاب معتبر نیست؛ تاریخ‌های مجاز و روزهای غیرفعال را بررسی کنید.'),
                          onConfirm: (selection) => ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      'تأیید شد: ${selection.start!.format()} تا ${selection.end!.format()}'))),
                        )))),
            const SizedBox(height: 20),
            Card.outlined(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('بازهٔ انتخاب‌شده',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 20, runSpacing: 10, children: [
                            Text(
                                'از: ${calendar.selection.start?.format() ?? '—'}',
                                key: const Key('range-start')),
                            Text(
                                'تا: ${calendar.selection.end?.format() ?? '—'}',
                                key: const Key('range-end')),
                            Text('${calendar.inclusiveDays ?? 0} روز',
                                key: const Key('range-length')),
                          ]),
                        ]))),
          ]));
  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData(
          useMaterial3: true,
          fontFamily: widget.fontFamily,
          colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: dark ? Brightness.dark : Brightness.light)),
      child: Builder(
          builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                  backgroundColor:
                      dark ? const Color(0xFF10191D) : const Color(0xFFF4F5F7),
                  body: SafeArea(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1100),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 16,
                                            runSpacing: 12,
                                            children: [
                                              const Text(
                                                  'روز / آزمایشگاه تقویم',
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                              OutlinedButton.icon(
                                                  onPressed: () =>
                                                      exportConfig(context),
                                                  icon: const Icon(Icons.copy,
                                                      size: 16),
                                                  label: const Text(
                                                      'خروجی تنظیمات'))
                                            ]),
                                        const SizedBox(height: 24),
                                        LayoutBuilder(
                                            builder: (context, constraints) =>
                                                constraints.maxWidth >= 900
                                                    ? Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                            SizedBox(
                                                                width: 300,
                                                                child: controls(
                                                                    context)),
                                                            const SizedBox(
                                                                width: 24),
                                                            Expanded(
                                                                child: preview(
                                                                    context))
                                                          ])
                                                    : Column(children: [
                                                        preview(context),
                                                        const SizedBox(
                                                            height: 24),
                                                        controls(context)
                                                      ])),
                                      ])))))))));
}
