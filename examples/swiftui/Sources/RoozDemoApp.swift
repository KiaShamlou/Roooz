import SwiftUI

@main
struct RoozDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView { BookingCalendar() }
#if os(macOS)
                .frame(minWidth: 440, minHeight: 520)
#endif
        }
    }
}
