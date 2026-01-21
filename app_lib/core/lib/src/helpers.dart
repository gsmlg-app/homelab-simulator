import 'position.dart';

/// Constants for the game grid
class GameConstants {
  static const double tileSize = 32.0;
  static const int roomWidth = 20;
  static const int roomHeight = 12;
  static const GridPosition terminalPosition = GridPosition(2, 2);
  static const GridPosition playerStartPosition = GridPosition(10, 6);
  static const int startingCredits = 1000;

  /// The entity ID used for the terminal component.
  static const String terminalEntityId = 'terminal';

  /// Threshold for gamepad button press detection.
  /// Values above this are considered "pressed".
  static const double gamepadButtonPressThreshold = 0.5;

  /// Deadzone for analog stick input.
  /// Values below this magnitude are ignored.
  static const double gamepadAnalogDeadzone = 0.3;

  /// Cooldown time in seconds for D-pad input to prevent rapid repeats.
  static const double gamepadDpadCooldownSeconds = 0.15;

  // Animation constants

  /// Device LED flicker animation frequency multiplier.
  static const double deviceFlickerFrequency = 3.0;

  /// Device LED flicker minimum brightness (0.0-1.0).
  static const double deviceFlickerMin = 0.85;

  /// Device LED flicker amplitude (brightness range = min to min + amplitude).
  static const double deviceFlickerAmplitude = 0.15;

  /// Door glow animation frequency multiplier.
  static const double doorGlowFrequency = 4.0;

  /// Terminal screen flicker animation frequency multiplier.
  static const double terminalFlickerFrequency = 4.0;

  /// Terminal screen flicker minimum brightness (0.0-1.0).
  static const double terminalFlickerMin = 0.9;

  /// Terminal screen flicker amplitude.
  static const double terminalFlickerAmplitude = 0.1;

  /// Placement ghost breathing animation frequency multiplier.
  static const double placementBreatheFrequency = 3.0;

  /// Placement ghost breathing animation base fill opacity.
  static const double placementBreatheMinOpacity = 0.4;

  /// Placement ghost breathing animation fill opacity amplitude.
  static const double placementBreatheAmplitude = 0.1;

  /// Placement ghost breathing animation base border opacity.
  static const double placementBreatheBorderMinOpacity = 0.7;

  /// Placement ghost breathing animation border opacity amplitude.
  static const double placementBreatheBorderAmplitude = 0.3;

  // Drawing constants

  /// Standard padding for device body drawing (pixels).
  static const double deviceBodyPadding = 4.0;

  /// Standard corner radius for device body (pixels).
  static const double deviceCornerRadius = 4.0;

  /// Inset for selection highlight stroke (pixels).
  static const double deviceSelectionInset = 2.0;

  /// Device LED indicator radius (pixels).
  static const double deviceLedRadius = 3.0;

  /// Device LED indicator offset from edge (pixels).
  static const double deviceLedOffset = 10.0;
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
