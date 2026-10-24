package dev.rooz

fun main() {
    var count = 0
    java.io.File("tests/fixtures/jalali-boundaries.tsv").forEachLine { line ->
        val (epoch, year, month, day) = line.split('\t').map(String::toInt)
        val date = CivilDate(year, month, day)
        check(date.epochDay == epoch)
        val inverse = CivilDate.fromEpochDay(epoch)
        check(listOf(inverse.year, inverse.month, inverse.day) == listOf(year, month, day))
        check(CivilDate.parse(date.format()) == date)
        if (month == 12) check(runCatching { CivilDate(year, month, day + 1) }.isFailure)
        count++
    }
    check(count == 6354)
    for (c in CalendarSystem.entries) {
        val first = CivilDate(1, 1, 1, c)
        check(runCatching { first.plusDays(-1) }.isFailure)
        val year = if (c == CalendarSystem.JALALI) 3177 else 9999
        val end = CivilDate(year, 12, 1, c).let { it.plusDays(it.monthLength - 1) }
        check(runCatching { end.plusDays(1) }.isFailure)
        check(end.monthGrid().size == 42)
    }
    println("PASS Kotlin shared corpus: $count Jalali boundaries")
    val n = CivilDate(1403, 1, 1)
    val g = n.convertTo(CalendarSystem.GREGORIAN)
    check(listOf(g.year, g.month, g.day) == listOf(2024, 3, 20))
    check(CivilDate.parse("۱۴۰۳/۰۱/۰۱") == n)
    check(n.format("%A %d %B %Y") == "چهارشنبه ۰۱ فروردین ۱۴۰۳")
    check(n.format("📅 %Y", digits = Digits.LATIN) == "📅 1403")
    check(n.monthGrid().size == 42)
    check(n.monthGrid()[0] == CivilDate(1402, 12, 26))
    check(runCatching { CivilDate(1400, 12, 30) }.isFailure)
    check(runCatching { CivilDate.parse("1403/01/01\u0000junk") }.isFailure)
    check(CivilDate(1403, 6, 31).plusMonths(1).day == 30)
    check(runCatching { CivilDate(1403, 6, 31).plusMonths(1, Overflow.REJECT) }.isFailure)
    val rules = RangeRules(n, n.plusDays(30), minLength = 2, maxLength = 10, blockedDays = listOf(n.plusDays(7).epochDay))
    val s = DateSelection().tap(n.plusDays(5), rules).tap(n.plusDays(2), rules)
    check(s.start == n.plusDays(2) && s.end == n.plusDays(5))
    check(n.plusDays(3) in s)
    val pending = DateSelection().tap(n, rules)
    check(runCatching { pending.tap(n.plusDays(9), rules) }.exceptionOrNull() is RoozException)
    check(pending.end == null)
    check(runCatching { DateSelection().tap(n, rules, validator = { _, _ -> error("custom policy") }) }.isFailure)
    println("PASS Kotlin/JNI: conversion, formatting, parsing, grid, arithmetic, range rejection")
}
