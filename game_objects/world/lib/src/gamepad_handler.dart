import 'dart:async';
import 'package:flame/components.dart';
import 'package:gamepads/gamepads.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Callback for gamepad direction input
typedef GamepadDirectionCallback = void Function(Direction direction);

/// Callback for gamepad button input
typedef GamepadButtonCallback = void Function(GamepadButton button);

/// Enum for gamepad buttons we care about
enum GamepadButton {
  south, // A/Cross - confirm/interact
  east, // B/Circle - cancel/back
  north, // Y/Triangle
  west, // X/Square
  start, // Start/Options
  select, // Select/Share
  leftBumper,
  rightBumper,
  leftTrigger,
  rightTrigger,
}

/// Component that handles gamepad input
class GamepadHandler extends Component {
  final GamepadDirectionCallback? onDirection;
  final GamepadButtonCallback? onButtonPressed;
  final GamepadButtonCallback? onButtonReleased;

  StreamSubscription<GamepadEvent>? _subscription;

  // Track current direction to avoid repeated events
  Direction _currentDirection = Direction.none;

  // Debounce for D-pad
  double _dpadCooldown = 0;

  GamepadHandler({
    this.onDirection,
    this.onButtonPressed,
    this.onButtonReleased,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _subscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dpadCooldown > 0) {
      _dpadCooldown -= dt;
    }
  }

  void _handleGamepadEvent(GamepadEvent event) {
    switch (event.type) {
      case KeyType.button:
        _handleButtonEvent(event);
      case KeyType.analog:
        _handleAnalogEvent(event);
    }
  }

  void _handleButtonEvent(GamepadEvent event) {
    final pressed = event.value > GameConstants.gamepadButtonPressThreshold;
    final button = _mapKeyToButton(event.key);

    // Handle D-pad as direction
    final direction = _mapKeyToDirection(event.key);
    if (direction != null && direction != Direction.none) {
      if (pressed && _dpadCooldown <= 0) {
        onDirection?.call(direction);
        _dpadCooldown = GameConstants.gamepadDpadCooldownSeconds;
      }
      return;
    }

    if (button != null) {
      if (pressed) {
        onButtonPressed?.call(button);
      } else {
        onButtonReleased?.call(button);
      }
    }
  }

  void _handleAnalogEvent(GamepadEvent event) {
    // Handle left stick for movement
    final key = event.key.toLowerCase();
    if (key.contains('left') && key.contains('x')) {
      _leftStickX = event.value;
      _updateAnalogDirection();
    } else if (key.contains('left') && key.contains('y')) {
      _leftStickY = event.value;
      _updateAnalogDirection();
    }
  }

  // Track analog values for combined direction
  double _leftStickX = 0;
  double _leftStickY = 0;

  void _updateAnalogDirection() {
    // Calculate direction from stick position
    Direction newDirection = Direction.none;

    if (_leftStickX.abs() > GameConstants.gamepadAnalogDeadzone ||
        _leftStickY.abs() > GameConstants.gamepadAnalogDeadzone) {
      // Determine primary direction
      if (_leftStickX.abs() > _leftStickY.abs()) {
        newDirection = _leftStickX > 0 ? Direction.right : Direction.left;
      } else {
        newDirection = _leftStickY > 0 ? Direction.down : Direction.up;
      }
    }

    if (newDirection != _currentDirection) {
      _currentDirection = newDirection;
      if (newDirection != Direction.none) {
        onDirection?.call(newDirection);
      }
    }
  }

  GamepadButton? _mapKeyToButton(String key) {
    return switch (key.toLowerCase()) {
      'a' || 'button south' || 'cross' => GamepadButton.south,
      'b' || 'button east' || 'circle' => GamepadButton.east,
      'x' || 'button west' || 'square' => GamepadButton.west,
      'y' || 'button north' || 'triangle' => GamepadButton.north,
      'start' || 'options' || 'menu' => GamepadButton.start,
      'select' || 'back' || 'share' => GamepadButton.select,
      'left bumper' || 'lb' || 'l1' => GamepadButton.leftBumper,
      'right bumper' || 'rb' || 'r1' => GamepadButton.rightBumper,
      'left trigger' || 'lt' || 'l2' => GamepadButton.leftTrigger,
      'right trigger' || 'rt' || 'r2' => GamepadButton.rightTrigger,
      _ => null,
    };
  }

  Direction? _mapKeyToDirection(String key) {
    return switch (key.toLowerCase()) {
      'dpad up' || 'up' => Direction.up,
      'dpad down' || 'down' => Direction.down,
      'dpad left' || 'left' => Direction.left,
      'dpad right' || 'right' => Direction.right,
      _ => null,
    };
  }
}
