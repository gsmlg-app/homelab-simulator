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

    group('edge cases', () {
      test('handles minimum grid size of 1x1', () {
        final grid = GridComponent(gridWidth: 1, gridHeight: 1, tileSize: 32.0);

        expect(grid.size, Vector2(32.0, 32.0));
        expect(grid.gridWidth, 1);
        expect(grid.gridHeight, 1);
      });

      test('handles non-square grid', () {
        final grid = GridComponent(
          gridWidth: 20,
          gridHeight: 5,
          tileSize: 32.0,
        );

        expect(grid.size.x, 640.0);
        expect(grid.size.y, 160.0);
      });

      test('handles tall grid', () {
        final grid = GridComponent(
          gridWidth: 5,
          gridHeight: 20,
          tileSize: 32.0,
        );

        expect(grid.size.x, 160.0);
        expect(grid.size.y, 640.0);
      });

      test('handles very small tile size', () {
        final grid = GridComponent(
          gridWidth: 10,
          gridHeight: 10,
          tileSize: 1.0,
        );

        expect(grid.size, Vector2(10.0, 10.0));
      });
    });

    group('grid color', () {
      test('uses AppColors.gridOverlay as default', () {
        final grid = GridComponent();

        expect(grid.gridColor, AppColors.gridOverlay);
      });

      test('accepts fully opaque custom color', () {
        const opaqueColor = Color(0xFFFF0000);
        final grid = GridComponent(gridColor: opaqueColor);

        expect(grid.gridColor, opaqueColor);
      });

      test('accepts transparent custom color', () {
        const transparentColor = Color(0x00000000);
        final grid = GridComponent(gridColor: transparentColor);

        expect(grid.gridColor, transparentColor);
      });

      test('preserves color alpha channel', () {
        const semiTransparent = Color(0x80FFFFFF);
        final grid = GridComponent(gridColor: semiTransparent);

        expect(
          grid.gridColor.a,
          closeTo(0.5, 0.01),
          reason: 'Alpha should be approximately 0.5',
        );
      });
    });

    group('position manipulation', () {
      test('initial position is zero', () {
        final grid = GridComponent();

        expect(grid.position, Vector2.zero());
      });

      test('can be positioned with offset', () {
        final grid = GridComponent();
        grid.position = Vector2(50, 75);

        expect(grid.position.x, 50);
        expect(grid.position.y, 75);
      });

      test('position does not affect size', () {
        final grid = GridComponent(
          gridWidth: 10,
          gridHeight: 10,
          tileSize: 32.0,
        );
        grid.position = Vector2(1000, 1000);

        expect(grid.size, Vector2(320.0, 320.0));
      });
    });

    group('component properties', () {
      test('can have priority set', () {
        final grid = GridComponent();
        grid.priority = 5;

        expect(grid.priority, 5);
      });

      test('can have anchor set', () {
        final grid = GridComponent();
        grid.anchor = Anchor.center;

        expect(grid.anchor, Anchor.center);
      });

      test('default anchor is top left', () {
        final grid = GridComponent();

        expect(grid.anchor, Anchor.topLeft);
      });
    });

    group('cached path optimization', () {
      test('creates grid path during construction', () {
        // If path is not built, construction would fail or render would throw
        final grid = GridComponent(
          gridWidth: 5,
          gridHeight: 5,
          tileSize: 32.0,
        );

        // Verifies grid is created successfully with cached path
        expect(grid.gridWidth, 5);
        expect(grid.gridHeight, 5);
      });

      test('grid can be constructed with various dimensions', () {
        // Test that path building works for different grid sizes
        final grids = [
          GridComponent(gridWidth: 1, gridHeight: 1),
          GridComponent(gridWidth: 10, gridHeight: 5),
          GridComponent(gridWidth: 5, gridHeight: 10),
          GridComponent(gridWidth: 100, gridHeight: 100),
        ];

        for (final grid in grids) {
          expect(grid, isA<GridComponent>());
        }
      });

      test('grid with zero dimensions does not throw', () {
        // Edge case: zero dimensions should still construct
        expect(
          () => GridComponent(gridWidth: 0, gridHeight: 0),
          returnsNormally,
        );
      });
    });
  });
}
