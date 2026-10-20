import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_practice/main.dart';

void main() {
  testWidgets('Splash screen loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ServiceFlowApp());

    // Verify that the title text exists
    expect(find.text('Field Service Management'), findsOneWidget);
    expect(find.text('จัดการงานบริการได้ทุกที่'), findsOneWidget);
  });
}
