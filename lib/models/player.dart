import 'package:flutter/foundation.dart';

@immutable
class Player {
  final String id;
  final String name;

  const Player({required this.id, required this.name});

  Player copyWith({String? name}) =>
      Player(id: id, name: name ?? this.name);

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Player && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
