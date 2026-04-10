import 'package:flutter_test/flutter_test.dart';
import 'package:ecodex/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoDexApp());
    expect(find.byType(EcoDexApp), findsOneWidget);
  });
}