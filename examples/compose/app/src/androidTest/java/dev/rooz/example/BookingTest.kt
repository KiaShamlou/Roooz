package dev.rooz.example
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.Rule
import org.junit.Test

class BookingTest {
    @get:Rule val ui = createAndroidComposeRule<MainActivity>()
    @Test fun selectReverseRangeNavigateAndClear() {
        ui.onNodeWithTag("day-19807", useUnmergedTree = true).performClick() // 1403/01/06
        ui.onNodeWithTag("day-19804", useUnmergedTree = true).performClick() // 1403/01/03
        ui.onNodeWithTag("selection-status").assertTextEquals("۱۴۰۳/۰۱/۰۳ ← ۱۴۰۳/۰۱/۰۶")
        ui.onNodeWithTag("next-month").performClick()
        ui.onNodeWithTag("month-title").assertTextEquals("اردیبهشت ۱۴۰۳")
        ui.onNodeWithTag("clear-selection").performClick()
        ui.onNodeWithTag("selection-status").assertTextEquals("شروع و پایان بازه را انتخاب کنید")
    }
}
