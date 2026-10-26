import 'package:flutter/material.dart';
import 'rooz_calendar_controller.dart';
import 'rooz_calendar_flutter.dart';
import 'rooz_calendar_motion.dart';

@immutable
class RoozDayDetails {
  final CivilDate date;
  final bool selected, start, end, enabled, inMonth, today;
  final List<String> events;
  const RoozDayDetails(
      {required this.date,
      required this.selected,
      required this.start,
      required this.end,
      required this.enabled,
      required this.inMonth,
      required this.today,
      required this.events});
}

typedef RoozDayContentBuilder = Widget Function(BuildContext, RoozDayDetails);
typedef RoozHeaderBuilder = Widget Function(BuildContext, CivilDate, Widget);

/// Presentation-only overrides. A custom day changes content, not the semantic
/// button, keyboard activation, validation or selection contract.
class RoozCalendarCustomization extends InheritedWidget {
  final RoozCalendarController? controller;
  final RoozCalendarMotion motion;
  final RoozDayContentBuilder? dayBuilder, badgeBuilder;
  final RoozHeaderBuilder? headerBuilder;
  final Map<int, List<String>> events;
  final CivilDate? today;
  final double minDayHeight;
  final double? cardRadius;
  final EdgeInsets? contentPadding;
  final bool showOutsideDays;
  const RoozCalendarCustomization(
      {super.key,
      required super.child,
      this.controller,
      this.motion = const RoozCalendarMotion(),
      this.dayBuilder,
      this.badgeBuilder,
      this.headerBuilder,
      this.events = const {},
      this.today,
      this.minDayHeight = 48,
      this.cardRadius,
      this.contentPadding,
      this.showOutsideDays = true})
      : assert(minDayHeight >= 44),
        assert(cardRadius == null || cardRadius >= 0);
  static RoozCalendarCustomization? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RoozCalendarCustomization>();
  @override
  bool updateShouldNotify(RoozCalendarCustomization oldWidget) => true;
}

Widget roozCustomHeader(
        BuildContext context, CivilDate date, Widget fallback) =>
    RoozCalendarCustomization.maybeOf(context)
        ?.headerBuilder
        ?.call(context, date, fallback) ??
    fallback;

Widget roozCustomDay(BuildContext context,
    {required CivilDate? date,
    required CivilDate month,
    required DateSelection selection,
    required bool enabled,
    required ValueChanged<CivilDate> onTap,
    required String label,
    required Widget Function() fallback}) {
  final scope = RoozCalendarCustomization.maybeOf(context);
  if (scope == null || date == null) return fallback();
  final inMonth = date.year == month.year && date.month == month.month;
  if (!scope.showOutsideDays && !inMonth)
    return SizedBox(height: scope.minDayHeight);
  final details = RoozDayDetails(
      date: date,
      selected: selection.contains(date),
      start: date.epochDay == selection.start?.epochDay,
      end: date.epochDay == (selection.end ?? selection.start)?.epochDay,
      enabled: enabled,
      inMonth: inMonth,
      today: date.epochDay == scope.today?.epochDay,
      events:
          List.unmodifiable(scope.events[date.epochDay] ?? const <String>[]));
  final content = scope.dayBuilder == null
      ? fallback()
      : Semantics(
          button: true,
          enabled: enabled,
          selected: details.selected,
          label: label,
          onTap: enabled ? () => onTap(date) : null,
          child: ExcludeSemantics(
              child: InkWell(
                  key: ValueKey('custom-day-${date.epochDay}'),
                  onTap: enabled ? () => onTap(date) : null,
                  canRequestFocus: enabled,
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: scope.minDayHeight),
                      child: Center(
                          child: scope.dayBuilder!(context, details))))));
  final badge = scope.badgeBuilder?.call(context, details) ??
      (details.events.isEmpty
          ? null
          : Icon(Icons.circle,
              size: 4, color: Theme.of(context).colorScheme.primary));
  final rendered = ConstrainedBox(
      constraints: BoxConstraints(minHeight: scope.minDayHeight),
      child: Stack(alignment: Alignment.center, children: [
        content,
        if (badge != null)
          PositionedDirectional(
              bottom: 1,
              end: 4,
              child: IgnorePointer(child: ExcludeSemantics(child: badge))),
      ]));
  return scope.controller == null
      ? rendered
      : RoozRangeEndTarget(
          controller: scope.controller!,
          motion: scope.motion,
          date: date,
          label: label,
          child: rendered);
}
