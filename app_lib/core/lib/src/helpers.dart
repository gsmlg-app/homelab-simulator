import 'position.dart';

/// Constants for the game grid
class GameConstants {
  static const double tileSize = 32.0;
  static const int roomWidth = 20;
  static const int roomHeight = 12;
  static const GridPosition terminalPosition = GridPosition(2, 2);
  static const GridPosition playerStartPosition = GridPosition(10, 6);
  static const int startingCredits = 1000;
}

/// Convert grid position to pixel position
(double, double) gridToPixel(GridPosition pos) {
  return (
    pos.x * GameConstants.tileSize.toDouble(),
    pos.y * GameConstants.tileSize.toDouble(),
  );
}

/// Convert pixel position to grid position
GridPosition pixelToGrid(double x, double y) {
  return GridPosition(
    (x / GameConstants.tileSize).floor(),
    (y / GameConstants.tileSize).floor(),
  );
}

/// Check if position is within room bounds
bool isWithinBounds(GridPosition pos) {
  return pos.x >= 0 &&
      pos.x < GameConstants.roomWidth &&
      pos.y >= 0 &&
      pos.y < GameConstants.roomHeight;
}

/// Count occurrences of items by a key selector.
///
/// Returns a map where keys are the extracted values and values are counts.
///
/// Example:
/// ```dart
/// final devices = [Device(type: server), Device(type: router), Device(type: server)];
/// final counts = countBy(devices, (d) => d.type);
/// // {server: 2, router: 1}
/// ```
Map<K, int> countBy<T, K>(Iterable<T> items, K Function(T) keySelector) {
  final counts = <K, int>{};
  for (final item in items) {
    final key = keySelector(item);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Group items by a key selector.
///
/// Returns a map where keys are the extracted values and values are lists of items.
///
/// Example:
/// ```dart
/// final devices = [Device(type: server, name: 'a'), Device(type: server, name: 'b')];
/// final grouped = groupBy(devices, (d) => d.type);
/// // {server: [Device(name: 'a'), Device(name: 'b')]}
/// ```
Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) keySelector) {
  final groups = <K, List<T>>{};
  for (final item in items) {
    final key = keySelector(item);
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups;
}
