// This is a basic Flutter widget test.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamup/app_state.dart';
import 'package:teamup/main.dart';
import 'package:teamup/screens/home_screen.dart';
import 'package:teamup/services/update_service.dart';

/// Convenience helper – only the [version] varies between tests.
void _setMockVersion(String version) {
  PackageInfo.setMockInitialValues(
    appName: 'TeamUp',
    packageName: 'com.example.teamup',
    version: version,
    buildNumber: '1',
    buildSignature: '',
  );
}

/// Builds a [MockClient] that serves a stable release and a list of all
/// releases (used for dev-version look-ups).
MockClient _devClient({
  required String stableTag,
  required List<Map<String, dynamic>> releases,
}) {
  return MockClient((request) async {
    if (request.url.path.endsWith('/releases/latest')) {
      return http.Response(
        jsonEncode({
          'tag_name': stableTag,
          'html_url': 'https://github.com/test/releases/$stableTag',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(
      jsonEncode(releases),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App launches and shows home screen', (
    WidgetTester tester,
  ) async {
    _setMockVersion('1.0.0');
    final state = AppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(TeamUpApp(state: state));
    // Home screen should render without crashing
    expect(find.text('TeamUp'), findsOneWidget);
  });

  group('HomeScreen update notification', () {
    setUp(() => _setMockVersion('1.0.0'));

    testWidgets(
      'shows banner when a newer dev release exists and current version is a dev build '
      'even if notifyDevUpdates is false',
      (tester) async {
        _setMockVersion('0.2.3.dev');

        final state = AppState();
        addTearDown(state.dispose);
        // The preference is off – this was the bug trigger.
        expect(state.notifyDevUpdates, isFalse);

        final service = UpdateService(
          client: _devClient(
            stableTag: 'v0.2.3',
            releases: [
              {
                'tag_name': 'v0.2.4.dev',
                'html_url': 'https://github.com/test/releases/v0.2.4.dev',
                'draft': false,
              },
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(state: state, updateService: service),
          ),
        );
        // Let the post-frame callback and async update check complete.
        await tester.pumpAndSettle();

        expect(find.byType(MaterialBanner), findsOneWidget);
        expect(find.text('Dev version 0.2.4.dev is available'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT show banner for a dev release when current version is stable '
      'and notifyDevUpdates is false',
      (tester) async {
        _setMockVersion('0.2.3');

        final state = AppState();
        addTearDown(state.dispose);
        expect(state.notifyDevUpdates, isFalse);

        final service = UpdateService(
          client: _devClient(
            stableTag: 'v0.2.3',
            releases: [
              {
                'tag_name': 'v0.2.4.dev',
                'html_url': 'https://github.com/test/releases/v0.2.4.dev',
                'draft': false,
              },
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(state: state, updateService: service),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MaterialBanner), findsNothing);
      },
    );

    testWidgets(
      'banner is dismissed when Dismiss is tapped',
      (tester) async {
        _setMockVersion('0.2.3.dev');

        final state = AppState();
        addTearDown(state.dispose);

        final service = UpdateService(
          client: _devClient(
            stableTag: 'v0.2.3',
            releases: [
              {
                'tag_name': 'v0.2.4.dev',
                'html_url': 'https://github.com/test/releases/v0.2.4.dev',
                'draft': false,
              },
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(state: state, updateService: service),
          ),
        );
        await tester.pumpAndSettle();

        // Banner is visible.
        expect(find.byType(MaterialBanner), findsOneWidget);

        // Tap Dismiss.
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        // Banner is gone.
        expect(find.byType(MaterialBanner), findsNothing);
      },
    );

    testWidgets(
      'shows banner immediately from persisted SharedPreferences state '
      'even when the network check fails',
      (tester) async {
        _setMockVersion('0.2.3.dev');

        // Pre-populate SharedPreferences with a saved pending update.
        SharedPreferences.setMockInitialValues({
          'pending_update_version': '0.2.4.dev',
          'pending_update_url': 'https://github.com/test/releases/v0.2.4.dev',
          'pending_update_is_dev': true,
        });

        final state = AppState();
        await state.loadSettings();
        addTearDown(state.dispose);

        // Use a service that always throws (simulates no network).
        final service = UpdateService(
          client: MockClient((_) async => throw Exception('no network')),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(state: state, updateService: service),
          ),
        );
        await tester.pumpAndSettle();

        // Banner is shown from persisted state even though the network check
        // failed and did not re-populate it.
        expect(find.byType(MaterialBanner), findsOneWidget);
        expect(find.text('Dev version 0.2.4.dev is available'), findsOneWidget);
      },
    );
  });
}
