library;

import 'dart:convert';
import 'dart:ffi';

enum CalendarSystem { gregorian, jalali, islamicCivil, julian }

enum DigitSet { latin, persian, arabic }

enum RoozLocale { english, persian, arabic }

enum MonthOverflow { clamp, reject }

enum SelectionMode { single, range }

final class _NativeSelection extends Struct {
  @Int32()
  external int start;
  @Int32()
  external int end;
}

final class _NativeRules extends Struct {
  @Int32()
  external int minimum;
  @Int32()
  external int maximum;
  @Int32()
  external int minLength;
  @Int32()
  external int maxLength;
  @Uint32()
  external int disabledWeekdays;
  external Pointer<Int32> blocked;
  @Size()
  external int blockedCount;
}

class RoozException implements Exception {
  final int code;
  final String message;
  RoozException(this.code, this.message);
  @override
  String toString() => 'RoozException($code): $message';
}

/// Native engine with no runtime package dependencies. Supply a packaged native
/// library, or DynamicLibrary.process() for statically linked Apple targets.
class Rooz {
  static const _invalid = -2147483648;
  final DynamicLibrary library;
  Rooz(this.library) {
    final version = library
        .lookupFunction<Int32 Function(), int Function()>('rc_abi_version')();
    if (version != 1) throw StateError('Unsupported Rooz ABI $version');
  }
  factory Rooz.open(String path) => Rooz(DynamicLibrary.open(path));
  late final _alloc = library.lookupFunction<Pointer<Void> Function(Size),
      Pointer<Void> Function(int)>('rc_alloc');
  late final _free = library.lookupFunction<Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('rc_free');
  late final _toDay = library.lookupFunction<
      Int32 Function(Int32, Int32, Int32, Int32),
      int Function(int, int, int, int)>('rc_to_day');
  late final _field = library.lookupFunction<
      Int32 Function(Int32, Int32, Int32),
      int Function(int, int, int)>('rc_get_field');
  late final _addDays = library.lookupFunction<
      Int32 Function(Int32, Int32, Int32),
      int Function(int, int, int)>('rc_add_days');
  late final _addMonths = library.lookupFunction<
      Int32 Function(Int32, Int32, Int32, Int32),
      int Function(int, int, int, int)>('rc_add_months');
  late final _grid = library.lookupFunction<
      Int32 Function(Int32, Int32, Int32, Int32),
      int Function(int, int, int, int)>('rc_grid_start');
  late final _locale = library.lookupFunction<
      Pointer<Void> Function(Int32, Int32),
      Pointer<Void> Function(int, int)>('rc_builtin_locale');
  late final _format = library.lookupFunction<
      Int32 Function(Int32, Int32, Pointer<Uint8>, Pointer<Void>, Int32,
          Pointer<Uint8>, Size),
      int Function(int, int, Pointer<Uint8>, Pointer<Void>, int, Pointer<Uint8>,
          int)>('rc_format');
  late final _parse = library.lookupFunction<
      Int32 Function(Int32, Pointer<Uint8>, Pointer<Uint8>),
      int Function(int, Pointer<Uint8>, Pointer<Uint8>)>('rc_parse');
  late final _validate = library.lookupFunction<
      Int32 Function(Int32, Int32, Pointer<_NativeRules>),
      int Function(int, int, Pointer<_NativeRules>)>('rc_validate_range');
  late final _select = library.lookupFunction<
      Int32 Function(Int32, _NativeSelection, Int32, Pointer<_NativeRules>,
          Pointer<_NativeSelection>),
      int Function(int, _NativeSelection, int, Pointer<_NativeRules>,
          Pointer<_NativeSelection>)>('rc_select');
  late final _message = library.lookupFunction<Pointer<Uint8> Function(Int32),
      Pointer<Uint8> Function(int)>('rc_status_message');
  static int _int32(int value) {
    if (value < -2147483648 || value > 2147483647)
      throw RangeError.range(value, -2147483648, 2147483647);
    return value;
  }

  Pointer<Uint8> _string(String text) {
    if (text.contains('\u0000')) throw ArgumentError('NUL in string');
    final bytes = utf8.encode(text);
    final p = _memory(bytes.length + 1).cast<Uint8>();
    p.asTypedList(bytes.length + 1).setAll(0, [...bytes, 0]);
    return p;
  }

  Pointer<Void> _memory(int size) {
    final p = _alloc(size);
    if (p == nullptr) throw StateError('Native allocation failed');
    return p;
  }

  String _read(Pointer<Uint8> p) {
    var length = 0;
    while (p[length] != 0) {
      length++;
    }
    return utf8.decode(p.asTypedList(length));
  }

  void _check(int status) {
    if (status != 0) throw RoozException(status, _read(_message(status)));
  }

  CivilDate date(int year, int month, int day,
          {CalendarSystem calendar = CalendarSystem.jalali}) =>
      fromEpochDay(
          _toDay(calendar.index, _int32(year), _int32(month), _int32(day)),
          calendar: calendar);
  CivilDate fromEpochDay(int day,
      {CalendarSystem calendar = CalendarSystem.jalali}) {
    if (_field(calendar.index, _int32(day), 0) == _invalid) _check(1);
    return CivilDate._(this, calendar, day);
  }

  CivilDate parse(String text,
      {String pattern = '%Y/%m/%d',
      CalendarSystem calendar = CalendarSystem.jalali}) {
    final t = _string(text);
    try {
      final p = _string(pattern);
      try {
        return fromEpochDay(_parse(calendar.index, t, p), calendar: calendar);
      } finally {
        _free(p.cast());
      }
    } finally {
      _free(t.cast());
    }
  }

  T _withRules<T>(RangeRules rules, T Function(Pointer<_NativeRules>) body) {
    final r = _memory(sizeOf<_NativeRules>()).cast<_NativeRules>();
    Pointer<Int32> blocked = nullptr;
    try {
      if (rules.blockedDays.isNotEmpty) {
        blocked =
            _memory(rules.blockedDays.length * sizeOf<Int32>()).cast<Int32>();
        for (var i = 0; i < rules.blockedDays.length; i++) {
          blocked[i] = _int32(rules.blockedDays[i]);
        }
      }
      r.ref
        ..minimum = _int32(rules.minimum.epochDay)
        ..maximum = _int32(rules.maximum.epochDay)
        ..minLength = _int32(rules.minLength)
        ..maxLength = _int32(rules.maxLength)
        ..disabledWeekdays = rules.disabledWeekdays
        ..blocked = blocked
        ..blockedCount = rules.blockedDays.length;
      return body(r);
    } finally {
      _free(blocked.cast());
      _free(r.cast());
    }
  }

  void validateRange(CivilDate start, CivilDate end, RangeRules rules) =>
      _withRules(
          rules, (r) => _check(_validate(start.epochDay, end.epochDay, r)));
  DateSelection select(
      DateSelection current, CivilDate tapped, RangeRules rules,
      {SelectionMode mode = SelectionMode.range,
      void Function(CivilDate, CivilDate)? validator}) {
    final old = _memory(sizeOf<_NativeSelection>()).cast<_NativeSelection>();
    try {
      old.ref
        ..start = current.start?.epochDay ?? _invalid
        ..end = current.end?.epochDay ?? _invalid;
      final out = _memory(sizeOf<_NativeSelection>()).cast<_NativeSelection>();
      try {
        _withRules(
            rules,
            (r) =>
                _check(_select(mode.index, old.ref, tapped.epochDay, r, out)));
        final candidateStart =
            fromEpochDay(out.ref.start, calendar: tapped.calendar);
        final candidateEnd = out.ref.end == _invalid
            ? null
            : fromEpochDay(out.ref.end, calendar: tapped.calendar);
        validator?.call(candidateStart, candidateEnd ?? candidateStart);
        return DateSelection._(candidateStart, candidateEnd);
      } finally {
        _free(out.cast());
      }
    } finally {
      _free(old.cast());
    }
  }
}

class CivilDate {
  final Rooz engine;
  final CalendarSystem calendar;
  final int epochDay;
  const CivilDate._(this.engine, this.calendar, this.epochDay);
  int get year => engine._field(calendar.index, epochDay, 0);
  int get month => engine._field(calendar.index, epochDay, 1);
  int get day => engine._field(calendar.index, epochDay, 2);
  int get weekday => engine._field(calendar.index, epochDay, 3);
  int get monthLength => engine._field(calendar.index, epochDay, 4);
  int get dayOfYear => engine._field(calendar.index, epochDay, 5);
  CivilDate convertTo(CalendarSystem system) =>
      engine.fromEpochDay(epochDay, calendar: system);
  CivilDate addDays(int amount) => engine.fromEpochDay(
      engine._addDays(calendar.index, epochDay, Rooz._int32(amount)),
      calendar: calendar);
  CivilDate addMonths(int amount,
          {MonthOverflow overflow = MonthOverflow.clamp}) =>
      engine.fromEpochDay(
          engine._addMonths(
              calendar.index, epochDay, Rooz._int32(amount), overflow.index),
          calendar: calendar);
  String format(
      {String pattern = '%Y/%m/%d',
      RoozLocale locale = RoozLocale.persian,
      DigitSet digits = DigitSet.persian}) {
    final p = engine._string(pattern);
    try {
      final capacity = utf8.encode(pattern).length * 128 + 256;
      final out = engine._memory(capacity).cast<Uint8>();
      try {
        engine._check(engine._format(
            calendar.index,
            epochDay,
            p,
            engine._locale(calendar.index, locale.index),
            digits.index,
            out,
            capacity));
        return engine._read(out);
      } finally {
        engine._free(out.cast());
      }
    } finally {
      engine._free(p.cast());
    }
  }

  List<CivilDate?> monthGrid({int firstWeekday = 6}) {
    final start =
        engine._grid(calendar.index, year, month, Rooz._int32(firstWeekday));
    if (start == Rooz._invalid) engine._check(1);
    return List.unmodifiable(List.generate(42, (i) {
      try {
        return engine.fromEpochDay(start + i, calendar: calendar);
      } on RoozException {
        return null;
      }
    }));
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      calendar == other.calendar &&
      epochDay == other.epochDay;
  @override
  int get hashCode => Object.hash(calendar, epochDay);
  @override
  String toString() =>
      format(locale: RoozLocale.english, digits: DigitSet.latin);
}

class RangeRules {
  final CivilDate minimum, maximum;
  final int minLength, maxLength, disabledWeekdays;
  final List<int> blockedDays;
  RangeRules(
      {required this.minimum,
      required this.maximum,
      this.minLength = 1,
      this.maxLength = 2147483647,
      this.disabledWeekdays = 0,
      List<int> blockedDays = const []})
      : blockedDays = List.unmodifiable(blockedDays) {
    if (disabledWeekdays < 0 || disabledWeekdays > 127)
      throw RangeError.range(disabledWeekdays, 0, 127);
  }
}

class DateSelection {
  final CivilDate? start, end;
  const DateSelection()
      : start = null,
        end = null;
  const DateSelection._(this.start, this.end);
  bool get isComplete => start != null && end != null;
  bool contains(CivilDate day) =>
      start != null &&
      day.epochDay >= start!.epochDay &&
      day.epochDay <= (end ?? start)!.epochDay;
  DateSelection tap(CivilDate date, RangeRules rules,
          {SelectionMode mode = SelectionMode.range,
          void Function(CivilDate, CivilDate)? validator}) =>
      date.engine.select(this, date, rules, mode: mode, validator: validator);
}
