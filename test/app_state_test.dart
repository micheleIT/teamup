import 'package:flutter_test/flutter_test.dart';
import 'package:teamup/app_state.dart';

void main() {
  group('AppState – player name uniqueness', () {
    late AppState state;

    setUp(() => state = AppState());
    tearDown(() => state.dispose());

    test('addPlayer returns true and adds the player', () {
      final result = state.addPlayer('Alice');
      expect(result, isTrue);
      expect(state.players.length, 1);
      expect(state.players.first.name, 'Alice');
    });

    test('addPlayer rejects an exact duplicate name', () {
      state.addPlayer('Alice');
      final result = state.addPlayer('Alice');
      expect(result, isFalse);
      expect(state.players.length, 1);
    });

    test('addPlayer rejects a duplicate name with different casing', () {
      state.addPlayer('Alice');
      final result = state.addPlayer('ALICE');
      expect(result, isFalse);
      expect(state.players.length, 1);
    });

    test('addPlayer rejects a duplicate name with surrounding whitespace', () {
      state.addPlayer('Alice');
      final result = state.addPlayer('  Alice  ');
      expect(result, isFalse);
      expect(state.players.length, 1);
    });

    test('addPlayer returns false for an empty name', () {
      final result = state.addPlayer('   ');
      expect(result, isFalse);
      expect(state.players, isEmpty);
    });

    test('addPlayer allows two players with different names', () {
      state.addPlayer('Alice');
      final result = state.addPlayer('Bob');
      expect(result, isTrue);
      expect(state.players.length, 2);
    });

    test('renamePlayer returns true and renames the player', () {
      state.addPlayer('Alice');
      final id = state.players.first.id;
      final result = state.renamePlayer(id, 'Alicia');
      expect(result, isTrue);
      expect(state.players.first.name, 'Alicia');
    });

    test('renamePlayer rejects renaming to an existing name', () {
      state.addPlayer('Alice');
      state.addPlayer('Bob');
      final id = state.players.first.id;
      final result = state.renamePlayer(id, 'Bob');
      expect(result, isFalse);
      expect(state.players.first.name, 'Alice');
    });

    test('renamePlayer rejects renaming to an existing name (different casing)',
        () {
      state.addPlayer('Alice');
      state.addPlayer('Bob');
      final id = state.players.first.id;
      final result = state.renamePlayer(id, 'BOB');
      expect(result, isFalse);
      expect(state.players.first.name, 'Alice');
    });

    test('renamePlayer allows keeping the same name (no-op)', () {
      state.addPlayer('Alice');
      final id = state.players.first.id;
      final result = state.renamePlayer(id, 'Alice');
      expect(result, isTrue);
      expect(state.players.first.name, 'Alice');
    });

    test('renamePlayer returns false for an empty name', () {
      state.addPlayer('Alice');
      final id = state.players.first.id;
      final result = state.renamePlayer(id, '  ');
      expect(result, isFalse);
      expect(state.players.first.name, 'Alice');
    });
  });
}
