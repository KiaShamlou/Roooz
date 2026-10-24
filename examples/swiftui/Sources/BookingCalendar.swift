import SwiftUI
import RoozCalendar

/// A runnable, deterministic booking demo. Dates are civil days, not instants.
struct BookingCalendar: View {
    @State private var month = try! CivilDate(1403, 1, 1)
    @State private var selection = DateSelection()
    @State private var message = "شروع و پایان بازه را انتخاب کنید"
    private let rules = RangeRules(minimum: try! CivilDate(1400, 1, 1),
                                   maximum: try! CivilDate(1410, 12, 29), maxLength: 30)
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("ماه قبل") { navigate(-1) }.accessibilityIdentifier("previous-month")
                Spacer()
                Text((try? month.formatted("%B %Y")) ?? "").font(.title2.bold()).accessibilityIdentifier("month-title")
                Spacer()
                Button("ماه بعد") { navigate(1) }.accessibilityIdentifier("next-month")
            }
            HStack {
                ForEach(["ش", "ی", "د", "س", "چ", "پ", "ج"].indices, id: \.self) { i in
                    Text(["ش", "ی", "د", "س", "چ", "پ", "ج"][i]).frame(maxWidth: .infinity)
                }
            }.foregroundStyle(.secondary)
            if let grid = try? RoozMonthView(month: month, selection: selection,
                isEnabled: { $0.epochDay >= rules.minimum && $0.epochDay <= rules.maximum },
                onTap: select,
                dayContent: { date, selected, inMonth in
                    Text((try? date.formatted("%d")) ?? "")
                        .font(.body.monospacedDigit()).accessibilityIdentifier("day-\(date.epochDay)")
                        .foregroundStyle(selected ? Color.white : Color.primary.opacity(inMonth ? 1 : 0.35))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selected ? Color.teal : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                }) { grid }
            Text(message).font(.callout).accessibilityLabel(message).accessibilityIdentifier("selection-status")
            Button("پاک کردن انتخاب") { selection.clear(); message = "شروع و پایان بازه را انتخاب کنید" }.accessibilityIdentifier("clear-selection")
        }
        .padding(24).frame(maxWidth: 520)
        .environment(\.layoutDirection, .rightToLeft)
    }
    private func navigate(_ amount: Int32) {
        if let next = try? month.adding(months: amount) { month = next }
    }
    private func select(_ date: CivilDate) {
        do {
            try selection.tap(date, rules: rules)
            if let start = selection.start, let end = selection.end {
                message = "\(try start.formatted()) ← \(try end.formatted())"
            } else { message = "تاریخ پایان را انتخاب کنید" }
        } catch { message = "این بازه معتبر نیست؛ بازه‌ای تا ۳۰ روز انتخاب کنید" }
    }
}
