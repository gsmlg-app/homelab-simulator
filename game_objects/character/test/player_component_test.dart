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
      test('default moveSpeed is playerMoveSpeed', () {
        final player = PlayerComponent();

        expect(player.moveSpeed, GameConstants.playerMoveSpeed);
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
          tileSize: GameConstants.tileSize,
        );
        final player64 = PlayerComponent(
          initialPosition: gridPos,
          tileSize: 64.0,
        );

        expect(player32.position, Vector2(64.0, 96.0));
        expect(player64.position, Vector2(128.0, 192.0));
      });

      test('tileSize affects component size', () {
        final player32 = PlayerComponent(tileSize: GameConstants.tileSize);
        final player64 = PlayerComponent(tileSize: 64.0);

        expect(player32.size, Vector2.all(32.0));
        expect(player64.size, Vector2.all(64.0));
      });
    });

    group('edge cases', () {
      test('handles high position values', () {
        const farPos = GridPosition(100, 100);
        final player = PlayerComponent(initialPosition: farPos, tileSize: GameConstants.tileSize);

        expect(player.position, Vector2(3200.0, 3200.0));
        expect(player.gridPosition, farPos);
      });

      test('handles zero move speed', () {
        final player = PlayerComponent(moveSpeed: 0);

        expect(player.moveSpeed, 0);
      });

      test('handles very large tile size', () {
        final player = PlayerComponent(tileSize: 256.0);

        expect(player.tileSize, 256.0);
        expect(player.size, Vector2.all(256.0));
      });

      test('handles very small tile size', () {
        final player = PlayerComponent(tileSize: 8.0);

        expect(player.tileSize, 8.0);
        expect(player.size, Vector2.all(8.0));
      });

      test('position at high grid coordinates', () {
        const gridPos = GridPosition(999, 999);
        final player = PlayerComponent(
          initialPosition: gridPos,
          tileSize: GameConstants.tileSize,
        );

        expect(player.position.x, 999 * 32.0);
        expect(player.position.y, 999 * 32.0);
      });
    });

    group('component properties', () {
      test('default anchor is top left', () {
        final player = PlayerComponent();

        expect(player.anchor, Anchor.topLeft);
      });

      test('can have priority set', () {
        final player = PlayerComponent();
        player.priority = 10;

        expect(player.priority, 10);
      });

      test('can have anchor changed', () {
        final player = PlayerComponent();
        player.anchor = Anchor.center;

        expect(player.anchor, Anchor.center);
      });
    });

    group('position manipulation', () {
      test('position can be modified', () {
        final player = PlayerComponent();
        player.position = Vector2(500, 600);

        expect(player.position, Vector2(500, 600));
      });

      test('size can be modified', () {
        final player = PlayerComponent();
        player.size = Vector2(100, 100);

        expect(player.size, Vector2(100, 100));
      });

      test('initial position uses grid coordinates', () {
        const gridPos = GridPosition(10, 20);
        final player = PlayerComponent(
          initialPosition: gridPos,
          tileSize: 16.0,
        );

        expect(player.position.x, 160.0); // 10 * 16
        expect(player.position.y, 320.0); // 20 * 16
      });
    });
  });
}
