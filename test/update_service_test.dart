import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:teamup/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    late UpdateService service;

    setUp(() {
      service = UpdateService();
    });

    test('returns true when latest is greater than current (patch)', () {
      expect(service.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });

    test('returns true when latest is greater than current (minor)', () {
      expect(service.isNewerVersion('1.1.0', '1.0.0'), isTrue);
    });

    test('returns true when latest is greater than current (major)', () {
      expect(service.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('returns false when versions are equal', () {
      expect(service.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('returns false when latest is lower than current', () {
      expect(service.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('handles missing patch segment', () {
      expect(service.isNewerVersion('1.1', '1.0.0'), isTrue);
    });
  });

  group('UpdateService.isDevVersion', () {
    late UpdateService service;

    setUp(() {
      service = UpdateService();
    });

    test('returns true for version with .dev suffix', () {
      expect(service.isDevVersion('1.1.0.dev'), isTrue);
    });

    test('returns true for version with .dev and trailing identifier', () {
      expect(service.isDevVersion('1.1.0.dev1'), isTrue);
    });

    test('returns false for stable version', () {
      expect(service.isDevVersion('1.1.0'), isFalse);
    });
  });

  group('UpdateService.checkForUpdate – stable only', () {
    _stableClient(String tagName, String htmlUrl) => MockClient(
      (_) async => http.Response(
        jsonEncode({'tag_name': tagName, 'html_url': htmlUrl}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    test('isUpdateAvailable is true when a newer version is published', () async {
      final service = UpdateService(
        client: _stableClient('v2.0.0', 'https://github.com/test/repo/releases/v2.0.0'),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isTrue);
      expect(result.latestVersion, '2.0.0');
      expect(result.isDev, isFalse);
      expect(result.releaseUrl, 'https://github.com/test/repo/releases/v2.0.0');
    });

    test('isUpdateAvailable is false when already on latest version', () async {
      final service = UpdateService(
        client: _stableClient('v1.0.0', 'https://github.com/test/repo/releases/v1.0.0'),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isFalse);
    });

    test('handles tag without v-prefix', () async {
      final service = UpdateService(
        client: _stableClient('2.0.0', 'https://github.com/test/repo/releases/2.0.0'),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isTrue);
      expect(result.latestVersion, '2.0.0');
    });

    test('isUpdateAvailable is false on non-200 response', () async {
      final service = UpdateService(
        client: MockClient((_) async => http.Response('Not Found', 404)),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isFalse);
    });

    test('isUpdateAvailable is false on network error', () async {
      final service = UpdateService(
        client: MockClient((_) async => throw Exception('network error')),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isFalse);
    });
  });

  group('UpdateService.checkForUpdate – includeDevVersions', () {
    /// Returns a client that:
    ///  • responds to the /releases/latest URL with [stableTag]
    ///  • responds to the /releases list URL with [devReleases]
    MockClient _devClient({
      required String stableTag,
      required List<Map<String, dynamic>> devReleases,
    }) {
      return MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({'tag_name': stableTag, 'html_url': 'https://github.com/test/releases/$stableTag'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        // /releases list
        return http.Response(
          jsonEncode(devReleases),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    test('returns dev update when dev version is newer and no stable update', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v1.0.0',
          devReleases: [
            {'tag_name': 'v1.1.0.dev', 'html_url': 'https://github.com/test/releases/v1.1.0.dev', 'draft': false},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0', includeDevVersions: true);
      expect(result.isUpdateAvailable, isTrue);
      expect(result.isDev, isTrue);
      expect(result.latestVersion, '1.1.0.dev');
    });

    test('returns stable update when stable is newer than dev', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v2.0.0',
          devReleases: [
            {'tag_name': 'v1.1.0.dev', 'html_url': 'https://github.com/test/releases/v1.1.0.dev', 'draft': false},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0', includeDevVersions: true);
      expect(result.isUpdateAvailable, isTrue);
      expect(result.isDev, isFalse);
      expect(result.latestVersion, '2.0.0');
    });

    test('returns dev update when dev numeric version is higher than stable', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v1.1.0',
          devReleases: [
            {'tag_name': 'v1.2.0.dev', 'html_url': 'https://github.com/test/releases/v1.2.0.dev', 'draft': false},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0', includeDevVersions: true);
      expect(result.isUpdateAvailable, isTrue);
      expect(result.isDev, isTrue);
      expect(result.latestVersion, '1.2.0.dev');
    });

    test('stable wins tie when dev has same numeric version as stable', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v1.1.0',
          devReleases: [
            {'tag_name': 'v1.1.0.dev', 'html_url': 'https://github.com/test/releases/v1.1.0.dev', 'draft': false},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0', includeDevVersions: true);
      expect(result.isUpdateAvailable, isTrue);
      expect(result.isDev, isFalse);
      expect(result.latestVersion, '1.1.0');
    });

    test('skips drafts in dev releases list', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v1.0.0',
          devReleases: [
            {'tag_name': 'v1.1.0.dev', 'html_url': 'https://github.com/test/releases/v1.1.0.dev', 'draft': true},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0', includeDevVersions: true);
      expect(result.isUpdateAvailable, isFalse);
    });

    test('does not show dev update when includeDevVersions is false', () async {
      final service = UpdateService(
        client: _devClient(
          stableTag: 'v1.0.0',
          devReleases: [
            {'tag_name': 'v1.1.0.dev', 'html_url': 'https://github.com/test/releases/v1.1.0.dev', 'draft': false},
          ],
        ),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isFalse);
    });
  });
}
