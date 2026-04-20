import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'models/sport.dart';
import 'services/stats_service.dart';

class AppState extends ChangeNotifier {
  static const _prefKeyNotifyDevUpdates = 'notify_dev_updates';
  static const _prefKeyPendingUpdateVersion = 'pending_update_version';
  static const _prefKeyPendingUpdateUrl = 'pending_update_url';
  static const _prefKeyPendingUpdateIsDev = 'pending_update_is_dev';

  final statsService = StatsService();
  final List<Player> _players = [];
  Sport _selectedSport = Sport.soccer;
  int _teamCount = 2;
  bool _wheelEnabled = false;
  bool _notifyDevUpdates = false;
  bool _autoAskForResults = true;
  String? _pendingUpdateVersion;
  String? _pendingUpdateUrl;
  bool _pendingUpdateIsDev = false;

  List<Player> get players => List.unmodifiable(_players);
  Sport get selectedSport => _selectedSport;
  int get teamCount => _teamCount;
  bool get wheelEnabled => _wheelEnabled;
  bool get notifyDevUpdates => _notifyDevUpdates;
  bool get autoAskForResults => _autoAskForResults;
  String? get pendingUpdateVersion => _pendingUpdateVersion;
  String? get pendingUpdateUrl => _pendingUpdateUrl;
  bool get pendingUpdateIsDev => _pendingUpdateIsDev;

  bool get canGenerate => _players.length >= _teamCount;

  /// Load persisted settings. Call once from main() before runApp.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifyDevUpdates = prefs.getBool(_prefKeyNotifyDevUpdates) ?? false;
    _pendingUpdateVersion = prefs.getString(_prefKeyPendingUpdateVersion);
    _pendingUpdateUrl = prefs.getString(_prefKeyPendingUpdateUrl);
    _pendingUpdateIsDev = prefs.getBool(_prefKeyPendingUpdateIsDev) ?? false;
  }

  void setWheelEnabled(bool value) {
    _wheelEnabled = value;
    notifyListeners();
  }

  void setNotifyDevUpdates(bool value) {
    _notifyDevUpdates = value;
    notifyListeners();
    // Persistence is fire-and-forget: the UI updates immediately while the
    // write happens asynchronously in the background.
    _saveSettings();
  }

  void setAutoAskForResults(bool value) {
    _autoAskForResults = value;
    notifyListeners();
  }

  /// Records that an update is available. Persists across app restarts.
  void setPendingUpdate(String version, String? url, {bool isDev = false}) {
    _pendingUpdateVersion = version;
    _pendingUpdateUrl = url;
    _pendingUpdateIsDev = isDev;
    notifyListeners();
    _saveSettings();
  }

  /// Clears the pending update notification (called on dismiss or view release).
  void clearPendingUpdate() {
    _pendingUpdateVersion = null;
    _pendingUpdateUrl = null;
    _pendingUpdateIsDev = false;
    notifyListeners();
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pendingUpdateVersion != null) {
      await Future.wait([
        prefs.setBool(_prefKeyNotifyDevUpdates, _notifyDevUpdates),
        prefs.setString(_prefKeyPendingUpdateVersion, _pendingUpdateVersion!),
        if (_pendingUpdateUrl != null)
          prefs.setString(_prefKeyPendingUpdateUrl, _pendingUpdateUrl!)
        else
          prefs.remove(_prefKeyPendingUpdateUrl),
        prefs.setBool(_prefKeyPendingUpdateIsDev, _pendingUpdateIsDev),
      ]);
    } else {
      await Future.wait([
        prefs.setBool(_prefKeyNotifyDevUpdates, _notifyDevUpdates),
        prefs.remove(_prefKeyPendingUpdateVersion),
        prefs.remove(_prefKeyPendingUpdateUrl),
        prefs.remove(_prefKeyPendingUpdateIsDev),
      ]);
    }
  }

  void addPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _players.add(
      Player(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
      ),
    );
    notifyListeners();
  }

  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void renamePlayer(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _players[idx] = _players[idx].copyWith(name: trimmed);
    notifyListeners();
  }

  void selectSport(Sport sport) {
    _selectedSport = sport;
    // Clamp teamCount to something sensible
    if (_teamCount < 2) _teamCount = 2;
    notifyListeners();
  }

  void setTeamCount(int count) {
    if (count < 2) return;
    _teamCount = count;
    notifyListeners();
  }

  void clearPlayers() {
    _players.clear();
    notifyListeners();
  }
}
