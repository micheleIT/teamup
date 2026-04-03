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

  group('UpdateService.checkForUpdate', () {
    _githubResponse(String tagName, String htmlUrl) => MockClient(
      (_) async => http.Response(
        jsonEncode({'tag_name': tagName, 'html_url': htmlUrl}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    test('isUpdateAvailable is true when a newer version is published', () async {
      final service = UpdateService(
        client: _githubResponse('v2.0.0', 'https://github.com/test/repo/releases/v2.0.0'),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isTrue);
      expect(result.latestVersion, '2.0.0');
      expect(result.releaseUrl, 'https://github.com/test/repo/releases/v2.0.0');
    });

    test('isUpdateAvailable is false when already on latest version', () async {
      final service = UpdateService(
        client: _githubResponse('v1.0.0', 'https://github.com/test/repo/releases/v1.0.0'),
      );
      final result = await service.checkForUpdate('1.0.0');
      expect(result.isUpdateAvailable, isFalse);
    });

    test('handles tag without v-prefix', () async {
      final service = UpdateService(
        client: _githubResponse('2.0.0', 'https://github.com/test/repo/releases/2.0.0'),
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
}
