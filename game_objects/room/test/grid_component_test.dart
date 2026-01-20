import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  group('GridComponent', () {
    group('constructor', () {
      test('uses default values from GameConstants', () {
        final grid = GridComponent();

        expect(grid.gridWidth, GameConstants.roomWidth);
        expect(grid.gridHeight, GameConstants.roomHeight);
        expect(grid.tileSize, GameConstants.tileSize);
      });

      test('accepts custom dimensions', () {
        final grid = GridComponent(
          gridWidth: 10,
          gridHeight: 8,
          tileSize: 64.0,
        );

        expect(grid.gridWidth, 10);
        expect(grid.gridHeight, 8);
        expect(grid.tileSize, 64.0);
      });

      test('accepts custom grid color', () {
        const customColor = Color(0xFF00FF00);
        final grid = GridComponent(gridColor: customColor);

        expect(grid.gridColor, customColor);
      });

      test('defaults grid color to semi-transparent white', () {
        final grid = GridComponent();

        expect(grid.gridColor, const Color(0x33FFFFFF));
      });
    });

    group('size', () {
      test('calculates size from grid dimensions and tile size', () {
        final grid = GridComponent(
          gridWidth: 10,
          gridHeight: 8,
          tileSize: 32.0,
        );

        expect(grid.size, Vector2(320.0, 256.0));
      });

      test('defaults to full room size', () {
        final grid = GridComponent();

        const expectedWidth = GameConstants.roomWidth * GameConstants.tileSize;
        const expectedHeight =
            GameConstants.roomHeight * GameConstants.tileSize;

        expect(grid.size, Vector2(expectedWidth, expectedHeight));
      });

      test('handles different tile sizes', () {
        final grid = GridComponent(gridWidth: 5, gridHeight: 5, tileSize: 16.0);

        expect(grid.size, Vector2(80.0, 80.0));
      });

      test('handles large grid sizes', () {
        final grid = GridComponent(
          gridWidth: 100,
          gridHeight: 50,
          tileSize: 64.0,
        );

        expect(grid.size, Vector2(6400.0, 3200.0));
      });
    });

    group('grid properties', () {
      test('gridWidth is immutable after construction', () {
        final grid = GridComponent(gridWidth: 15);

        expect(grid.gridWidth, 15);
      });

      test('gridHeight is immutable after construction', () {
        final grid = GridComponent(gridHeight: 10);

        expect(grid.gridHeight, 10);
      });

      test('tileSize is immutable after construction', () {
        final grid = GridComponent(tileSize: 48.0);

        expect(grid.tileSize, 48.0);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final grid = GridComponent();

        expect(grid, isA<PositionComponent>());
      });

      test('can be positioned', () {
        final grid = GridComponent();
        grid.position = Vector2(100, 200);

        expect(grid.position, Vector2(100, 200));
      });
    });
  });
}
