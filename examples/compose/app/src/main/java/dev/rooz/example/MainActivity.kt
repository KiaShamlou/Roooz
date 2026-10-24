package dev.rooz.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import dev.rooz.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { Surface { BookingCalendar() } } }
    }
}

@Composable
fun BookingCalendar() {
    var month by remember { mutableStateOf(CivilDate(1403, 1, 1)) }
    var selection by remember { mutableStateOf(DateSelection()) }
    var message by remember { mutableStateOf("شروع و پایان بازه را انتخاب کنید") }
    val minimum = remember { CivilDate(1400, 1, 1) }
    val maximum = remember { CivilDate(1410, 12, 29) }
    val rules = remember { RangeRules(minimum, maximum, maxLength = 30) }
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)
            .verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text("روز · تقویم جلالی", style = MaterialTheme.typography.headlineMedium)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                TextButton(onClick = { month = month.plusMonths(-1) }, modifier = Modifier.testTag("previous-month")) { Text("ماه قبل") }
                Text(month.format("%B %Y"), modifier = Modifier.testTag("month-title"))
                TextButton(onClick = { month = month.plusMonths(1) }, modifier = Modifier.testTag("next-month")) { Text("ماه بعد") }
            }
            Row { listOf("ش", "ی", "د", "س", "چ", "پ", "ج").forEach { Text(it, Modifier.weight(1f)) } }
            RoozMonthGrid(month, selection, isEnabled = { it.epochDay in minimum.epochDay..maximum.epochDay }, onDateTapped = { date ->
                try {
                    selection = selection.tap(date, rules)
                    message = if (selection.isComplete) "${selection.start!!.format()} ← ${selection.end!!.format()}" else "تاریخ پایان را انتخاب کنید"
                } catch (_: RoozException) { message = "این بازه معتبر نیست؛ حداکثر ۳۰ روز" }
            }) { date, selected, inMonth ->
                Text(date.format("%d"), modifier = Modifier.testTag("day-${date.epochDay}"),
                    color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface.copy(alpha = if (inMonth) 1f else .4f))
            }
            Text(message, Modifier.testTag("selection-status"))
            TextButton(onClick = { selection = DateSelection(); message = "شروع و پایان بازه را انتخاب کنید" }, modifier = Modifier.testTag("clear-selection")) { Text("پاک کردن انتخاب") }
        }
    }
}
