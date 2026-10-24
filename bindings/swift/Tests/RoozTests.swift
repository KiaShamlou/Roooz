import XCTest
@testable import RoozCalendar

final class RoozTests: XCTestCase {
    func testConversionAndParsing() throws {
        let d = try CivilDate(1403, 1, 1)
        let g = try d.converted(to: .gregorian)
        XCTAssertEqual([g.year, g.month, g.day], [2024, 3, 20])
        XCTAssertEqual(try CivilDate.parse("۱۴۰۳/۰۱/۰۱"), d)
        XCTAssertEqual(try d.formatted("%A %d %B %Y"), "چهارشنبه ۰۱ فروردین ۱۴۰۳")
        XCTAssertThrowsError(try CivilDate(1400, 12, 30))
        XCTAssertThrowsError(try CivilDate.parse("1403/01/01\0junk"))
        XCTAssertThrowsError(try d.formatted("%Q"))
    }
    func testArithmeticAndGrid() throws {
        let d = try CivilDate(1403, 6, 31)
        XCTAssertEqual(try d.adding(months: 1).day, 30)
        XCTAssertThrowsError(try d.adding(months: 1, overflow: .reject))
        XCTAssertEqual(try d.monthGrid().count, 42)
        XCTAssertEqual(try CivilDate(1403, 1, 1).monthGrid()[0]!, try CivilDate(1402, 12, 26))
        XCTAssertNil(try CivilDate(1, 1, 1).monthGrid(firstWeekday: 1).first!)
    }
    func testRangeStateAndInteriorBlock() throws {
        let start = try CivilDate(1403, 1, 1), end = try CivilDate(1403, 1, 31)
        var rules = RangeRules(minimum: start, maximum: end, minLength: 2, maxLength: 10)
        var selection = DateSelection()
        try selection.tap(start.adding(days: 5), rules: rules)
        XCTAssertNil(selection.end)
        try selection.tap(start.adding(days: 2), rules: rules)
        XCTAssertEqual(selection.start, try start.adding(days: 2))
        XCTAssertTrue(selection.contains(try start.adding(days: 3)))
        selection.clear(); rules.blockedDays = [try start.adding(days: 3).epochDay]
        try selection.tap(start, rules: rules)
        XCTAssertThrowsError(try selection.tap(start.adding(days: 5), rules: rules))
        XCTAssertEqual(selection.start, start); XCTAssertNil(selection.end)
        selection.clear()
        XCTAssertThrowsError(try selection.tap(start, rules: rules, validator: { _, _ in throw RoozError(code: 6) }))
        XCTAssertNil(selection.start)
    }
    func testExplicitTimeZone() throws {
        let instant = Date(timeIntervalSince1970: 1710892800) // 2024-03-20 UTC
        let utc = try CivilDate.from(instant, timeZone: TimeZone(secondsFromGMT: 0)!)
        let west = try CivilDate.from(instant, timeZone: TimeZone(secondsFromGMT: -3600)!)
        XCTAssertEqual(utc.epochDay - west.epochDay, 1)
        let ancient = try CivilDate(100, 1, 1, calendar: .gregorian)
        XCTAssertEqual(try CivilDate.from(Date(timeIntervalSince1970: Double(ancient.epochDay) * 86400),
            timeZone: TimeZone(secondsFromGMT: 0)!, calendar: .gregorian), ancient)
    }
}

final class ConformanceTests: XCTestCase {
    func testSharedJalaliBoundaries() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: root.appendingPathComponent("tests/fixtures/jalali-boundaries.tsv"), encoding: .utf8)
        let rows = text.split(separator: "\n")
        XCTAssertEqual(rows.count, 6354)
        for row in rows {
            let v = row.split(separator: "\t").map { Int32($0)! }
            let date = try CivilDate(v[1], v[2], v[3])
            XCTAssertEqual(date.epochDay, v[0])
            let inverse = try CivilDate(epochDay: v[0])
            XCTAssertEqual([inverse.year, inverse.month, inverse.day], Array(v[1...3]))
            XCTAssertEqual(try CivilDate.parse(date.formatted()), date)
            if v[2] == 12 { XCTAssertThrowsError(try CivilDate(v[1], 12, v[3] + 1)) }
        }
    }
    func testAllCalendarLimits() throws {
        for c in CalendarSystem.allCases {
            let first = try CivilDate(1, 1, 1, calendar: c)
            XCTAssertThrowsError(try first.adding(days: -1))
            let lastMonth = try CivilDate(c == .jalali ? 3177 : 9999, 12, 1, calendar: c)
            let last = try lastMonth.adding(days: lastMonth.monthLength - 1)
            XCTAssertThrowsError(try last.adding(days: 1))
            XCTAssertEqual(try last.monthGrid().count, 42)
        }
    }
    func testSingleSelectionAndInvalidRules() throws {
        let date = try CivilDate(1403, 1, 1)
        var selection = DateSelection()
        let rules = RangeRules(minimum: date, maximum: try date.adding(days: 30), minLength: 5)
        try selection.tap(date, mode: .single, rules: rules)
        XCTAssertEqual(selection.start, selection.end)
        let old = selection
        let invalid = RangeRules(minimum: date, maximum: date, disabledWeekdays: 128)
        XCTAssertThrowsError(try selection.tap(date, rules: invalid))
        XCTAssertEqual(selection, old)
    }
    func testNonFiniteInstants() {
        let utc = TimeZone(secondsFromGMT: 0)!
        XCTAssertThrowsError(try CivilDate.from(Date(timeIntervalSince1970: .infinity), timeZone: utc))
        XCTAssertThrowsError(try CivilDate.from(Date(timeIntervalSince1970: .nan), timeZone: utc))
    }
}
