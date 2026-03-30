import 'package:flutter/foundation.dart';
import 'models/player.dart';
import 'models/sport.dart';

class AppState extends ChangeNotifier {
  final List<Player> _players = [];
  Sport _selectedSport = Sport.soccer;
  int _teamCount = 2;
  bool _wheelEnabled = false;

  List<Player> get players => List.unmodifiable(_players);
  Sport get selectedSport => _selectedSport;
  int get teamCount => _teamCount;
  bool get wheelEnabled => _wheelEnabled;

  bool get canGenerate => _players.length >= _teamCount;

  void setWheelEnabled(bool value) {
    _wheelEnabled = value;
    notifyListeners();
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
