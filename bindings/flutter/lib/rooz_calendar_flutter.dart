import 'package:flutter/material.dart';
import 'package:rooz_calendar/rooz_calendar.dart';
export 'package:rooz_calendar/rooz_calendar.dart';

typedef RoozDayBuilder = Widget Function(BuildContext context, CivilDate date,
    bool selected, bool inDisplayedMonth, bool enabled);

/// Rendering only: the caller owns state, header, navigation, RTL/LTR, events
/// and selection policy. Every day remains a semantic, keyboard-focusable button.
class RoozMonthView extends StatelessWidget {
  final CivilDate month;
  final DateSelection selection;
  final int firstWeekday;
  final ValueChanged<CivilDate> onDateTapped;
  final bool Function(CivilDate)? isEnabled;
  final String Function(CivilDate)? labelBuilder;
  final RoozDayBuilder? dayBuilder;
  final double minCellHeight;
  const RoozMonthView(
      {super.key,
      required this.month,
      required this.selection,
      required this.onDateTapped,
      this.firstWeekday = 6,
      this.isEnabled,
      this.labelBuilder,
      this.dayBuilder,
      this.minCellHeight = 48});

  @override
  Widget build(BuildContext context) {
    final days = month.monthGrid(firstWeekday: firstWeekday);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var week = 0; week < 6; week++)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var column = 0; column < 7; column++)
            Expanded(child: _cell(context, days[week * 7 + column])),
        ]),
    ]);
  }

  Widget _cell(BuildContext context, CivilDate? date) {
    if (date == null) return SizedBox(height: minCellHeight);
    final selected = selection.contains(date);
    final inMonth = date.month == month.month;
    final enabled = isEnabled?.call(date) ?? true;
    return Semantics(
      selected: selected,
      label: labelBuilder?.call(date) ?? date.format(pattern: '%A %d %B %Y'),
      child: TextButton(
        onPressed: enabled ? () => onDateTapped(date) : null,
        style: TextButton.styleFrom(
          minimumSize: Size(44, minCellHeight),
          backgroundColor:
              selected ? Theme.of(context).colorScheme.primaryContainer : null,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: ExcludeSemantics(
            child:
                dayBuilder?.call(context, date, selected, inMonth, enabled) ??
                    Opacity(
                        opacity: inMonth ? 1 : .4,
                        child: Text(date.format(pattern: '%d')))),
      ),
    );
  }
}
