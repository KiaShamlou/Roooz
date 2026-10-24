import Foundation
import CRooz

public enum CalendarSystem: Int32, CaseIterable, Sendable {
    case gregorian = 0, jalali = 1, islamicCivil = 2, julian = 3
}
public enum DigitSet: Int32, Sendable { case latin = 0, persian = 1, arabic = 2 }
public enum RoozLocale: Int32, Sendable { case english = 0, persian = 1, arabic = 2 }
public enum MonthOverflow: Int32, Sendable { case clamp = 0, reject = 1 }
public struct RoozError: Error, CustomStringConvertible, Equatable, Sendable {
    public let code: Int32
    public var description: String { String(cString: rc_status_message(code)) }
    public init(code: Int32) { self.code = code }
}

/// An immutable civil date, with no implicit time zone or clock access.
public struct CivilDate: Hashable, Sendable {
    public let calendar: CalendarSystem
    public let epochDay: Int32
    public init(_ year: Int32, _ month: Int32, _ day: Int32, calendar: CalendarSystem = .jalali) throws {
        try self.init(epochDay: rc_to_day(calendar.rawValue, year, month, day), calendar: calendar)
    }
    public init(epochDay: Int32, calendar: CalendarSystem = .jalali) throws {
        guard rc_get_field(calendar.rawValue, epochDay, 0) != Int32.min else { throw RoozError(code: 1) }
        self.epochDay = epochDay; self.calendar = calendar
    }
    private func field(_ index: Int32) -> Int32 { rc_get_field(calendar.rawValue, epochDay, index) }
    public var year: Int32 { field(0) }
    public var month: Int32 { field(1) }
    public var day: Int32 { field(2) }
    public var weekday: Int32 { field(3) }
    public var monthLength: Int32 { field(4) }
    public var dayOfYear: Int32 { field(5) }
    public func converted(to calendar: CalendarSystem) throws -> CivilDate {
        try CivilDate(epochDay: epochDay, calendar: calendar)
    }
    public func adding(days: Int32) throws -> CivilDate {
        try CivilDate(epochDay: rc_add_days(calendar.rawValue, epochDay, days), calendar: calendar)
    }
    public func adding(months: Int32, overflow: MonthOverflow = .clamp) throws -> CivilDate {
        try CivilDate(epochDay: rc_add_months(calendar.rawValue, epochDay, months, overflow.rawValue), calendar: calendar)
    }
    public func formatted(_ pattern: String = "%Y/%m/%d", locale: RoozLocale = .persian, digits: DigitSet = .persian) throws -> String {
        guard !pattern.utf8.contains(0) else { throw RoozError(code: 8) }
        // Capacity grows with caller's pattern; each token expands to <=128 bytes in built-in locales.
        var buffer = [CChar](repeating: 0, count: max(256, pattern.utf8.count * 128 + 1))
        let status = pattern.withCString { p in
            rc_format(calendar.rawValue, epochDay, p, rc_builtin_locale(calendar.rawValue, locale.rawValue), digits.rawValue, &buffer, buffer.count)
        }
        guard status == 0 else { throw RoozError(code: status) }
        return String(cString: buffer)
    }
    public static func parse(_ text: String, pattern: String = "%Y/%m/%d", calendar: CalendarSystem = .jalali) throws -> CivilDate {
        guard !text.utf8.contains(0), !pattern.utf8.contains(0) else { throw RoozError(code: 1) }
        let day = text.withCString { t in pattern.withCString { p in rc_parse(calendar.rawValue, t, p) } }
        return try CivilDate(epochDay: day, calendar: calendar)
    }
    /// Fixed six-week grid. Nil edge cells lie outside the calendar's supported years.
    public func monthGrid(firstWeekday: Int32 = 6) throws -> [CivilDate?] {
        let start = rc_grid_start(calendar.rawValue, year, month, firstWeekday)
        guard start != Int32.min else { throw RoozError(code: 1) }
        return (0..<42).map { try? CivilDate(epochDay: start + Int32($0), calendar: calendar) }
    }
    /// Explicit projection of an instant onto a civil day in a chosen time zone.
    public static func from(_ instant: Date, timeZone: TimeZone, calendar: CalendarSystem = .jalali) throws -> CivilDate {
        // Project the instant directly; Foundation's historical Gregorian cutover
        // must not silently change our explicitly proleptic date contract.
        let day = floor((instant.timeIntervalSince1970 + Double(timeZone.secondsFromGMT(for: instant))) / 86400)
        guard day.isFinite, day > Double(Int32.min), day <= Double(Int32.max) else { throw RoozError(code: 1) }
        return try CivilDate(epochDay: Int32(day), calendar: calendar)
    }
}

public struct RangeRules: Sendable {
    public var minimum: Int32
    public var maximum: Int32
    public var minLength: Int32
    public var maxLength: Int32
    public var disabledWeekdays: UInt32
    public var blockedDays: [Int32]
    public init(minimum: CivilDate, maximum: CivilDate, minLength: Int32 = 1,
                maxLength: Int32 = Int32.max, disabledWeekdays: UInt32 = 0, blockedDays: [Int32] = []) {
        self.minimum = minimum.epochDay; self.maximum = maximum.epochDay
        self.minLength = minLength; self.maxLength = maxLength
        self.disabledWeekdays = disabledWeekdays; self.blockedDays = blockedDays
    }
    fileprivate func withNative<T>(_ body: (UnsafePointer<rc_rules>) throws -> T) rethrows -> T {
        try blockedDays.withUnsafeBufferPointer { blocked in
            var rules = rc_rules(min_day: minimum, max_day: maximum, min_length: minLength,
                                 max_length: maxLength, disabled_weekdays: disabledWeekdays,
                                 blocked_days: blocked.baseAddress, blocked_count: blocked.count)
            return try withUnsafePointer(to: &rules, body)
        }
    }
    public func validate(start: CivilDate, end: CivilDate) throws {
        let code = withNative { rc_validate_range(start.epochDay, end.epochDay, $0) }
        guard code == 0 else { throw RoozError(code: code) }
    }
}
public enum SelectionMode: Int32, Sendable { case single = 0, range = 1 }
public struct DateSelection: Equatable, Sendable {
    public private(set) var start: CivilDate?
    public private(set) var end: CivilDate?
    public init() { start = nil; end = nil }
    public var isComplete: Bool { start != nil && end != nil }
    public func contains(_ day: CivilDate) -> Bool {
        guard let start else { return false }
        return day.epochDay >= start.epochDay && day.epochDay <= (end ?? start).epochDay
    }
    public mutating func clear() { self = DateSelection() }
    /// Rejection leaves the existing state intact, including a pending range anchor.
    public mutating func tap(_ day: CivilDate, mode: SelectionMode = .range, rules: RangeRules,
                             validator: ((CivilDate, CivilDate) throws -> Void)? = nil) throws {
        let current = rc_selection(start: start?.epochDay ?? Int32.min, end: end?.epochDay ?? Int32.min)
        var result = current
        let code = rules.withNative { rc_select(mode.rawValue, current, day.epochDay, $0, &result) }
        guard code == 0 else { throw RoozError(code: code) }
        let candidateStart = try CivilDate(epochDay: result.start, calendar: day.calendar)
        let candidateEnd = result.end == Int32.min ? nil : try CivilDate(epochDay: result.end, calendar: day.calendar)
        try validator?(candidateStart, candidateEnd ?? candidateStart)
        start = candidateStart; end = candidateEnd
    }
}
