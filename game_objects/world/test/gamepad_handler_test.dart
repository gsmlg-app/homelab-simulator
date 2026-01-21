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

  group('GamepadHandler callback patterns', () {
    test('supports direction callback chain', () {
      final directions = <Direction>[];
      final handler = GamepadHandler(onDirection: (dir) => directions.add(dir));

      // Simulate the callback being invoked multiple times
      handler.onDirection!(Direction.up);
      handler.onDirection!(Direction.down);
      handler.onDirection!(Direction.left);
      handler.onDirection!(Direction.right);

      expect(directions.length, 4);
      expect(directions, [
        Direction.up,
        Direction.down,
        Direction.left,
        Direction.right,
      ]);
    });

    test('supports button pressed callback chain', () {
      final buttons = <GamepadButton>[];
      final handler = GamepadHandler(
        onButtonPressed: (button) => buttons.add(button),
      );

      handler.onButtonPressed!(GamepadButton.south);
      handler.onButtonPressed!(GamepadButton.east);

      expect(buttons.length, 2);
      expect(buttons, [GamepadButton.south, GamepadButton.east]);
    });

    test('supports button released callback chain', () {
      final buttons = <GamepadButton>[];
      final handler = GamepadHandler(
        onButtonReleased: (button) => buttons.add(button),
      );

      handler.onButtonReleased!(GamepadButton.north);
      handler.onButtonReleased!(GamepadButton.west);

      expect(buttons.length, 2);
      expect(buttons, [GamepadButton.north, GamepadButton.west]);
    });
  });

  group('GamepadButton enum properties', () {
    test('south button index is 0', () {
      expect(GamepadButton.south.index, 0);
    });

    test('east button index is 1', () {
      expect(GamepadButton.east.index, 1);
    });

    test('start button index is 4', () {
      expect(GamepadButton.start.index, 4);
    });

    test('all buttons have unique indices', () {
      final indices = GamepadButton.values.map((b) => b.index).toSet();
      expect(indices.length, GamepadButton.values.length);
    });
  });

  group('Direction enum integration', () {
    test('Direction.none is distinct from directions', () {
      expect(Direction.none, isNot(Direction.up));
      expect(Direction.none, isNot(Direction.down));
      expect(Direction.none, isNot(Direction.left));
      expect(Direction.none, isNot(Direction.right));
    });

    test('all directions have unique values', () {
      final directions = Direction.values.toSet();
      expect(directions.length, Direction.values.length);
    });
  });

  group('GamepadHandler edge cases', () {
    test('can be created multiple times independently', () {
      final handler1 = GamepadHandler();
      final handler2 = GamepadHandler();

      expect(handler1, isNot(same(handler2)));
    });

    test('different handlers can have different callbacks', () {
      var count1 = 0;
      var count2 = 0;

      final handler1 = GamepadHandler(onDirection: (_) => count1++);
      final handler2 = GamepadHandler(onDirection: (_) => count2++);

      handler1.onDirection!(Direction.up);
      handler2.onDirection!(Direction.down);
      handler2.onDirection!(Direction.left);

      expect(count1, 1);
      expect(count2, 2);
    });

    test('handler without callbacks can be created', () {
      final handler = GamepadHandler();

      expect(handler.onDirection, isNull);
      expect(handler.onButtonPressed, isNull);
      expect(handler.onButtonReleased, isNull);
    });
  });
}
