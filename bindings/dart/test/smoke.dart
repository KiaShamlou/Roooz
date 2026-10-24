import 'dart:io';
import '../lib/rooz_calendar.dart';

void check(bool condition) {
  if (!condition) throw StateError('Check failed');
}

void rejects(void Function() call) {
  var threw = false;
  try {
    call();
  } catch (_) {
    threw = true;
  }
  check(threw);
}

void main(List<String> args) {
  final rooz = Rooz.open(args.single);
  var count = 0;
  for (final line
      in File('tests/fixtures/jalali-boundaries.tsv').readAsLinesSync()) {
    final v = line.split('\t').map(int.parse).toList();
    final date = rooz.date(v[1], v[2], v[3]);
    check(date.epochDay == v[0]);
    final inverse = rooz.fromEpochDay(v[0]);
    check(inverse.year == v[1] && inverse.month == v[2] && inverse.day == v[3]);
    check(rooz.parse(date.format()) == date);
    if (v[2] == 12) rejects(() => rooz.date(v[1], 12, v[3] + 1));
    count++;
  }
  check(count == 6354);
  for (final c in CalendarSystem.values) {
    final first = rooz.date(1, 1, 1, calendar: c);
    rejects(() => first.addDays(-1));
    final lastMonth =
        rooz.date(c == CalendarSystem.jalali ? 3177 : 9999, 12, 1, calendar: c);
    final end = lastMonth.addDays(lastMonth.monthLength - 1);
    rejects(() => end.addDays(1));
    check(end.monthGrid().length == 42);
  }
  print('PASS Dart shared corpus: $count Jalali boundaries');
  final n = rooz.date(1403, 1, 1);
  final g = n.convertTo(CalendarSystem.gregorian);
  check(g.year == 2024 && g.month == 3 && g.day == 20);
  check(rooz.parse('۱۴۰۳/۰۱/۰۱') == n);
  check(n.format(pattern: '%A %d %B %Y') == 'چهارشنبه ۰۱ فروردین ۱۴۰۳');
  check(n.format(pattern: '📅 %Y', digits: DigitSet.latin) == '📅 1403');
  check(n.monthGrid().length == 42);
  check(n.monthGrid()[0] == rooz.date(1402, 12, 26));
  check(rooz.date(1403, 6, 31).addMonths(1).day == 30);
  rejects(() =>
      rooz.date(1403, 6, 31).addMonths(1, overflow: MonthOverflow.reject));
  rejects(() => rooz.date(1400, 12, 30));
  rejects(() => rooz.parse('1403/01/01\u0000junk'));
  rejects(() => rooz.date(4294968699, 1, 1)); // no silent FFI int32 truncation
  final rules = RangeRules(
      minimum: n,
      maximum: n.addDays(30),
      minLength: 2,
      maxLength: 10,
      blockedDays: [n.addDays(7).epochDay]);
  final s =
      const DateSelection().tap(n.addDays(5), rules).tap(n.addDays(2), rules);
  check(s.start == n.addDays(2) && s.end == n.addDays(5));
  check(s.contains(n.addDays(3)));
  final pending = const DateSelection().tap(n, rules);
  rejects(() => pending.tap(n.addDays(9), rules));
  check(pending.end == null);
  rejects(() => const DateSelection().tap(n, rules, validator: (_, __) {
        throw StateError('custom policy');
      }));
  print(
      'PASS Dart/FFI: conversion, formatting, parsing, grid, arithmetic, range rejection');
}
