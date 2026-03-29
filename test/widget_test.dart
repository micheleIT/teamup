// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:teamup/main.dart';

void main() {
  testWidgets('App launches and shows home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TeamUpApp());
    // Home screen should render without crashing
    expect(find.text('TeamUp'), findsOneWidget);
  });
}
