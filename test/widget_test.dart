// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:teamup/app_state.dart';
import 'package:teamup/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (
    WidgetTester tester,
  ) async {
    final state = AppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(TeamUpApp(state: state));
    // Home screen should render without crashing
    expect(find.text('TeamUp'), findsOneWidget);
  });
}
