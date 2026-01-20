import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_character/game_objects_character.dart';

void main() {
  group('PlayerComponent', () {
    group('constructor', () {
      test('uses default values from GameConstants', () {
        final player = PlayerComponent();

        expect(player.tileSize, GameConstants.tileSize);
        expect(player.gridPosition, GameConstants.playerStartPosition);
        expect(player.moveSpeed, 150);
      });

      test('accepts custom initial position', () {
        const customPos = GridPosition(5, 5);
        final player = PlayerComponent(initialPosition: customPos);

        expect(player.gridPosition, customPos);
      });

      test('accepts custom tile size', () {
        final player = PlayerComponent(tileSize: 64.0);

        expect(player.tileSize, 64.0);
      });

      test('accepts custom move speed', () {
        final player = PlayerComponent(moveSpeed: 200);

        expect(player.moveSpeed, 200);
      });

      test('accepts all custom parameters', () {
        const customPos = GridPosition(3, 7);
        final player = PlayerComponent(
          initialPosition: customPos,
          tileSize: 48.0,
          moveSpeed: 175,
        );

        expect(player.gridPosition, customPos);
        expect(player.tileSize, 48.0);
        expect(player.moveSpeed, 175);
      });
    });

    group('position', () {
      test('initializes pixel position from grid position', () {
        const gridPos = GridPosition(5, 3);
        const tileSize = 32.0;
        final player = PlayerComponent(
          initialPosition: gridPos,
          tileSize: tileSize,
        );

        expect(player.position, Vector2(160.0, 96.0));
      });

      test('position at origin grid position', () {
        const gridPos = GridPosition(0, 0);
        final player = PlayerComponent(initialPosition: gridPos);

        expect(player.position, Vector2(0, 0));
      });

      test('uses default start position for pixel calculation', () {
        final player = PlayerComponent();

        final expectedX =
            GameConstants.playerStartPosition.x * GameConstants.tileSize;
        final expectedY =
            GameConstants.playerStartPosition.y * GameConstants.tileSize;

        expect(player.position, Vector2(expectedX, expectedY));
      });
    });

    group('size', () {
      test('is one tile size with default', () {
        final player = PlayerComponent();

        expect(player.size, Vector2.all(GameConstants.tileSize));
      });

      test('is one tile size with custom tile size', () {
        final player = PlayerComponent(tileSize: 48.0);

        expect(player.size, Vector2.all(48.0));
      });
    });

    group('gridPosition', () {
      test('returns the current grid position', () {
        const pos = GridPosition(7, 4);
        final player = PlayerComponent(initialPosition: pos);

        expect(player.gridPosition, pos);
      });

      test('grid position x and y are accessible', () {
        const pos = GridPosition(8, 2);
        final player = PlayerComponent(initialPosition: pos);

        expect(player.gridPosition.x, 8);
        expect(player.gridPosition.y, 2);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final player = PlayerComponent();

        expect(player, isA<PositionComponent>());
      });
    });

    group('moveSpeed', () {
      test('default moveSpeed is 150', () {
        final player = PlayerComponent();

        expect(player.moveSpeed, 150);
      });

      test('moveSpeed is immutable after construction', () {
        final player = PlayerComponent(moveSpeed: 100);

        expect(player.moveSpeed, 100);
      });

      test('different players can have different move speeds', () {
        final player1 = PlayerComponent(moveSpeed: 100);
        final player2 = PlayerComponent(moveSpeed: 200);

        expect(player1.moveSpeed, 100);
        expect(player2.moveSpeed, 200);
      });
    });

    group('tile size', () {
      test('tileSize affects initial position calculation', () {
        const gridPos = GridPosition(2, 3);

        final player32 = PlayerComponent(
          initialPosition: gridPos,
          tileSize: 32.0,
        );
        final player64 = PlayerComponent(
          initialPosition: gridPos,
          tileSize: 64.0,
        );

        expect(player32.position, Vector2(64.0, 96.0));
        expect(player64.position, Vector2(128.0, 192.0));
      });

      test('tileSize affects component size', () {
        final player32 = PlayerComponent(tileSize: 32.0);
        final player64 = PlayerComponent(tileSize: 64.0);

        expect(player32.size, Vector2.all(32.0));
        expect(player64.size, Vector2.all(64.0));
      });
    });
  });
}
