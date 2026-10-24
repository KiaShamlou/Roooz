// Controlled UI: this demo consumes the local Rooz Android library.
package dev.rooz.example

import androidx.compose.foundation.layout.*
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import dev.rooz.CivilDate
import dev.rooz.DateSelection

/** Caller owns UI state, day styling, event badges, locale and selection policy. */
@Composable
fun RoozMonthGrid(
    month: CivilDate,
    selection: DateSelection,
    onDateTapped: (CivilDate) -> Unit,
    firstWeekday: Int = 6,
    isEnabled: (CivilDate) -> Boolean = { true },
    label: (CivilDate) -> String = { it.format("%A %d %B %Y") },
    dayContent: @Composable (CivilDate, Boolean, Boolean) -> Unit
) {
    val days = month.monthGrid(firstWeekday)
    Column {
        days.chunked(7).forEach { week ->
            Row {
                week.forEach { date ->
                    Box(Modifier.weight(1f).heightIn(min = 48.dp)) {
                        if (date != null) TextButton(
                            onClick = { onDateTapped(date) }, enabled = isEnabled(date),
                            modifier = Modifier.fillMaxWidth().semantics {
                                selected = date in selection
                                contentDescription = label(date)
                            }
                        ) { dayContent(date, date in selection, date.month == month.month) }
                    }
                }
            }
        }
    }
}
