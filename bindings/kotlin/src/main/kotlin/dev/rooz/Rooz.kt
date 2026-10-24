package dev.rooz

enum class CalendarSystem { GREGORIAN, JALALI, ISLAMIC_CIVIL, JULIAN }
enum class Digits { LATIN, PERSIAN, ARABIC }
enum class Locale { ENGLISH, PERSIAN, ARABIC }
enum class Overflow { CLAMP, REJECT }
enum class SelectionMode { SINGLE, RANGE }
class RoozException(val code: Int) : IllegalArgumentException("Rooz: ${Native.message(code)}")

/** Load from java.library.path (JVM), or Android's packaged jniLibs. */
internal object Native {
    init { System.loadLibrary("rooz_jni"); check(abi() == 1) { "Unsupported Rooz ABI" } }
    external fun abi(): Int
    external fun message(code: Int): String
    external fun toDay(c: Int, y: Int, m: Int, d: Int): Int
    external fun field(c: Int, day: Int, field: Int): Int
    external fun addDays(c: Int, day: Int, n: Int): Int
    external fun addMonths(c: Int, day: Int, n: Int, overflow: Int): Int
    external fun grid(c: Int, y: Int, m: Int, first: Int): Int
    external fun format(c: Int, day: Int, pattern: String, locale: Int, digits: Int): String
    external fun parse(c: Int, text: String, pattern: String): Int
    external fun validate(start: Int, end: Int, rules: IntArray, blocked: IntArray): Int
    external fun select(mode: Int, start: Int, end: Int, tap: Int, rules: IntArray, blocked: IntArray): IntArray
}

/** Civil date without time-of-day or an implicit time zone. Equality includes the calendar. */
class CivilDate private constructor(val epochDay: Int, val calendar: CalendarSystem) {
    init { if (Native.field(calendar.ordinal, epochDay, 0) == Int.MIN_VALUE) throw RoozException(1) }
    constructor(year: Int, month: Int, day: Int, calendar: CalendarSystem = CalendarSystem.JALALI) :
        this(Native.toDay(calendar.ordinal, year, month, day), calendar)
    val year get() = Native.field(calendar.ordinal, epochDay, 0)
    val month get() = Native.field(calendar.ordinal, epochDay, 1)
    val day get() = Native.field(calendar.ordinal, epochDay, 2)
    val weekday get() = Native.field(calendar.ordinal, epochDay, 3)
    val monthLength get() = Native.field(calendar.ordinal, epochDay, 4)
    val dayOfYear get() = Native.field(calendar.ordinal, epochDay, 5)
    fun convertTo(system: CalendarSystem) = fromEpochDay(epochDay, system)
    fun plusDays(amount: Int) = fromEpochDay(Native.addDays(calendar.ordinal, epochDay, amount), calendar)
    fun plusMonths(amount: Int, overflow: Overflow = Overflow.CLAMP) =
        fromEpochDay(Native.addMonths(calendar.ordinal, epochDay, amount, overflow.ordinal), calendar)
    fun format(pattern: String = "%Y/%m/%d", locale: Locale = Locale.PERSIAN, digits: Digits = Digits.PERSIAN): String {
        require('\u0000' !in pattern) { "NUL in pattern" }
        return Native.format(calendar.ordinal, epochDay, pattern, locale.ordinal, digits.ordinal)
    }
    fun monthGrid(firstWeekday: Int = 6): List<CivilDate?> {
        val first = Native.grid(calendar.ordinal, year, month, firstWeekday)
        if (first == Int.MIN_VALUE) throw RoozException(1)
        return List(42) { runCatching { fromEpochDay(first + it, calendar) }.getOrNull() }
    }
    override fun equals(other: Any?) = other is CivilDate && epochDay == other.epochDay && calendar == other.calendar
    override fun hashCode() = 31 * epochDay + calendar.ordinal
    override fun toString() = format(locale = Locale.ENGLISH, digits = Digits.LATIN)
    companion object {
        fun fromEpochDay(day: Int, calendar: CalendarSystem = CalendarSystem.JALALI) = CivilDate(day, calendar)
        fun parse(text: String, pattern: String = "%Y/%m/%d", calendar: CalendarSystem = CalendarSystem.JALALI): CivilDate {
            require('\u0000' !in text && '\u0000' !in pattern) { "NUL in input" }
            return fromEpochDay(Native.parse(calendar.ordinal, text, pattern), calendar)
        }
    }
}

class RangeRules(
    minimum: CivilDate, maximum: CivilDate, minLength: Int = 1, maxLength: Int = Int.MAX_VALUE,
    disabledWeekdays: Int = 0, blockedDays: List<Int> = emptyList()
) {
    internal val values = intArrayOf(minimum.epochDay, maximum.epochDay, minLength, maxLength, disabledWeekdays)
    internal val blocked = blockedDays.toIntArray()
    fun validate(start: CivilDate, end: CivilDate) {
        val code = Native.validate(start.epochDay, end.epochDay, values, blocked)
        if (code != 0) throw RoozException(code)
    }
}
/** Immutable selection reducer. Keep it in StateFlow, Compose state, or any other UI store. */
class DateSelection private constructor(val start: CivilDate?, val end: CivilDate?) {
    constructor() : this(null, null)
    val isComplete get() = start != null && end != null
    operator fun contains(date: CivilDate): Boolean = start != null &&
        date.epochDay >= start.epochDay && date.epochDay <= (end ?: start).epochDay
    fun tap(date: CivilDate, rules: RangeRules, mode: SelectionMode = SelectionMode.RANGE,
            validator: ((CivilDate, CivilDate) -> Unit)? = null): DateSelection {
        val r = Native.select(mode.ordinal, start?.epochDay ?: Int.MIN_VALUE, end?.epochDay ?: Int.MIN_VALUE,
            date.epochDay, rules.values, rules.blocked)
        if (r[0] != 0) throw RoozException(r[0])
        val candidateStart = CivilDate.fromEpochDay(r[1], date.calendar)
        val candidateEnd = if (r[2] == Int.MIN_VALUE) null else CivilDate.fromEpochDay(r[2], date.calendar)
        validator?.invoke(candidateStart, candidateEnd ?: candidateStart)
        return DateSelection(candidateStart, candidateEnd)
    }
}
