import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamup/app_state.dart';
import 'package:teamup/models/team.dart';
import 'package:teamup/screens/teams_screen.dart';

// Helpers ─────────────────────────────────────────────────────────────────────

AppState _makeState() {
  final state = AppState();
  state.addPlayer('Alice');
  state.addPlayer('Bob');
  state.addPlayer('Charlie');
  state.addPlayer('Dave');
  return state;
}

Widget _buildScreen(AppState state) {
  final teams = [
    Team(number: 1, players: [state.players[0], state.players[1]]),
    Team(number: 2, players: [state.players[2], state.players[3]]),
  ];
  return MaterialApp(
    home: TeamsScreen(state: state, precomputedTeams: teams),
  );
}

// Complete the record-result sheet: select the first team option and save.
// Assumes the caller has already triggered the sheet to appear (e.g. via tap).
Future<void> _completeRecordSheet(WidgetTester tester) async {
  await tester.pumpAndSettle(); // wait for sheet slide-in animation to finish
  await tester.tap(find.byType(OutlinedButton).first);
  await tester.pump(); // rebuild with winner selected
  await tester.tap(find.text('Save Result'));
  await tester.pumpAndSettle(); // dismiss + addRecord + setState + snackbar
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TeamsScreen – result-recording guard', () {
    testWidgets('record button is enabled initially', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_buildScreen(state));

      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.emoji_events_outlined),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('record button is disabled after saving a result', (
      tester,
    ) async {
      final state = _makeState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_buildScreen(state));

      // Open sheet and save a result
      await tester.tap(find.byTooltip('Record result'));
      await _completeRecordSheet(tester);

      // Button should now show the filled icon and be disabled
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      final btn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.emoji_events),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets(
      'manual record button re-enabled after reshuffling new teams',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Record a result
        await tester.tap(find.byTooltip('Record result'));
        await _completeRecordSheet(tester);

        // Reshuffle — autoAskForResults is true but _resultRecorded is true,
        // so no sheet should appear; new teams are rolled.
        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pump();

        // Sheet was NOT shown (no 'Who won?' visible) …
        expect(find.textContaining('Who won?'), findsNothing);
        // … and the record button is active again with the outlined icon.
        final btn = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.emoji_events_outlined),
        );
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      'reshuffle shows record sheet when result has not been saved yet',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Reshuffle without having recorded a result first
        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pump();
        await tester.pump(); // let sheet animate in

        // The record-result bottom sheet should appear
        expect(find.textContaining('Who won?'), findsOneWidget);
      },
    );

    testWidgets(
      'reshuffle does not show record sheet when result was already saved',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Record manually first
        await tester.tap(find.byTooltip('Record result'));
        await _completeRecordSheet(tester);

        // Reshuffle — no sheet expected
        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('Who won?'), findsNothing);
      },
    );

    testWidgets(
      'reshuffle does not show record sheet when autoAskForResults is off',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        state.setAutoAskForResults(false);
        await tester.pumpWidget(_buildScreen(state));

        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('Who won?'), findsNothing);
      },
    );

    testWidgets(
      'reshuffle shows "Reshuffle without saving" button in the record sheet',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Trigger reshuffle — sheet should appear with the skip button
        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pumpAndSettle();

        expect(find.text('Reshuffle without saving'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Reshuffle without saving" reshuffles without recording a result',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Trigger reshuffle — sheet appears
        await tester.tap(find.byTooltip('Shuffle again'));
        await tester.pumpAndSettle();

        // Tap the skip button
        await tester.tap(find.text('Reshuffle without saving'));
        await tester.pumpAndSettle();

        // Sheet is dismissed
        expect(find.textContaining('Who won?'), findsNothing);
        // No result was recorded — button is still enabled with outlined icon
        final btn = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.emoji_events_outlined),
        );
        expect(btn.onPressed, isNotNull);
        // Stats service should have no records
        expect(state.statsService.records, isEmpty);
      },
    );

    testWidgets(
      'manual "Record result" button does not show "Reshuffle without saving"',
      (tester) async {
        final state = _makeState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_buildScreen(state));

        // Open the sheet via the manual record button
        await tester.tap(find.byTooltip('Record result'));
        await tester.pumpAndSettle();

        // The skip button should NOT appear here
        expect(find.text('Reshuffle without saving'), findsNothing);
      },
    );
  });
}
