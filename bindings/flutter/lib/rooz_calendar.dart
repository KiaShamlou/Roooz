import 'package:flutter/material.dart';
import 'rooz_calendar_controller.dart';
import 'rooz_calendar_motion.dart';
export 'rooz_calendar_motion.dart';
import 'rooz_calendar_customization.dart';
import 'rooz_month_designs.dart';
import 'rooz_calendar_layouts.dart';
import 'rooz_styled_calendar.dart';
export 'rooz_calendar_controller.dart';
export 'rooz_calendar_customization.dart';
export 'rooz_month_designs.dart';
export 'rooz_calendar_layouts.dart';
export 'rooz_styled_calendar.dart';

enum RoozPresentationGroup { monthly, layouts, original }

/// Independent presentation values: picking an accent never picks a design.
@immutable
class RoozCalendarOptions {
  final RoozPresentationGroup group;
  final RoozMonthDesign design;
  final RoozCalendarLayout layout;
  final RoozCalendarStyle style;
  final Color accent;
  final bool dark, showOutsideDays, showActions;
  final TextDirection direction;
  final RoozLocale locale;
  final DigitSet digits;
  final int firstWeekday;
  final List<String>? weekdayLabels;
  final String previousLabel,
      nextLabel,
      clearLabel,
      confirmLabel,
      emptyLabel,
      endLabel,
      eventsLabel,
      noEventsLabel,
      yearLabel;
  const RoozCalendarOptions(
      {this.group = RoozPresentationGroup.monthly,
      this.design = RoozMonthDesign.ribbon,
      this.layout = RoozCalendarLayout.month,
      this.style = RoozCalendarStyle.classic,
      this.accent = const Color(0xFF28766D),
      this.dark = false,
      this.showOutsideDays = true,
      this.showActions = true,
      this.direction = TextDirection.rtl,
      this.locale = RoozLocale.persian,
      this.digits = DigitSet.persian,
      this.firstWeekday = 6,
      this.weekdayLabels,
      this.previousLabel = 'قبلی',
      this.nextLabel = 'بعدی',
      this.clearLabel = 'پاک کردن',
      this.confirmLabel = 'تأیید انتخاب',
      this.emptyLabel = 'شروع بازه را انتخاب کنید',
      this.endLabel = 'پایان بازه را انتخاب کنید',
      this.eventsLabel = 'رویدادها',
      this.noEventsLabel = 'رویدادی ثبت نشده',
      this.yearLabel = 'نمای سال'})
      : assert(firstWeekday >= 1 && firstWeekday <= 7),
        assert(weekdayLabels == null || weekdayLabels.length == 7);
}

/// Ready-to-use adapter over all sixteen existing presentations. All public
/// low-level widgets remain usable without this controller or any inherited scope.
class RoozCalendar extends StatelessWidget {
  final RoozCalendarController controller;
  final RoozCalendarOptions options;
  final RoozCalendarMotion motion;
  final RoozDayContentBuilder? dayBuilder, badgeBuilder;
  final RoozHeaderBuilder? headerBuilder;
  final Widget Function(BuildContext, RoozCalendarController)? footerBuilder;
  final String Function(Object)? errorBuilder;
  final String Function(CivilDate)? labelBuilder;
  final Map<int, List<String>> events;
  final CivilDate? today;
  final double minDayHeight;
  final double? cardRadius;
  final EdgeInsets? contentPadding;
  final ColorScheme? colorScheme;
  final TextTheme? textTheme;
  final ValueChanged<DateSelection>? onConfirm;
  final bool? compactExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final ValueChanged<CivilDate>? onMonthSelected;
  const RoozCalendar(
      {super.key,
      required this.controller,
      this.options = const RoozCalendarOptions(),
      this.motion = const RoozCalendarMotion(),
      this.dayBuilder,
      this.badgeBuilder,
      this.headerBuilder,
      this.footerBuilder,
      this.errorBuilder,
      this.labelBuilder,
      this.events = const {},
      this.today,
      this.minDayHeight = 48,
      this.cardRadius,
      this.contentPadding,
      this.colorScheme,
      this.textTheme,
      this.onConfirm,
      this.compactExpanded,
      this.onExpandedChanged,
      this.onMonthSelected});
  @override
  Widget build(BuildContext context) {
    final o = options;
    final dark = o.dark ||
        (o.group == RoozPresentationGroup.original &&
            o.style == RoozCalendarStyle.midnight);
    final seed = ColorScheme.fromSeed(
        seedColor: o.accent,
        brightness: dark ? Brightness.dark : Brightness.light);
    // Exact caller accent, not a generated approximation. Contrast is chosen
    // from relative luminance and remains independently overridable via scheme.
    final scheme = colorScheme ??
        seed.copyWith(
            primary: o.accent,
            primaryContainer: Color.alphaBlend(
                o.accent.withAlpha(dark ? 50 : 25),
                dark ? const Color(0xFF182327) : Colors.white),
            onPrimary: o.accent.computeLuminance() > .179
                ? Colors.black
                : Colors.white,
            surface: dark ? const Color(0xFF182327) : Colors.white);
    return Theme(
        data: Theme.of(context).copyWith(
            colorScheme: scheme,
            textTheme: textTheme,
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    foregroundColor:
                        dark ? scheme.onSurface : scheme.primary))),
        child: Directionality(
            textDirection: o.direction,
            child: RoozCalendarCustomization(
                controller: controller,
                motion: motion,
                dayBuilder: dayBuilder,
                badgeBuilder: badgeBuilder,
                headerBuilder: headerBuilder,
                events: events,
                today: today,
                minDayHeight: minDayHeight,
                cardRadius: cardRadius,
                contentPadding: contentPadding,
                showOutsideDays: o.showOutsideDays,
                child: Builder(
                    builder: (context) => AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) => _body(context, scheme))))));
  }

  Widget _body(BuildContext context, ColorScheme c) {
    final o = options, state = controller;
    final anchor = state.anchor,
        month = state.month,
        selection = state.selection;
    final labels = o.weekdayLabels ??
        List.generate(7, (i) {
          // Derive weekday names using a known valid middle-of-range month, avoiding
          // invalid leading cells at the calendar's lower supported boundary.
          final d = month.engine.date(1400, 1, 15, calendar: month.calendar);
          return d
              .addDays((o.firstWeekday - d.weekday + 7) % 7 + i)
              .format(pattern: '%A', locale: o.locale, digits: o.digits);
        });
    final previous = state.monthOffset(-1), next = state.monthOffset(1);
    final calendar = switch (o.group) {
      RoozPresentationGroup.monthly => RoozMonthDesignView(
          month: month,
          selection: selection,
          design: o.design,
          onDateTapped: state.select,
          onPreviousMonth: previous == null ? null : () => state.goTo(previous),
          onNextMonth: next == null ? null : () => state.goTo(next),
          isEnabled: state.isEnabled,
          today: today,
          firstWeekday: o.firstWeekday,
          weekdayLabels: labels,
          locale: o.locale,
          digits: o.digits,
          previousLabel: o.previousLabel,
          nextLabel: o.nextLabel,
          emptyLabel: o.emptyLabel,
          labelBuilder: labelBuilder),
      RoozPresentationGroup.layouts => RoozCalendarLayouts(
          date: anchor,
          selection: selection,
          layout: o.layout,
          onDateTapped: state.select,
          onNavigate: state.goTo,
          canNavigate: state.canDisplay,
          onMonthSelected: onMonthSelected,
          isEnabled: state.isEnabled,
          events: events,
          expanded: compactExpanded,
          onExpandedChanged: onExpandedChanged,
          firstWeekday: o.firstWeekday,
          weekdayLabels: labels,
          locale: o.locale,
          digits: o.digits,
          previousLabel: o.previousLabel,
          nextLabel: o.nextLabel,
          emptyLabel: o.emptyLabel,
          eventsLabel: o.eventsLabel,
          noEventsLabel: o.noEventsLabel,
          yearLabel: o.yearLabel,
          labelBuilder: labelBuilder),
      RoozPresentationGroup.original => RoozStyledCalendar(
          month: month,
          selection: selection,
          style: o.style,
          onDateTapped: state.select,
          onPreviousMonth: previous == null ? null : () => state.goTo(previous),
          onNextMonth: next == null ? null : () => state.goTo(next),
          isEnabled: state.isEnabled,
          today: today,
          firstWeekday: o.firstWeekday,
          weekdayLabels: labels,
          locale: o.locale,
          digits: o.digits,
          previousLabel: o.previousLabel,
          nextLabel: o.nextLabel,
          emptyLabel: o.emptyLabel,
          endLabel: o.endLabel,
          clearLabel: o.clearLabel,
          labelBuilder: labelBuilder,
          palette: RoozCalendarPalette(
              surface: o.style == RoozCalendarStyle.glass
                  ? c.surface.withAlpha(220)
                  : c.surface,
              ink: c.onSurface,
              muted: c.onSurfaceVariant,
              accent: c.primary,
              onAccent: c.onPrimary,
              range: c.primaryContainer,
              line: c.outlineVariant,
              radius: RoozCalendarPalette.of(o.style).radius)),
    };
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          calendar,
          if (state.error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                    liveRegion: true,
                    child: Text(
                        errorBuilder?.call(state.error!) ??
                            'انتخاب با محدودیت‌های تقویم سازگار نیست',
                        key: const Key('rooz-error'),
                        style: TextStyle(color: c.error)))),
          if (footerBuilder != null)
            footerBuilder!(context, state)
          else if (o.showActions)
            Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
              TextButton(
                  key: const Key('rooz-clear'),
                  onPressed: selection.start == null ? null : state.clear,
                  child: Text(o.clearLabel)),
              FilledButton(
                  key: const Key('rooz-confirm'),
                  onPressed: selection.isComplete && onConfirm != null
                      ? () => onConfirm!(selection)
                      : null,
                  child: Text(o.confirmLabel)),
            ]),
        ]);
  }
}
