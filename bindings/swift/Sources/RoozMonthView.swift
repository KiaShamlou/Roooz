#if canImport(SwiftUI)
import SwiftUI

/// Unstyled, controlled month grid: supply your own header and day view.
/// State, navigation, events, layout direction and business policy remain app-owned.
public struct RoozMonthView<DayContent: View>: View {
    private let days: [CivilDate?]
    private let month: Int32
    private let selection: DateSelection
    private let isEnabled: (CivilDate) -> Bool
    private let onTap: (CivilDate) -> Void
    private let accessibilityLabel: (CivilDate) -> String
    private let content: (CivilDate, Bool, Bool) -> DayContent
    public init(month: CivilDate, firstWeekday: Int32 = 6, selection: DateSelection,
                isEnabled: @escaping (CivilDate) -> Bool = { _ in true },
                accessibilityLabel: @escaping (CivilDate) -> String = { (try? $0.formatted("%A %d %B %Y")) ?? "" },
                onTap: @escaping (CivilDate) -> Void,
                @ViewBuilder dayContent: @escaping (CivilDate, Bool, Bool) -> DayContent) throws {
        days = try month.monthGrid(firstWeekday: firstWeekday); self.month = month.month
        self.selection = selection; self.isEnabled = isEnabled; self.onTap = onTap
        self.accessibilityLabel = accessibilityLabel; self.content = dayContent
    }
    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    Button { onTap(date) } label: {
                        content(date, selection.contains(date), date.month == month)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain).disabled(!isEnabled(date))
                    .accessibilityLabel(accessibilityLabel(date))
                    .accessibilityAddTraits(selection.contains(date) ? .isSelected : [])
                } else { Color.clear.frame(height: 44).accessibilityHidden(true) }
            }
        }
    }
}
#endif
