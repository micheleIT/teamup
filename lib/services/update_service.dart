import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of an update availability check.
class UpdateCheckResult {
  final bool isUpdateAvailable;
  final String? latestVersion;
  final String? releaseUrl;

  /// Whether the available version is a dev release.
  final bool isDev;

  /// `true` when the check could not complete due to a network or parse error.
  /// Callers should not clear persisted update state when this is `true`.
  final bool checkFailed;

  const UpdateCheckResult({
    required this.isUpdateAvailable,
    this.latestVersion,
    this.releaseUrl,
    this.isDev = false,
    this.checkFailed = false,
  });
}

/// Checks GitHub releases for a newer version of the app.
class UpdateService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/micheleIT/teamup/releases/latest';
  static const _releasesListApiUrl =
      'https://api.github.com/repos/micheleIT/teamup/releases';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const _githubHeaders = {'Accept': 'application/vnd.github+json'};

  /// Checks whether a newer release exists on GitHub.
  ///
  /// When [includeDevVersions] is `true`, also checks for newer dev releases
  /// (tags containing `.dev`). If both a stable and a dev update are found,
  /// the one with the higher version number is returned (stable wins a tie).
  ///
  /// If only the dev check fails, the stable result is returned as a partial
  /// success so a transient second-request failure does not discard an already-
  /// found update.  On a complete failure [checkFailed] is set to `true`.
  Future<UpdateCheckResult> checkForUpdate(
    String currentVersion, {
    bool includeDevVersions = false,
  }) async {
    final stableResult = await _checkStableRelease(currentVersion);
    if (stableResult.checkFailed) return stableResult;
    if (!includeDevVersions) return stableResult;

    final devResult = await _checkLatestDevRelease(currentVersion);
    // If the dev check failed, return the stable result as a partial success
    // rather than surfacing an error to the user.
    if (devResult.checkFailed) return stableResult;

    if (!stableResult.isUpdateAvailable && !devResult.isUpdateAvailable) {
      return const UpdateCheckResult(isUpdateAvailable: false);
    }
    if (!devResult.isUpdateAvailable) return stableResult;
    if (!stableResult.isUpdateAvailable) return devResult;

    // Both available – return the higher version; stable wins a tie.
    final stableNumeric = stableResult.latestVersion ?? '';
    final devNumeric = _stripDevSuffix(devResult.latestVersion ?? '');
    return isNewerVersion(devNumeric, stableNumeric) ? devResult : stableResult;
  }

  Future<UpdateCheckResult> _checkStableRelease(String currentVersion) async {
    try {
      final response = await _client
          .get(Uri.parse(_releasesApiUrl), headers: _githubHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final releaseUrl = data['html_url'] as String?;

      return UpdateCheckResult(
        isUpdateAvailable: isNewerVersion(latestVersion, currentVersion),
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } catch (e) {
      debugPrint('UpdateService: stable check failed: $e');
      return const UpdateCheckResult(isUpdateAvailable: false, checkFailed: true);
    }
  }

  Future<UpdateCheckResult> _checkLatestDevRelease(
    String currentVersion,
  ) async {
    try {
      final response = await _client
          .get(Uri.parse(_releasesListApiUrl), headers: _githubHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }

      final releases = jsonDecode(response.body) as List<dynamic>;

      UpdateCheckResult? best;
      for (final item in releases) {
        final release = item as Map<String, dynamic>;
        if (release['draft'] == true) continue;

        final tagName = release['tag_name'] as String? ?? '';
        final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        if (!isDevVersion(version)) continue;

        if (!isNewerVersion(version, currentVersion)) continue;

        if (best == null ||
            isNewerVersion(version, best.latestVersion ?? '')) {
          best = UpdateCheckResult(
            isUpdateAvailable: true,
            latestVersion: version,
            releaseUrl: release['html_url'] as String?,
            isDev: true,
          );
        }
      }

      return best ?? const UpdateCheckResult(isUpdateAvailable: false);
    } catch (e) {
      debugPrint('UpdateService: dev check failed: $e');
      return const UpdateCheckResult(isUpdateAvailable: false, checkFailed: true);
    }
  }

  /// Returns `true` when [latest] is strictly greater than [current].
  ///
  /// Both strings are expected to be in `MAJOR.MINOR.PATCH[.dev]` format.
  /// Non-numeric segments are treated as 0.
  /// When numeric parts are equal, a stable release is considered newer than
  /// a dev release (e.g. `1.0.0` is newer than `1.0.0.dev`).
  bool isNewerVersion(String latest, String current) {
    final l = _parseParts(latest);
    final c = _parseParts(current);
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    // Numeric parts are equal: a stable release supersedes a dev release.
    return !isDevVersion(latest) && isDevVersion(current);
  }

  /// Returns `true` if [version] contains a `.dev` suffix.
  bool isDevVersion(String version) => version.contains('.dev');

  /// Strips the `.dev` suffix (and any characters after it) from [version].
  String _stripDevSuffix(String version) {
    final idx = version.indexOf('.dev');
    return idx == -1 ? version : version.substring(0, idx);
  }

  List<int> _parseParts(String version) {
    final stripped = _stripDevSuffix(version);
    final parts =
        stripped.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}
