import 'package:flutter/foundation.dart';
import 'rooz_calendar_flutter.dart';

/// Selection rules shared by every presentation. Dates are inclusive.
/// Weekday mask: Monday = bit 0, Sunday = bit 6 (the native ABI convention).
@immutable
class RoozSelectionPolicy {
  /// No additional length cap within the calendar and supplied date bounds.
  static const int unlimitedDays = 2147483647;
  final CivilDate minimum, maximum;
  final int minDays, maxDays, disabledWeekdays;
  final SelectionMode mode;
  final List<int> blockedDays;
  final bool Function(CivilDate)? isSelectable;
  final void Function(CivilDate, CivilDate)? rangeValidator;
  RoozSelectionPolicy(
      {required this.minimum,
      required this.maximum,
      this.minDays = 1,
      this.maxDays = unlimitedDays,
      this.disabledWeekdays = 0,
      this.mode = SelectionMode.range,
      List<int> blockedDays = const [],
      this.isSelectable,
      this.rangeValidator})
      : blockedDays = List.unmodifiable(blockedDays) {
    if (minimum.calendar != maximum.calendar ||
        minimum.epochDay > maximum.epochDay ||
        (mode == SelectionMode.single && minDays != 1) ||
        minDays < 1 ||
        maxDays < minDays ||
        maxDays > 2147483647 ||
        disabledWeekdays < 0 ||
        disabledWeekdays > 127) {
      throw ArgumentError('Invalid calendar, bounds, lengths or weekday mask');
    }
  }
  RangeRules get rules => RangeRules(
      minimum: minimum,
      maximum: maximum,
      minLength: minDays,
      maxLength: maxDays,
      disabledWeekdays: disabledWeekdays,
      blockedDays: blockedDays);
  bool allows(CivilDate d) =>
      d.calendar == minimum.calendar &&
      d.epochDay >= minimum.epochDay &&
      d.epochDay <= maximum.epochDay &&
      (disabledWeekdays & (1 << (d.weekday - 1))) == 0 &&
      !blockedDays.contains(d.epochDay) &&
      (isSelectable?.call(d) ?? true);
  void validateCustom(CivilDate start, CivilDate end) {
    // Interior blackout days must also reject the range, not only its endpoints.
    if (isSelectable != null) {
      for (var day = start.epochDay; day <= end.epochDay; day++) {
        if (!isSelectable!(
            start.engine.fromEpochDay(day, calendar: start.calendar))) {
          throw ArgumentError('A date in this range is unavailable');
        }
      }
    }
    rangeValidator?.call(start, end);
  }
}

/// Optional state owner; low-level stateless widgets remain available.
/// A rejected operation preserves selection and emits [onError]. No clock,
/// storage, networking or alternate calendar arithmetic is hidden here.
class RoozCalendarController extends ChangeNotifier {
  CivilDate _anchor;
  DateSelection _selection = const DateSelection();
  RoozSelectionPolicy _policy;
  Object? _error;
  final ValueChanged<DateSelection>? onSelectionChanged;
  final ValueChanged<CivilDate>? onNavigate;
  final ValueChanged<Object>? onError;
  RoozCalendarController(
      {required CivilDate initialDate,
      required RoozSelectionPolicy policy,
      this.onSelectionChanged,
      this.onNavigate,
      this.onError})
      : _anchor = initialDate,
        _policy = policy {
    if (!canDisplay(initialDate))
      throw ArgumentError('Initial month outside policy bounds');
  }
  CivilDate get anchor => _anchor;
  CivilDate get month => _anchor.addDays(1 - _anchor.day);
  DateSelection get selection => _selection;
  RoozSelectionPolicy get policy => _policy;
  Object? get error => _error;
  int? get inclusiveDays => _selection.isComplete
      ? _selection.end!.epochDay - _selection.start!.epochDay + 1
      : null;
  bool isEnabled(CivilDate date) => _policy.allows(date);
  bool canDisplay(CivilDate date) =>
      date.calendar == _policy.minimum.calendar &&
      date.epochDay - date.day + date.monthLength >= _policy.minimum.epochDay &&
      date.epochDay - date.day + 1 <= _policy.maximum.epochDay;
  bool _reject(Object error) {
    _error = error;
    notifyListeners();
    onError?.call(error);
    return false;
  }

  bool select(CivilDate date) {
    late DateSelection next;
    try {
      if (!isEnabled(date)) throw ArgumentError('Date unavailable');
      next = _selection.tap(date, _policy.rules,
          mode: _policy.mode, validator: _policy.validateCustom);
    } on RoozException catch (e) {
      return _reject(e);
    } on ArgumentError catch (e) {
      return _reject(e);
    }
    _selection = next;
    _error = null;
    notifyListeners();
    onSelectionChanged?.call(next);
    return true;
  }

  /// Atomic preset selection. Reversed endpoints are normalized by Roooz.
  bool setRange(CivilDate start, CivilDate end) {
    late DateSelection next;
    try {
      if (!isEnabled(start) || !isEnabled(end))
        throw ArgumentError('Date unavailable');
      if (_policy.mode == SelectionMode.single && start != end) {
        throw ArgumentError('A single selection requires matching endpoints');
      }
      next =
          const DateSelection().tap(start, _policy.rules, mode: _policy.mode);
      if (_policy.mode == SelectionMode.range)
        next = next.tap(end, _policy.rules);
      _policy.validateCustom(next.start!, next.end!);
    } on RoozException catch (e) {
      return _reject(e);
    } on ArgumentError catch (e) {
      return _reject(e);
    }
    _selection = next;
    _error = null;
    notifyListeners();
    onSelectionChanged?.call(next);
    return true;
  }

  /// Side-effect-free validation for a drop target. Custom validators should
  /// be pure: hovering may call them repeatedly. Start never swaps with end.
  bool canResizeEnd(CivilDate end) => _canResizeRange(_selection.start, end);

  bool canResizeStart(CivilDate start) =>
      _canResizeRange(start, _selection.end);

  bool _canResizeRange(CivilDate? start, CivilDate? end) {
    if (_policy.mode != SelectionMode.range ||
        !_selection.isComplete ||
        start == null ||
        end == null ||
        end.calendar != start.calendar ||
        end.epochDay < start.epochDay) return false;
    try {
      if (!isEnabled(start) || !isEnabled(end)) return false;
      start.engine.validateRange(start, end, _policy.rules);
      _policy.validateCustom(start, end);
      return true;
    } on RoozException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  /// Commits one endpoint edit. Invalid drops leave selection untouched.
  bool resizeEnd(CivilDate end) {
    if (!canResizeEnd(end)) return false;
    if (end.epochDay == _selection.end?.epochDay) return true;
    return setRange(_selection.start!, end);
  }

  /// Moves the start while holding the end fixed; crossing the end is rejected.
  bool resizeStart(CivilDate start) {
    if (!canResizeStart(start)) return false;
    if (start.epochDay == _selection.start?.epochDay) return true;
    return setRange(start, _selection.end!);
  }

  void clear() {
    _selection = const DateSelection();
    _error = null;
    notifyListeners();
    onSelectionChanged?.call(_selection);
  }

  bool goTo(CivilDate date) {
    if (!canDisplay(date))
      return _reject(ArgumentError('Month outside bounds'));
    _anchor = date;
    _error = null;
    notifyListeners();
    onNavigate?.call(date);
    return true;
  }

  CivilDate? monthOffset(int delta) {
    try {
      final d = month.addMonths(delta);
      return canDisplay(d) ? d : null;
    } on RoozException {
      return null;
    }
  }

  bool navigateMonths(int delta) {
    final d = monthOffset(delta);
    return d == null ? false : goTo(d);
  }

  /// Revalidates existing selection. Incompatible selection is cleared once.
  /// Calendar changes are explicit: make a new controller for another calendar.
  void updatePolicy(RoozSelectionPolicy value) {
    if (value.minimum.calendar != _anchor.calendar)
      throw ArgumentError('Calendar changed');
    var cleared = false;
    try {
      final start = _selection.start, end = _selection.end;
      if (start != null) {
        if (value.mode != _policy.mode && end == null)
          throw ArgumentError("Selection mode changed");
        if (!value.allows(start) || (end != null && !value.allows(end)))
          throw ArgumentError('Selection unavailable');
        if (end != null) {
          if (value.mode == SelectionMode.single && start != end)
            throw ArgumentError('Not a single day');
          start.engine.validateRange(start, end, value.rules);
          value.validateCustom(start, end);
        }
      }
      _error = null;
    } on RoozException catch (e) {
      _error = e;
      cleared = true;
    } on ArgumentError catch (e) {
      _error = e;
      cleared = true;
    }
    _policy = value;
    if (cleared) _selection = const DateSelection();
    final moved = !canDisplay(_anchor);
    if (moved) _anchor = value.minimum;
    notifyListeners();
    if (cleared) {
      onSelectionChanged?.call(_selection);
      onError?.call(_error!);
    }
    if (moved) onNavigate?.call(_anchor);
  }
}
