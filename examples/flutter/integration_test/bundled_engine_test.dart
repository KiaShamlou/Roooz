import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rooz_native/rooz_native.dart';
import 'package:rooz_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('packaged engine ABI and Nowruz', (tester) async {
    final engine = openBundledRooz();
    final date = engine.date(1403, 1, 1).convertTo(CalendarSystem.gregorian);
    expect([date.year, date.month, date.day], [2024, 3, 20]);
    expect(() => engine.date(1400, 12, 30), throwsA(isA<RoozException>()));
    await tester.pumpWidget(BookingApp(engine: engine));
    expect(find.text('فروردین ۱۴۰۳'), findsOneWidget);
  });
}
