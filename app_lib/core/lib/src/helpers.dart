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

  // Gamepad key constants (lowercase for comparison)

  /// D-pad up key variations.
  static const Set<String> dpadUpKeys = {'dpad up', 'up'};

  /// D-pad down key variations.
  static const Set<String> dpadDownKeys = {'dpad down', 'down'};

  /// D-pad left key variations.
  static const Set<String> dpadLeftKeys = {'dpad left', 'left'};

  /// D-pad right key variations.
  static const Set<String> dpadRightKeys = {'dpad right', 'right'};

  /// South button (A/Cross) key variations.
  static const Set<String> buttonSouthKeys = {'a', 'button south', 'cross'};

  /// East button (B/Circle) key variations.
  static const Set<String> buttonEastKeys = {'b', 'button east', 'circle'};

  /// West button (X/Square) key variations.
  static const Set<String> buttonWestKeys = {'x', 'button west', 'square'};

  /// North button (Y/Triangle) key variations.
  static const Set<String> buttonNorthKeys = {'y', 'button north', 'triangle'};

  /// Start button key variations.
  static const Set<String> buttonStartKeys = {'start', 'options', 'menu'};

  /// Select button key variations.
  static const Set<String> buttonSelectKeys = {'select', 'back', 'share'};

  /// Left bumper key variations.
  static const Set<String> leftBumperKeys = {'left bumper', 'lb', 'l1'};

  /// Right bumper key variations.
  static const Set<String> rightBumperKeys = {'right bumper', 'rb', 'r1'};

  /// Left trigger key variations.
  static const Set<String> leftTriggerKeys = {'left trigger', 'lt', 'l2'};

  /// Right trigger key variations.
  static const Set<String> rightTriggerKeys = {'right trigger', 'rt', 'r2'};

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

  // Audio constants

  /// Default volume for sound effects (0.0 to 1.0).
  static const double audioSfxVolumeDefault = 1.0;

  /// Default volume for background music (0.0 to 1.0).
  static const double audioMusicVolumeDefault = 0.5;

  // Component drawing constants

  /// Outer padding for terminal/door frame from component edge (pixels).
  static const double componentFramePadding = 2.0;

  /// Inner padding for terminal screen/door surface (pixels).
  static const double componentInnerPadding = 6.0;

  /// Width of terminal/door frame (componentInnerPadding - componentFramePadding) (pixels).
  static const double componentFrameWidth = 4.0;

  /// Corner radius for terminal/door components (pixels).
  static const double componentCornerRadius = 4.0;

  /// Additional height offset for terminal screen bottom edge (pixels).
  static const double terminalScreenBottomOffset = 4.0;

  /// Door handle offset from near edge (pixels).
  static const double doorHandleOffset = 8.0;

  /// Door handle radius (pixels).
  static const double doorHandleRadius = 3.0;

  /// Arrow indicator offset from center (pixels).
  static const double arrowBaseOffset = 6.0;

  /// Arrow indicator tip offset (pixels).
  static const double arrowTipOffset = 5.0;

  /// Arrow indicator perpendicular offset (pixels).
  static const double arrowPerpOffset = 3.0;

  // Glow animation constants

  /// Base stroke width for glow effect (pixels).
  static const double glowStrokeBase = 2.0;

  /// Additional stroke width at max glow intensity (pixels).
  static const double glowStrokeAmplitude = 2.0;

  /// Base opacity for glow effect (0.0 to 1.0).
  static const double glowOpacityBase = 0.6;

  /// Additional opacity at max glow intensity (0.0 to 1.0).
  static const double glowOpacityAmplitude = 0.4;

  /// Highlight border inset from component edge (pixels).
  static const double highlightBorderInset = 1.0;

  /// Glow intensity oscillation center (0.5 for balanced sine wave).
  static const double glowIntensityCenter = 0.5;

  // Player character drawing constants

  /// Player head vertical offset from center (pixels).
  static const double playerHeadYOffset = 4.0;

  /// Player head radius (pixels).
  static const double playerHeadRadius = 8.0;

  /// Player body vertical offset from center (pixels).
  static const double playerBodyYOffset = 8.0;

  /// Player body width (pixels).
  static const double playerBodyWidth = 12.0;

  /// Player body height (pixels).
  static const double playerBodyHeight = 14.0;

  /// Player body corner radius (pixels).
  static const double playerBodyRadius = 3.0;

  /// Player outline stroke width (pixels).
  static const double playerOutlineStrokeWidth = 2.0;

  /// Player default move speed (pixels per second).
  static const double playerMoveSpeed = 150.0;

  /// Player movement threshold for position snap (pixels).
  static const double playerMovementThreshold = 1.0;
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

/// Parse an enum value by name safely, returning [defaultValue] if parsing fails.
///
/// This is safer than using [Enum.byName] directly because it catches
/// [ArgumentError] thrown when the name doesn't match any enum value.
///
/// Example:
/// ```dart
/// final type = parseEnum(DeviceType.values, json['type'], DeviceType.server);
/// ```
T parseEnum<T extends Enum>(List<T> values, String? name, T defaultValue) {
  if (name == null) return defaultValue;
  try {
    return values.byName(name);
  } on ArgumentError {
    return defaultValue;
  }
}

/// Parse a DateTime from ISO 8601 string safely, returning [defaultValue] if parsing fails.
///
/// This is safer than using [DateTime.parse] directly because it catches
/// [FormatException] thrown when the string is malformed.
///
/// Example:
/// ```dart
/// final createdAt = parseDateTime(json['createdAt'], DateTime.now());
/// ```
DateTime parseDateTime(String? value, DateTime defaultValue) {
  if (value == null) return defaultValue;
  try {
    return DateTime.parse(value);
  } on FormatException {
    return defaultValue;
  }
}
