import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app shows the initial screen text.
    expect(find.text('MediConnect Initial Screen'), findsOneWidget);
  });
}
