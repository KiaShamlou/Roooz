import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'rooz_calendar_flutter.dart';
import 'rooz_calendar_customization.dart';
export 'rooz_calendar_flutter.dart';

/// Optional presentation layer. The caller still owns dates and selection.
enum RoozCalendarStyle { minimal, classic, glass, midnight }

@immutable
class RoozCalendarPalette {
  final Color surface, ink, muted, accent, onAccent, range, line;
  final double radius;
  const RoozCalendarPalette(
      {required this.surface,
      required this.ink,
      required this.muted,
      required this.accent,
      required this.onAccent,
      required this.range,
      required this.line,
      required this.radius});

  static RoozCalendarPalette of(RoozCalendarStyle style) => switch (style) {
        RoozCalendarStyle.minimal => const RoozCalendarPalette(
            surface: Color(0xFFFFFFFF),
            ink: Color(0xFF171719),
            muted: Color(0xFF74747C),
            accent: Color(0xFF171719),
            onAccent: Color(0xFFFFFFFF),
            range: Color(0xFFF1F1F3),
            line: Color(0xFFE8E8ED),
            radius: 0),
        RoozCalendarStyle.classic => const RoozCalendarPalette(
            surface: Color(0xFFFFFFFF),
            ink: Color(0xFF171719),
            muted: Color(0xFF73737C),
            accent: Color(0xFF007AFF),
            onAccent: Color(0xFFFFFFFF),
            range: Color(0xFFE9F2FF),
            line: Color(0xFFECECF0),
            radius: 28),
        RoozCalendarStyle.glass => const RoozCalendarPalette(
            surface: Color(0xDDFFFFFF),
            ink: Color(0xFF222238),
            muted: Color(0xFF69697B),
            accent: Color(0xFF6554D9),
            onAccent: Color(0xFFFFFFFF),
            range: Color(0xFFEDE9FC),
            line: Color(0xFFDFDAF0),
            radius: 32),
        RoozCalendarStyle.midnight => const RoozCalendarPalette(
            surface: Color(0xFF1C1C1E),
            ink: Color(0xFFF5F5F7),
            muted: Color(0xFFA0A0A9),
            accent: Color(0xFF0A84FF),
            onAccent: Color(0xFFFFFFFF),
            range: Color(0xFF142F4B),
            line: Color(0xFF36363A),
            radius: 28),
      };
}

/// A responsive, RTL-aware calendar with four opt-in visual presets.
/// Uses the native engine's grid and never implements calendar arithmetic.
/// Supply localized weekday names in display order when changing firstWeekday.
class RoozStyledCalendar extends StatelessWidget {
  final CivilDate month;
  final DateSelection selection;
  final ValueChanged<CivilDate> onDateTapped;
  final VoidCallback? onPreviousMonth, onNextMonth, onClear;
  final bool Function(CivilDate)? isEnabled;
  final CivilDate? today;
  final RoozCalendarStyle style;
  final RoozCalendarPalette? palette;
  final int firstWeekday;
  final List<String> weekdayLabels;
  final RoozLocale locale;
  final DigitSet digits;
  final String previousLabel, nextLabel, clearLabel, emptyLabel, endLabel;
  final String Function(CivilDate)? labelBuilder;

  const RoozStyledCalendar({
    super.key,
    required this.month,
    required this.selection,
    required this.onDateTapped,
    this.onPreviousMonth,
    this.onNextMonth,
    this.onClear,
    this.isEnabled,
    this.today,
    this.style = RoozCalendarStyle.classic,
    this.palette,
    this.firstWeekday = 6,
    this.weekdayLabels = const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    this.locale = RoozLocale.persian,
    this.digits = DigitSet.persian,
    this.previousLabel = 'ماه قبل',
    this.nextLabel = 'ماه بعد',
    this.clearLabel = 'پاک کردن',
    this.emptyLabel = 'یک روز را انتخاب کنید',
    this.endLabel = 'تاریخ پایان را انتخاب کنید',
    this.labelBuilder,
  })  : assert(weekdayLabels.length == 7),
        assert(firstWeekday >= 1 && firstWeekday <= 7);

  String _format(CivilDate date, String pattern) =>
      date.format(pattern: pattern, locale: locale, digits: digits);

  @override
  Widget build(BuildContext context) {
    final p = palette ?? RoozCalendarPalette.of(style);
    final days = month.monthGrid(firstWeekday: firstWeekday);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final minimal = style == RoozCalendarStyle.minimal;
    final status = selection.start == null
        ? emptyLabel
        : selection.end == null
            ? '${_format(selection.start!, '%d %B')} · $endLabel'
            : '${_format(selection.start!, '%d %B')} — ${_format(selection.end!, '%d %B')}';
    final content = Padding(
        padding: RoozCalendarCustomization.maybeOf(context)?.contentPadding ??
            EdgeInsets.all(minimal ? 8 : 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          roozCustomHeader(
              context,
              month,
              Row(children: [
                Expanded(
                    child: Semantics(
                        header: true,
                        liveRegion: true,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_format(month, '%B'),
                                  style: TextStyle(
                                      color: p.ink,
                                      fontSize: minimal ? 24 : 28,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.8)),
                              const SizedBox(height: 5),
                              Text(_format(month, '%Y'),
                                  style: TextStyle(
                                      color: p.muted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ]))),
                _navigation(
                    previousLabel,
                    onPreviousMonth,
                    rtl
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    p),
                const SizedBox(width: 2),
                _navigation(
                    nextLabel,
                    onNextMonth,
                    rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    p),
              ])),
          const SizedBox(height: 24),
          Row(children: [
            for (final label in weekdayLabels)
              Expanded(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: p.muted,
                          fontWeight: FontWeight.w500)))
          ]),
          const SizedBox(height: 10),
          for (var week = 0; week < 6; week++)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(child: _day(context, days[week * 7 + col], p))
                ])),
          const SizedBox(height: 16),
          Container(height: .5, color: p.line),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Semantics(
                    liveRegion: true,
                    child: Text(status,
                        style: TextStyle(
                            color: p.muted, fontSize: 12, height: 1.5)))),
            if (onClear != null)
              CupertinoButton(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  minSize: 44,
                  onPressed: selection.start == null ? null : onClear,
                  child: Text(clearLabel,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              selection.start == null ? p.muted : p.accent))),
          ]),
        ]));
    final card = DecoratedBox(
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(
                RoozCalendarCustomization.maybeOf(context)?.cardRadius ??
                    p.radius),
            border: style == RoozCalendarStyle.glass
                ? Border.all(color: const Color(0xDDFFFFFF), width: 1.5)
                : null,
            boxShadow: minimal || style == RoozCalendarStyle.midnight
                ? null
                : [
                    BoxShadow(
                        color: p.ink.withAlpha(9),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ]),
        child: content);
    if (style != RoozCalendarStyle.glass) return card;
    return ClipRRect(
        borderRadius: BorderRadius.circular(
            RoozCalendarCustomization.maybeOf(context)?.cardRadius ?? p.radius),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: card));
  }

  Widget _navigation(String label, VoidCallback? action, IconData icon,
          RoozCalendarPalette p) =>
      Tooltip(
          message: label,
          child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 44,
              onPressed: action,
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: p.accent.withAlpha(18), shape: BoxShape.circle),
                  child: Icon(icon,
                      size: 25, color: action == null ? p.muted : p.accent))));

  Widget _day(BuildContext context, CivilDate? date, RoozCalendarPalette p) =>
      roozCustomDay(context,
          date: date,
          month: month,
          selection: selection,
          enabled: date != null && (isEnabled?.call(date) ?? true),
          onTap: onDateTapped,
          label: date == null
              ? ''
              : (labelBuilder?.call(date) ?? _format(date, '%A %d %B %Y')),
          fallback: () => _defaultDay(context, date, p));
  Widget _defaultDay(
      BuildContext context, CivilDate? date, RoozCalendarPalette p) {
    if (date == null) return const SizedBox(height: 48);
    final selected = selection.contains(date);
    final first = date.epochDay == selection.start?.epochDay;
    final last = date.epochDay == (selection.end ?? selection.start)?.epochDay;
    final edge = first || last;
    final inMonth = date.month == month.month && date.year == month.year;
    final enabled = isEnabled?.call(date) ?? true;
    final isToday = today?.epochDay == date.epochDay;
    final foreground = edge
        ? p.onAccent
        : isToday
            ? p.accent
            : inMonth
                ? p.ink
                : p.muted;
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(17) / 17;
      final height = scale > 1.4 ? 48 * scale / 1.4 : 48.0;
      return SizedBox(
          height: height,
          child: Stack(alignment: Alignment.center, children: [
            if (selected)
              PositionedDirectional(
                  start: first ? constraints.maxWidth / 2 : 0,
                  end: last ? constraints.maxWidth / 2 : 0,
                  top: 5,
                  bottom: 5,
                  child: ColoredBox(color: p.range)),
            Semantics(
                selected: selected,
                label: labelBuilder?.call(date) ?? _format(date, '%A %d %B %Y'),
                child: CupertinoButton(
                    key: ValueKey('rooz-day-${date.epochDay}'),
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: enabled ? () => onDateTapped(date) : null,
                    child: Container(
                      alignment: Alignment.center,
                      width:
                          constraints.maxWidth < 38 ? constraints.maxWidth : 38,
                      height: height - 10,
                      decoration: BoxDecoration(
                          color: edge ? p.accent : null,
                          borderRadius: BorderRadius.circular(100)),
                      child: ExcludeSemantics(
                          child: Text(
                              _format(date, '%d')
                                  .replaceFirst(RegExp(r'^[0۰٠]'), ''),
                              style: TextStyle(
                                  color: enabled ? foreground : p.muted,
                                  fontSize: 17,
                                  fontWeight: edge || isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  decoration: !enabled
                                      ? TextDecoration.lineThrough
                                      : null))),
                    ))),
            if (isToday && !edge)
              Positioned(
                  bottom: 3,
                  child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                          color: p.accent, shape: BoxShape.circle))),
          ]));
    });
  }
}
