import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_world/game_objects_world.dart';

void main() {
  group('GamepadHandler', () {
    group('constructor', () {
      test('creates with no callbacks', () {
        final handler = GamepadHandler();

        expect(handler.onDirection, isNull);
        expect(handler.onButtonPressed, isNull);
        expect(handler.onButtonReleased, isNull);
      });

      test('accepts onDirection callback', () {
        Direction? receivedDirection;
        final handler = GamepadHandler(
          onDirection: (dir) => receivedDirection = dir,
        );

        expect(handler.onDirection, isNotNull);
        expect(receivedDirection, isNull); // Not called yet
      });

      test('accepts onButtonPressed callback', () {
        GamepadButton? receivedButton;
        final handler = GamepadHandler(
          onButtonPressed: (button) => receivedButton = button,
        );

        expect(handler.onButtonPressed, isNotNull);
        expect(receivedButton, isNull); // Not called yet
      });

      test('accepts onButtonReleased callback', () {
        GamepadButton? receivedButton;
        final handler = GamepadHandler(
          onButtonReleased: (button) => receivedButton = button,
        );

        expect(handler.onButtonReleased, isNotNull);
        expect(receivedButton, isNull); // Not called yet
      });

      test('accepts all callbacks', () {
        final handler = GamepadHandler(
          onDirection: (dir) {},
          onButtonPressed: (button) {},
          onButtonReleased: (button) {},
        );

        expect(handler.onDirection, isNotNull);
        expect(handler.onButtonPressed, isNotNull);
        expect(handler.onButtonReleased, isNotNull);
      });
    });

    group('inheritance', () {
      test('extends Component', () {
        final handler = GamepadHandler();

        expect(handler, isA<Component>());
      });
    });
  });

  group('GamepadButton', () {
    test('has south button', () {
      expect(GamepadButton.south, isA<GamepadButton>());
    });

    test('has east button', () {
      expect(GamepadButton.east, isA<GamepadButton>());
    });

    test('has north button', () {
      expect(GamepadButton.north, isA<GamepadButton>());
    });

    test('has west button', () {
      expect(GamepadButton.west, isA<GamepadButton>());
    });

    test('has start button', () {
      expect(GamepadButton.start, isA<GamepadButton>());
    });

    test('has select button', () {
      expect(GamepadButton.select, isA<GamepadButton>());
    });

    test('has left bumper', () {
      expect(GamepadButton.leftBumper, isA<GamepadButton>());
    });

    test('has right bumper', () {
      expect(GamepadButton.rightBumper, isA<GamepadButton>());
    });

    test('has left trigger', () {
      expect(GamepadButton.leftTrigger, isA<GamepadButton>());
    });

    test('has right trigger', () {
      expect(GamepadButton.rightTrigger, isA<GamepadButton>());
    });

    test('has 10 button values', () {
      expect(GamepadButton.values.length, 10);
    });
  });

  group('GamepadDirectionCallback', () {
    test('can be called with Direction.up', () {
      Direction? receivedDirection;
      Direction callback(Direction dir) => receivedDirection = dir;

      callback(Direction.up);

      expect(receivedDirection, Direction.up);
    });

    test('can be called with Direction.down', () {
      Direction? receivedDirection;
      Direction callback(Direction dir) => receivedDirection = dir;

      callback(Direction.down);

      expect(receivedDirection, Direction.down);
    });

    test('can be called with Direction.left', () {
      Direction? receivedDirection;
      Direction callback(Direction dir) => receivedDirection = dir;

      callback(Direction.left);

      expect(receivedDirection, Direction.left);
    });

    test('can be called with Direction.right', () {
      Direction? receivedDirection;
      Direction callback(Direction dir) => receivedDirection = dir;

      callback(Direction.right);

      expect(receivedDirection, Direction.right);
    });

    test('can be called with Direction.none', () {
      Direction? receivedDirection;
      Direction callback(Direction dir) => receivedDirection = dir;

      callback(Direction.none);

      expect(receivedDirection, Direction.none);
    });
  });

  group('GamepadButtonCallback', () {
    test('can be called with any GamepadButton', () {
      GamepadButton? receivedButton;
      GamepadButton callback(GamepadButton btn) => receivedButton = btn;

      for (final button in GamepadButton.values) {
        callback(button);
        expect(receivedButton, button);
      }
    });
  });
}
