import 'package:flutter/material.dart';
import 'rooz_calendar_flutter.dart';
import 'rooz_calendar_customization.dart';
export 'rooz_calendar_flutter.dart';

/// Six visual treatments of the SAME 42-cell month grid, not display modes.
enum RoozMonthDesign { ribbon, ledger, tiles, frame, floating, brackets }

extension RoozMonthDesignName on RoozMonthDesign {
  String get label => switch (this) {
        RoozMonthDesign.ribbon => 'روبان',
        RoozMonthDesign.ledger => 'دفتر',
        RoozMonthDesign.tiles => 'کاشی',
        RoozMonthDesign.frame => 'قاب',
        RoozMonthDesign.floating => 'شناور',
        RoozMonthDesign.brackets => 'براکت',
      };
}

/// All colors derive from the caller's ColorScheme. State remains caller-owned.
class RoozMonthDesignView extends StatelessWidget {
  final CivilDate month;
  final DateSelection selection;
  final RoozMonthDesign design;
  final ValueChanged<CivilDate> onDateTapped;
  final VoidCallback? onPreviousMonth, onNextMonth;
  final bool Function(CivilDate)? isEnabled;
  final CivilDate? today;
  final int firstWeekday;
  final List<String> weekdayLabels;
  final RoozLocale locale;
  final DigitSet digits;
  final String previousLabel, nextLabel, emptyLabel;
  final String Function(CivilDate)? labelBuilder;
  const RoozMonthDesignView({
    super.key,
    required this.month,
    required this.selection,
    required this.onDateTapped,
    this.design = RoozMonthDesign.ribbon,
    this.onPreviousMonth,
    this.onNextMonth,
    this.isEnabled,
    this.today,
    this.firstWeekday = 6,
    this.weekdayLabels = const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    this.locale = RoozLocale.persian,
    this.digits = DigitSet.persian,
    this.previousLabel = 'ماه قبل',
    this.nextLabel = 'ماه بعد',
    this.emptyLabel = 'انتخاب بازه',
    this.labelBuilder,
  })  : assert(weekdayLabels.length == 7),
        assert(firstWeekday >= 1 && firstWeekday <= 7);
  String f(CivilDate d, String pattern) =>
      d.format(pattern: pattern, locale: locale, digits: digits);
  String get summary => selection.start == null
      ? emptyLabel
      : selection.end == null
          ? f(selection.start!, '%d %B')
          : '${f(selection.start!, '%d %B')} — ${f(selection.end!, '%d %B')}';
  bool get ruled => design == RoozMonthDesign.ledger;
  bool get tiled => design == RoozMonthDesign.tiles;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final days = month.monthGrid(firstWeekday: firstWeekday);
    final radius = RoozCalendarCustomization.maybeOf(context)?.cardRadius ??
        (ruled
            ? 4.0
            : tiled
                ? 18.0
                : design == RoozMonthDesign.frame
                    ? 12.0
                    : 28.0);
    final gap = tiled
        ? 5.0
        : design == RoozMonthDesign.floating
            ? 2.0
            : 0.0;
    return Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: c.outlineVariant)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(context, c),
          Padding(
              padding: RoozCalendarCustomization.maybeOf(context)
                      ?.contentPadding ??
                  EdgeInsets.fromLTRB(ruled ? 16 : 20, 16, ruled ? 16 : 20, 20),
              child: Column(children: [
                Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                        border: ruled
                            ? Border(
                                bottom:
                                    BorderSide(color: c.outline, width: 1.5))
                            : null,
                        color: tiled ? c.surfaceContainerLow : null,
                        borderRadius: tiled ? BorderRadius.circular(8) : null),
                    child: Row(children: [
                      for (final label in weekdayLabels)
                        Expanded(
                            child: Text(label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: c.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)))
                    ])),
                const SizedBox(height: 8),
                for (var row = 0; row < 6; row++)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: tiled ? 3 : 2),
                      child: Row(children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                              child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: gap / 2),
                                  child: _cell(
                                      context, days[row * 7 + col], c, col)))
                      ])),
                const SizedBox(height: 16),
                if (design != RoozMonthDesign.floating) ...[
                  Divider(height: 1, color: c.outlineVariant),
                  const SizedBox(height: 14),
                  Semantics(
                      liveRegion: true,
                      child: Text(summary,
                          style: TextStyle(
                              color: c.brightness == Brightness.dark
                                  ? c.onSurface
                                  : c.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                ],
              ])),
        ]));
  }

  Widget _nav(BuildContext context, ColorScheme c, bool previous,
      {bool invert = false, bool boxed = false}) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return IconButton(
        tooltip: previous ? previousLabel : nextLabel,
        onPressed: previous ? onPreviousMonth : onNextMonth,
        style: IconButton.styleFrom(
            foregroundColor: invert
                ? c.onPrimary
                : (c.brightness == Brightness.dark ? c.onSurface : c.primary),
            backgroundColor: boxed ? c.primaryContainer : null,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tiled ? 9 : 30))),
        icon: Icon(previous == rtl ? Icons.chevron_right : Icons.chevron_left));
  }

  Widget _header(BuildContext context, ColorScheme c) =>
      roozCustomHeader(context, month, _defaultHeader(context, c));
  Widget _defaultHeader(BuildContext context, ColorScheme c) {
    final title = f(month, '%B'), year = f(month, '%Y');
    final label = Semantics(
        header: true,
        liveRegion: true,
        child: Text('$title $year',
            style: TextStyle(
                fontSize: 22,
                color: c.onSurface,
                fontWeight: FontWeight.w700)));
    switch (design) {
      case RoozMonthDesign.ribbon:
        return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(children: [
              _nav(context, c, true, boxed: true),
              Expanded(
                  child: Column(children: [
                Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface))),
                const SizedBox(height: 4),
                Text(year,
                    style: TextStyle(color: c.onSurfaceVariant, fontSize: 12))
              ])),
              _nav(context, c, false, boxed: true)
            ]));
      case RoozMonthDesign.ledger:
        return Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 18, 16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.outlineVariant))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                  child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(year,
                                style: TextStyle(
                                    color: c.onSurfaceVariant, fontSize: 13)),
                            Text(title,
                                style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: c.onSurface,
                                    height: 1.2))
                          ]))),
              _nav(context, c, true),
              _nav(context, c, false)
            ]));
      case RoozMonthDesign.tiles:
        return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: label),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: c.outlineVariant),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.grid_view, size: 18, color: c.primary))
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _nav(context, c, true, boxed: true),
                Expanded(
                    child: Divider(
                        color: c.outlineVariant, indent: 16, endIndent: 16)),
                _nav(context, c, false, boxed: true)
              ])
            ]));
      case RoozMonthDesign.frame:
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            color: c.brightness == Brightness.dark ? c.onSurface : c.primary,
            child: Row(children: [
              _nav(context, c, true, invert: true),
              Expanded(
                  child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text('$title · $year',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: c.onPrimary)))),
              _nav(context, c, false, invert: true)
            ]));
      case RoozMonthDesign.floating:
        return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: label),
                _nav(context, c, true),
                _nav(context, c, false)
              ]),
              const SizedBox(height: 16),
              Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                      color: c.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(30)),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(summary,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: c.brightness == Brightness.dark
                                  ? c.onSurface
                                  : c.primary,
                              fontWeight: FontWeight.w600))))
            ]));
      case RoozMonthDesign.brackets:
        return Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Row(children: [
              Container(width: 4, height: 52, color: c.primary),
              const SizedBox(width: 14),
              Expanded(
                  child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    fontSize: 28,
                                    color: c.onSurface,
                                    fontWeight: FontWeight.w600)),
                            Text(year,
                                style: TextStyle(
                                    fontSize: 12, color: c.onSurfaceVariant))
                          ]))),
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: c.outlineVariant),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _nav(context, c, true),
                    _nav(context, c, false)
                  ]))
            ]));
    }
  }

  Widget _cell(BuildContext context, CivilDate? d, ColorScheme c, int column) =>
      roozCustomDay(context,
          date: d,
          month: month,
          selection: selection,
          enabled: d != null && (isEnabled?.call(d) ?? true),
          onTap: onDateTapped,
          label:
              d == null ? '' : (labelBuilder?.call(d) ?? f(d, '%A %d %B %Y')),
          fallback: () => _defaultCell(context, d, c, column));
  Widget _defaultCell(
      BuildContext context, CivilDate? d, ColorScheme c, int column) {
    final h = (MediaQuery.textScalerOf(context).scale(16) + 26)
        .clamp(48.0, double.infinity)
        .toDouble();
    if (d == null) return SizedBox(height: h);
    final selected = selection.contains(d),
        first = d.epochDay == selection.start?.epochDay,
        last = d.epochDay == (selection.end ?? selection.start)?.epochDay;
    final edge = first || last, enabled = isEnabled?.call(d) ?? true;
    final inMonth = d.month == month.month && d.year == month.year,
        isToday = today?.epochDay == d.epochDay;
    final textColor = selected &&
            (tiled ||
                edge &&
                    (design == RoozMonthDesign.ribbon ||
                        ruled ||
                        design == RoozMonthDesign.floating))
        ? c.onPrimary
        : selected
            ? (c.brightness == Brightness.dark ? c.onSurface : c.primary)
            : inMonth
                ? c.onSurface
                : c.onSurfaceVariant;
    return Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        onTap: enabled ? () => onDateTapped(d) : null,
        label: labelBuilder?.call(d) ?? f(d, '%A %d %B %Y'),
        child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
                height: h,
                child: ExcludeSemantics(
                    child: Stack(alignment: Alignment.center, children: [
                  if (ruled)
                    Positioned.fill(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: c.outlineVariant),
                                    left: column == 6
                                        ? BorderSide.none
                                        : BorderSide(
                                            color: c.outlineVariant))))),
                  if (selected && design == RoozMonthDesign.ribbon)
                    PositionedDirectional(
                        start: first ? constraints.maxWidth / 2 : 0,
                        end: last ? constraints.maxWidth / 2 : 0,
                        top: 7,
                        bottom: 7,
                        child: ColoredBox(color: c.primaryContainer)),
                  if (selected && ruled)
                    PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 2,
                        child: Container(height: 3, color: c.primary)),
                  if (selected && design == RoozMonthDesign.frame)
                    Positioned.fill(
                        top: 4,
                        bottom: 4,
                        child: Container(
                            decoration: BoxDecoration(
                                color: c.primaryContainer,
                                border: BorderDirectional(
                                    top: BorderSide(color: c.primary),
                                    bottom: BorderSide(color: c.primary),
                                    start: first
                                        ? BorderSide(
                                            color:
                                                c.brightness == Brightness.dark
                                                    ? c.onSurface
                                                    : c.primary,
                                            width: 2)
                                        : BorderSide.none,
                                    end: last
                                        ? BorderSide(
                                            color:
                                                c.brightness == Brightness.dark
                                                    ? c.onSurface
                                                    : c.primary,
                                            width: 2)
                                        : BorderSide.none)))),
                  if (selected && design == RoozMonthDesign.brackets)
                    Positioned.fill(
                        top: 5,
                        bottom: 5,
                        child: Container(
                            decoration: BoxDecoration(
                                border: BorderDirectional(
                                    start: first
                                        ? BorderSide(
                                            color: c.brightness == Brightness.dark
                                                ? c.onSurface
                                                : c.primary,
                                            width: 3)
                                        : BorderSide.none,
                                    end: last
                                        ? BorderSide(
                                            color: c.brightness == Brightness.dark
                                                ? c.onSurface
                                                : c.primary,
                                            width: 3)
                                        : BorderSide.none,
                                    top: edge
                                        ? BorderSide(
                                            color: c.brightness == Brightness.dark
                                                ? c.onSurface
                                                : c.primary,
                                            width: 2)
                                        : BorderSide.none,
                                    bottom: edge
                                        ? BorderSide(
                                            color: c.brightness == Brightness.dark
                                                ? c.onSurface
                                                : c.primary,
                                            width: 2)
                                        : BorderSide.none)))),
                  Padding(
                      padding: EdgeInsets.all(tiled ? 0 : 5),
                      child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: tiled
                                  ? (selected
                                      ? c.primary
                                      : c.surfaceContainerLow)
                                  : edge &&
                                          (design == RoozMonthDesign.ribbon ||
                                              ruled ||
                                              design ==
                                                  RoozMonthDesign.floating)
                                      ? c.primary
                                      : null,
                              borderRadius: BorderRadius.circular(tiled
                                  ? 10
                                  : ruled
                                      ? 0
                                      : design == RoozMonthDesign.ribbon ||
                                              design == RoozMonthDesign.floating
                                          ? 100
                                          : 8),
                              border: tiled
                                  ? Border.all(
                                      color: selected
                                          ? c.primary
                                          : c.outlineVariant)
                                  : isToday && !selected
                                      ? Border.all(color: c.outline)
                                      : null,
                              boxShadow:
                                  edge && design == RoozMonthDesign.floating
                                      ? [
                                          BoxShadow(
                                              color: c.shadow.withAlpha(40),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))
                                        ]
                                      : null),
                          child: Text(
                              f(d, '%d').replaceFirst(RegExp(r'^[0۰٠]'), ''),
                              style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      enabled ? textColor : c.onSurfaceVariant,
                                  fontWeight:
                                      edge ? FontWeight.w800 : FontWeight.w400,
                                  decoration: !enabled
                                      ? TextDecoration.lineThrough
                                      : null)))),
                  if (selected &&
                      !edge &&
                      (design == RoozMonthDesign.floating ||
                          design == RoozMonthDesign.brackets))
                    Positioned(
                        bottom: 5,
                        child: Container(
                            width: design == RoozMonthDesign.brackets ? 14 : 4,
                            height: 3,
                            decoration: BoxDecoration(
                                color: c.brightness == Brightness.dark
                                    ? c.onSurface
                                    : c.primary,
                                borderRadius: BorderRadius.circular(3)))),
                  Positioned.fill(
                      child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              key: ValueKey('month-design-day-${d.epochDay}'),
                              onTap: enabled ? () => onDateTapped(d) : null,
                              canRequestFocus: enabled,
                              borderRadius: BorderRadius.circular(tiled
                                  ? 10
                                  : ruled
                                      ? 0
                                      : 20)))),
                ])))));
  }
}
