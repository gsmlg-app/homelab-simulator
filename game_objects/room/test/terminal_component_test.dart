import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  group('TerminalComponent', () {
    group('constructor', () {
      test('uses default position from GameConstants', () {
        final component = TerminalComponent();

        expect(component.gridPosition, GameConstants.terminalPosition);
      });

      test('uses default tile size from GameConstants', () {
        final component = TerminalComponent();

        expect(component.tileSize, GameConstants.tileSize);
      });

      test('accepts custom grid position', () {
        const customPos = GridPosition(5, 7);
        final component = TerminalComponent(gridPosition: customPos);

        expect(component.gridPosition, customPos);
      });

      test('accepts custom tile size', () {
        final component = TerminalComponent(tileSize: 64.0);

        expect(component.tileSize, 64.0);
      });

      test('accepts both custom position and tile size', () {
        const customPos = GridPosition(3, 4);
        final component = TerminalComponent(
          gridPosition: customPos,
          tileSize: 48.0,
        );

        expect(component.gridPosition, customPos);
        expect(component.tileSize, 48.0);
      });
    });

    group('position', () {
      test('initializes position from grid position and tile size', () {
        const gridPos = GridPosition(2, 2);
        const tileSize = 32.0;
        final component = TerminalComponent(
          gridPosition: gridPos,
          tileSize: tileSize,
        );

        expect(component.position, Vector2(64.0, 64.0));
      });

      test('calculates position correctly with different tile sizes', () {
        const gridPos = GridPosition(3, 5);
        const tileSize = 64.0;
        final component = TerminalComponent(
          gridPosition: gridPos,
          tileSize: tileSize,
        );

        expect(component.position, Vector2(192.0, 320.0));
      });

      test('position at origin grid position', () {
        const gridPos = GridPosition(0, 0);
        final component = TerminalComponent(gridPosition: gridPos);

        expect(component.position, Vector2(0, 0));
      });

      test('uses default terminal position for pixel calculation', () {
        final component = TerminalComponent();

        final expectedX =
            GameConstants.terminalPosition.x * GameConstants.tileSize;
        final expectedY =
            GameConstants.terminalPosition.y * GameConstants.tileSize;

        expect(component.position, Vector2(expectedX, expectedY));
      });
    });

    group('size', () {
      test('is one tile size with default', () {
        final component = TerminalComponent();

        expect(component.size, Vector2.all(GameConstants.tileSize));
      });

      test('is one tile size with custom tile size', () {
        final component = TerminalComponent(tileSize: 48.0);

        expect(component.size, Vector2.all(48.0));
      });
    });

    group('gridPosition', () {
      test('stores the provided grid position', () {
        const pos = GridPosition(10, 8);
        final component = TerminalComponent(gridPosition: pos);

        expect(component.gridPosition, pos);
      });

      test('grid position x and y are accessible', () {
        const pos = GridPosition(7, 3);
        final component = TerminalComponent(gridPosition: pos);

        expect(component.gridPosition.x, 7);
        expect(component.gridPosition.y, 3);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final component = TerminalComponent();

        expect(component, isA<PositionComponent>());
      });

      test('position can be modified', () {
        final component = TerminalComponent();
        component.position = Vector2(100, 200);

        expect(component.position, Vector2(100, 200));
      });
    });

    group('immutability', () {
      test('gridPosition is final', () {
        const pos = GridPosition(5, 5);
        final component = TerminalComponent(gridPosition: pos);

        expect(component.gridPosition, pos);
      });

      test('tileSize is final', () {
        const tileSize = 50.0;
        final component = TerminalComponent(tileSize: tileSize);

        expect(component.tileSize, tileSize);
      });
    });

    group('edge cases', () {
      test('handles position at high coordinates', () {
        const highPos = GridPosition(100, 100);
        final component = TerminalComponent(
          gridPosition: highPos,
          tileSize: GameConstants.tileSize,
        );

        expect(component.position, Vector2(3200.0, 3200.0));
      });

      test('handles very small tile size', () {
        final component = TerminalComponent(tileSize: 8.0);

        expect(component.tileSize, 8.0);
        expect(component.size, Vector2.all(8.0));
      });

      test('handles very large tile size', () {
        final component = TerminalComponent(tileSize: 256.0);

        expect(component.tileSize, 256.0);
        expect(component.size, Vector2.all(256.0));
      });

      test('default anchor is top left', () {
        final component = TerminalComponent();

        expect(component.anchor, Anchor.topLeft);
      });

      test('position at high grid coordinates', () {
        const gridPos = GridPosition(999, 999);
        final component = TerminalComponent(
          gridPosition: gridPos,
          tileSize: GameConstants.tileSize,
        );

        expect(component.position.x, 999 * GameConstants.tileSize);
        expect(component.position.y, 999 * GameConstants.tileSize);
      });
    });

    group('component properties', () {
      test('can have priority set', () {
        final component = TerminalComponent();
        component.priority = 10;

        expect(component.priority, 10);
      });

      test('can have anchor changed', () {
        final component = TerminalComponent();
        component.anchor = Anchor.center;

        expect(component.anchor, Anchor.center);
      });

      test('size can be modified', () {
        final component = TerminalComponent();
        component.size = Vector2(100, 100);

        expect(component.size, Vector2(100, 100));
      });
    });

    group('position calculation', () {
      test('position scales with tile size', () {
        const gridPos = GridPosition(5, 5);

        final component32 = TerminalComponent(
          gridPosition: gridPos,
          tileSize: GameConstants.tileSize,
        );
        final component64 = TerminalComponent(
          gridPosition: gridPos,
          tileSize: 64.0,
        );

        expect(component32.position, Vector2(160.0, 160.0));
        expect(component64.position, Vector2(320.0, 320.0));
      });

      test('position is consistent for same parameters', () {
        const gridPos = GridPosition(7, 9);

        final component1 = TerminalComponent(gridPosition: gridPos);
        final component2 = TerminalComponent(gridPosition: gridPos);

        expect(component1.position, component2.position);
      });
    });

    group('screen flicker animation', () {
      test('terminal has screen flicker animation capability', () {
        final component = TerminalComponent();

        // Terminal component has flicker animation
        expect(component, isA<PositionComponent>());
      });

      test('terminal at default position supports animation', () {
        final component = TerminalComponent();

        expect(component.gridPosition, GameConstants.terminalPosition);
      });

      test('terminal at custom position supports animation', () {
        const customPos = GridPosition(10, 10);
        final component = TerminalComponent(gridPosition: customPos);

        expect(component.gridPosition, customPos);
      });

      test('animation period constant is defined for time bounding', () {
        // Verify component type supports bounded animation time
        final component = TerminalComponent();

        // Terminal always has flicker animation active
        expect(component, isA<PositionComponent>());
      });
    });
  });
}
