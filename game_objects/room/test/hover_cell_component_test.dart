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
        final component = HoverCellComponent(tileSize: 32.0);

        expect(component.tileSize, 32.0);
      });

      test('different instances can have different tile sizes', () {
        final component1 = HoverCellComponent(tileSize: 32.0);
        final component2 = HoverCellComponent(tileSize: 64.0);

        expect(component1.tileSize, 32.0);
        expect(component2.tileSize, 64.0);
      });
    });
  });
}
