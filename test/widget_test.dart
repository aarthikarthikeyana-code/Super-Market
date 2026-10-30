import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_customer/main.dart';

void main() {
  testWidgets('Freshness customer app smoke test', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FreshnessSupermarketApp(),
      ),
    );

    // Verify that the splash screen shows the title.
    expect(find.text('Fresh Groceries'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
