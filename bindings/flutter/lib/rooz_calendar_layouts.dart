import 'package:flutter/material.dart';
import 'rooz_calendar_flutter.dart';
import 'rooz_calendar_customization.dart';
export 'rooz_calendar_flutter.dart';

/// Structural layouts, not color presets. Every color comes from ColorScheme.
enum RoozCalendarLayout { month, week, agenda, split, compact, year }

extension RoozCalendarLayoutName on RoozCalendarLayout {
  String get label => switch (this) {
        RoozCalendarLayout.month => 'ماهانه',
        RoozCalendarLayout.week => 'نوار هفتگی',
        RoozCalendarLayout.agenda => 'فهرست روزها',
        RoozCalendarLayout.split => 'دو‌بخشی',
        RoozCalendarLayout.compact => 'جمع‌شونده',
        RoozCalendarLayout.year => 'سالانه',
      };
}

/// Caller owns the displayed date, selection and event data. Only disclosure
/// and year drill-down are local presentation state. No date engine is replaced.
class RoozCalendarLayouts extends StatefulWidget {
  final CivilDate date;
  final DateSelection selection;
  final RoozCalendarLayout layout;
  final ValueChanged<CivilDate> onDateTapped;
  final ValueChanged<CivilDate>? onNavigate;
  final bool Function(CivilDate)? isEnabled, canNavigate;
  final Map<int, List<String>> events;
  final bool initiallyExpanded;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final ValueChanged<CivilDate>? onMonthSelected;
  final int firstWeekday;
  final List<String> weekdayLabels;
  final RoozLocale locale;
  final DigitSet digits;
  final String previousLabel,
      nextLabel,
      emptyLabel,
      eventsLabel,
      noEventsLabel,
      yearLabel;
  final String Function(CivilDate)? labelBuilder;
  const RoozCalendarLayouts({
    super.key,
    required this.date,
    required this.selection,
    required this.onDateTapped,
    this.onNavigate,
    this.isEnabled,
    this.canNavigate,
    this.layout = RoozCalendarLayout.month,
    this.events = const {},
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
    this.onMonthSelected,
    this.firstWeekday = 6,
    this.weekdayLabels = const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    this.locale = RoozLocale.persian,
    this.digits = DigitSet.persian,
    this.previousLabel = 'قبلی',
    this.nextLabel = 'بعدی',
    this.emptyLabel = 'انتخاب تاریخ',
    this.eventsLabel = 'برنامه‌های روز',
    this.noEventsLabel = 'برنامه‌ای ثبت نشده',
    this.yearLabel = 'نمای سال',
    this.labelBuilder,
  })  : assert(weekdayLabels.length == 7),
        assert(firstWeekday >= 1 && firstWeekday <= 7);
  @override
  State<RoozCalendarLayouts> createState() => _RoozCalendarLayoutsState();
}

class _RoozCalendarLayoutsState extends State<RoozCalendarLayouts> {
  late bool _expanded = widget.initiallyExpanded;
  bool get expanded => widget.expanded ?? _expanded;
  bool yearDetail = false;
  @override
  void didUpdateWidget(covariant RoozCalendarLayouts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _expanded = widget.initiallyExpanded;
      yearDetail = false;
    }
  }

  ColorScheme get colors => Theme.of(context).colorScheme;
  String fmt(CivilDate d, String pattern) =>
      d.format(pattern: pattern, locale: widget.locale, digits: widget.digits);
  String day(CivilDate d) => fmt(d, '%d').replaceFirst(RegExp(r'^[0۰٠]'), '');
  CivilDate? safeDay(CivilDate d, int offset) {
    try {
      return d.addDays(offset);
    } on RoozException {
      return null;
    }
  }

  CivilDate? shifted(int amount, {bool byWeek = false}) {
    try {
      final date = byWeek
          ? widget.date.addDays(amount * 7)
          : widget.date.addMonths(amount);
      return widget.canNavigate?.call(date) == false ? null : date;
    } on RoozException {
      return null;
    }
  }

  CivilDate get focusDate =>
      widget.selection.end ?? widget.selection.start ?? widget.date;
  String get selectionText => widget.selection.start == null
      ? widget.emptyLabel
      : widget.selection.end == null
          ? fmt(widget.selection.start!, '%d %B')
          : '${fmt(widget.selection.start!, '%d %B')} — ${fmt(widget.selection.end!, '%d %B')}';
  Widget header({bool week = false, bool year = false}) => roozCustomHeader(
      context, widget.date, defaultHeader(week: week, year: year));
  Widget defaultHeader({bool week = false, bool year = false}) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final step = year ? 12 : 1;
    final previous = shifted(-step, byWeek: week),
        next = shifted(step, byWeek: week);
    return Row(children: [
      Expanded(
          child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(fmt(widget.date, year ? '%Y' : '%B %Y'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)))),
      IconButton(
          tooltip: widget.previousLabel,
          onPressed: widget.onNavigate == null || previous == null
              ? null
              : () => widget.onNavigate!(previous),
          icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left)),
      IconButton(
          tooltip: widget.nextLabel,
          onPressed: widget.onNavigate == null || next == null
              ? null
              : () => widget.onNavigate!(next),
          icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right)),
    ]);
  }

  Widget surface(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(20)}) =>
      Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  RoozCalendarCustomization.maybeOf(context)?.cardRadius ?? 24),
              side: BorderSide(color: colors.outlineVariant)),
          child: Padding(
              padding:
                  RoozCalendarCustomization.maybeOf(context)?.contentPadding ??
                      padding,
              child: child));
  @override
  Widget build(BuildContext context) => switch (widget.layout) {
        RoozCalendarLayout.month => surface(month()),
        RoozCalendarLayout.week => surface(week()),
        RoozCalendarLayout.agenda => surface(agenda()),
        RoozCalendarLayout.split => surface(split()),
        RoozCalendarLayout.compact => surface(compact()),
        RoozCalendarLayout.year => surface(year()),
      };
  Widget month({bool footer = true}) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        header(),
        const SizedBox(height: 12),
        grid(),
        if (footer) ...[
          const SizedBox(height: 12),
          const Divider(),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                  liveRegion: true,
                  child: Text(selectionText,
                      style: TextStyle(
                          color: colors.brightness == Brightness.dark
                              ? colors.onSurface
                              : colors.primary,
                          fontWeight: FontWeight.w600))))
        ],
      ]);
  Widget grid() {
    final days = widget.date.monthGrid(firstWeekday: widget.firstWeekday);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        for (final name in widget.weekdayLabels)
          Expanded(
              child: Center(
                  child: Text(name,
                      style: TextStyle(
                          color: colors.onSurfaceVariant, fontSize: 12))))
      ]),
      const SizedBox(height: 8),
      for (var row = 0; row < 6; row++)
        Row(children: [
          for (var col = 0; col < 7; col++)
            Expanded(child: dayCell(days[row * 7 + col]))
        ]),
    ]);
  }

  Widget dayCell(CivilDate? d, {bool tall = false}) => roozCustomDay(context,
      date: d,
      month: widget.date,
      selection: widget.selection,
      enabled: d != null && (widget.isEnabled?.call(d) ?? true),
      onTap: widget.onDateTapped,
      label: d == null
          ? ''
          : (widget.labelBuilder?.call(d) ?? fmt(d, '%A %d %B %Y')),
      fallback: () => defaultDayCell(d, tall: tall));
  Widget defaultDayCell(CivilDate? d, {bool tall = false}) {
    if (d == null) return SizedBox(height: tall ? 92 : 48);
    final enabled = widget.isEnabled?.call(d) ?? true;
    final selected = widget.selection.contains(d);
    final inMonth = d.month == widget.date.month && d.year == widget.date.year;
    final hasEvents = widget.events[d.epochDay]?.isNotEmpty ?? false;
    return Padding(
        padding: const EdgeInsets.all(2),
        child: Semantics(
            selected: selected,
            label: widget.labelBuilder?.call(d) ?? fmt(d, '%A %d %B %Y'),
            child: TextButton(
                key: ValueKey('layout-day-${d.epochDay}'),
                onPressed: enabled ? () => widget.onDateTapped(d) : null,
                style: TextButton.styleFrom(
                    minimumSize: Size(0, tall ? 92 : 44),
                    padding: EdgeInsets.symmetric(vertical: tall ? 14 : 9),
                    backgroundColor: selected
                        ? colors.primary
                        : tall
                            ? colors.surfaceContainerLow
                            : null,
                    foregroundColor: selected
                        ? colors.onPrimary
                        : inMonth
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tall ? 24 : 12))),
                child: ExcludeSemantics(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (tall) ...[
                    Text(fmt(d, '%A'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 12)
                  ],
                  Text(day(d),
                      style: TextStyle(
                          fontSize: tall ? 21 : 16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500)),
                  if (tall) ...[
                    const SizedBox(height: 10),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEvents
                                ? selected
                                    ? colors.onPrimary
                                    : colors.primary
                                : Colors.transparent))
                  ],
                ])))));
  }

  Widget detail(CivilDate d) {
    final entries = widget.events[d.epochDay] ?? const <String>[];
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fmt(d, '%A'),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          Text(fmt(d, '%d %B'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text(widget.eventsLabel,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(widget.noEventsLabel,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          for (final title in entries)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(title,
                        style: TextStyle(
                            color: colors.onPrimaryContainer, fontSize: 13)))),
        ]);
  }

  Widget week() {
    final delta = (widget.date.weekday - widget.firstWeekday + 7) % 7;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(week: true),
          const SizedBox(height: 18),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                  child: dayCell(safeDay(widget.date, i - delta), tall: true))
          ]),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          detail(focusDate),
        ]);
  }

  Widget agenda() {
    final first = widget.date.addDays(1 - widget.date.day);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      header(),
      const SizedBox(height: 12),
      SizedBox(
          height: 330,
          child: ListView.separated(
              key: const ValueKey('agenda-list'),
              itemCount: widget.date.monthLength,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = first.addDays(i),
                    enabled = widget.isEnabled?.call(first.addDays(i)) ?? true;
                final selected = widget.selection.contains(d),
                    entries = widget.events[d.epochDay] ?? const <String>[];
                return roozCustomDay(context,
                    date: d,
                    month: widget.date,
                    selection: widget.selection,
                    enabled: enabled,
                    onTap: widget.onDateTapped,
                    label:
                        widget.labelBuilder?.call(d) ?? fmt(d, '%A %d %B %Y'),
                    fallback: () => Semantics(
                        selected: selected,
                        label: widget.labelBuilder?.call(d) ??
                            fmt(d, '%A %d %B %Y'),
                        child: ListTile(
                            key: ValueKey('agenda-day-${d.epochDay}'),
                            enabled: enabled,
                            onTap:
                                enabled ? () => widget.onDateTapped(d) : null,
                            selected: selected,
                            selectedTileColor: colors.primaryContainer,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            leading: Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(day(d),
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary))),
                            title: Text(fmt(d, '%A'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(entries.isEmpty
                                ? widget.noEventsLabel
                                : entries.join(' • ')),
                            trailing: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.chevron_left,
                                size: 20))));
              })),
    ]);
  }

  Widget split() => LayoutBuilder(builder: (context, constraints) {
        final panel = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20)),
            child: detail(focusDate));
        if (constraints.maxWidth < 470)
          return Column(mainAxisSize: MainAxisSize.min, children: [
            month(footer: false),
            const SizedBox(height: 20),
            panel
          ]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: month(footer: false)),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: panel),
        ]);
      });
  Widget compact() => Column(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
            expanded: expanded,
            child: OutlinedButton(
                key: const ValueKey('calendar-disclosure'),
                onPressed: () {
                  final value = !expanded;
                  if (widget.expanded == null)
                    setState(() => _expanded = value);
                  widget.onExpandedChanged?.call(value);
                },
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(selectionText)),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more)
                ]))),
        if (expanded) ...[const SizedBox(height: 20), month(footer: false)],
      ]);
  Widget year() {
    if (yearDetail)
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
                key: const ValueKey('back-to-year'),
                onPressed: () => setState(() => yearDetail = false),
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text(widget.yearLabel))),
        month(),
      ]);
    final first = widget.date.engine
        .date(widget.date.year, 1, 1, calendar: widget.date.calendar);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      header(year: true),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 330 ? 2 : 3;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          for (var row = 0; row < 12 ~/ columns; row++)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var col = 0; col < columns; col++)
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Builder(builder: (context) {
                          final m = first.addMonths(row * columns + col),
                              active = m.month == widget.date.month;
                          return OutlinedButton(
                              key: ValueKey('year-month-${m.month}'),
                              onPressed: widget.onNavigate == null ||
                                      widget.canNavigate?.call(m) == false
                                  ? null
                                  : () {
                                      if (widget.onMonthSelected != null) {
                                        widget.onMonthSelected!(m);
                                      } else {
                                        setState(() => yearDetail = true);
                                        widget.onNavigate!(m);
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      active ? colors.primaryContainer : null,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                              child: Column(children: [
                                Text(fmt(m, '%B'),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Text(fmt(m, '%Y'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurfaceVariant))
                              ]));
                        })))
            ]),
        ]);
      }),
    ]);
  }
}
