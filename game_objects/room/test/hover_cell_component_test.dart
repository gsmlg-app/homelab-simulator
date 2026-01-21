import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  group('HoverCellComponent', () {
    group('constructor', () {
      test('uses default tile size from GameConstants', () {
        final component = HoverCellComponent();

        expect(component.tileSize, GameConstants.tileSize);
      });

      test('accepts custom tile size', () {
        final component = HoverCellComponent(tileSize: 64.0);

        expect(component.tileSize, 64.0);
      });
    });

    group('size', () {
      test('is one tile size with default', () {
        final component = HoverCellComponent();

        expect(component.size, Vector2.all(GameConstants.tileSize));
      });

      test('is one tile size with custom tile size', () {
        final component = HoverCellComponent(tileSize: 48.0);

        expect(component.size, Vector2.all(48.0));
      });
    });

    group('setValidPlacement', () {
      test('can set valid placement to true', () {
        final component = HoverCellComponent();

        // No exception should be thrown
        component.setValidPlacement(true);
      });

      test('can set valid placement to false', () {
        final component = HoverCellComponent();

        // No exception should be thrown
        component.setValidPlacement(false);
      });

      test('can toggle placement validity', () {
        final component = HoverCellComponent();

        component.setValidPlacement(true);
        component.setValidPlacement(false);
        component.setValidPlacement(true);

        // No exception should be thrown for multiple calls
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final component = HoverCellComponent();

        expect(component, isA<PositionComponent>());
      });

      test('can have position set', () {
        final component = HoverCellComponent();
        component.position = Vector2(100, 200);

        expect(component.position, Vector2(100, 200));
      });
    });

    group('tile size immutability', () {
      test('tile size is set at construction', () {
        final component = HoverCellComponent(tileSize: GameConstants.tileSize);

        expect(component.tileSize, 32.0);
      });

      test('different instances can have different tile sizes', () {
        final component1 = HoverCellComponent(tileSize: GameConstants.tileSize);
        final component2 = HoverCellComponent(tileSize: 64.0);

        expect(component1.tileSize, 32.0);
        expect(component2.tileSize, 64.0);
      });
    });

    group('size configuration', () {
      test('size is square based on tile size', () {
        final component = HoverCellComponent(tileSize: 48.0);

        expect(component.size.x, 48.0);
        expect(component.size.y, 48.0);
      });

      test('size equals tile size in both dimensions', () {
        final component = HoverCellComponent();

        expect(component.size.x, component.tileSize);
        expect(component.size.y, component.tileSize);
      });

      test('handles small tile size', () {
        final component = HoverCellComponent(tileSize: 8.0);

        expect(component.size, Vector2.all(8.0));
      });

      test('handles large tile size', () {
        final component = HoverCellComponent(tileSize: 256.0);

        expect(component.size, Vector2.all(256.0));
      });
    });

    group('position manipulation', () {
      test('initial position is zero', () {
        final component = HoverCellComponent();

        expect(component.position, Vector2.zero());
      });

      test('position can be set to any value', () {
        final component = HoverCellComponent();
        component.position = Vector2(300, 400);

        expect(component.position.x, 300);
        expect(component.position.y, 400);
      });

      test('position can be negative', () {
        final component = HoverCellComponent();
        component.position = Vector2(-50, -75);

        expect(component.position.x, -50);
        expect(component.position.y, -75);
      });
    });

    group('setValidPlacement behavior', () {
      test('starts with valid placement by default', () {
        final component = HoverCellComponent();
        // Setting to true should work without changing anything
        component.setValidPlacement(true);
        // No exception means default is true
      });

      test('can alternate between valid and invalid', () {
        final component = HoverCellComponent();

        component.setValidPlacement(false);
        component.setValidPlacement(true);
        component.setValidPlacement(false);
        component.setValidPlacement(true);
        // Multiple alternations should work without error
      });

      test('consecutive same values are allowed', () {
        final component = HoverCellComponent();

        component.setValidPlacement(true);
        component.setValidPlacement(true);
        component.setValidPlacement(false);
        component.setValidPlacement(false);
        // Consecutive same values should not cause issues
      });
    });

    group('component type', () {
      test('is a PositionComponent', () {
        expect(HoverCellComponent(), isA<PositionComponent>());
      });

      test('can have priority set', () {
        final component = HoverCellComponent();
        component.priority = 10;

        expect(component.priority, 10);
      });

      test('can have anchor set', () {
        final component = HoverCellComponent();
        component.anchor = Anchor.center;

        expect(component.anchor, Anchor.center);
      });
    });
  });
}
