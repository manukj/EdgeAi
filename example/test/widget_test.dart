import 'package:flutter_test/flutter_test.dart';

import 'package:edge_ai_example/main.dart';

void main() {
  testWidgets('renders the feature tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Text tools'), findsOneWidget);
  });
}
