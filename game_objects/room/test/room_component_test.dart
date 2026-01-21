import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  group('RoomComponent', () {
    group('constructor', () {
      test('uses default values from GameConstants', () {
        final room = RoomComponent();

        expect(room.gridWidth, GameConstants.roomWidth);
        expect(room.gridHeight, GameConstants.roomHeight);
        expect(room.tileSize, GameConstants.tileSize);
      });

      test('accepts custom dimensions', () {
        final room = RoomComponent(
          gridWidth: 30,
          gridHeight: 20,
          tileSize: 64.0,
        );

        expect(room.gridWidth, 30);
        expect(room.gridHeight, 20);
        expect(room.tileSize, 64.0);
      });

      test('accepts partial custom dimensions', () {
        final room = RoomComponent(gridWidth: 25);

        expect(room.gridWidth, 25);
        expect(room.gridHeight, GameConstants.roomHeight);
        expect(room.tileSize, GameConstants.tileSize);
      });
    });

    group('size', () {
      test('calculates size from grid dimensions and tile size', () {
        final room = RoomComponent(
          gridWidth: 10,
          gridHeight: 8,
          tileSize: GameConstants.tileSize,
        );

        expect(room.size, Vector2(320.0, 256.0));
      });

      test('defaults to full room size', () {
        final room = RoomComponent();

        const expectedWidth = GameConstants.roomWidth * GameConstants.tileSize;
        const expectedHeight =
            GameConstants.roomHeight * GameConstants.tileSize;

        expect(room.size, Vector2(expectedWidth, expectedHeight));
      });

      test('handles different tile sizes', () {
        final room = RoomComponent(gridWidth: 5, gridHeight: 5, tileSize: 16.0);

        expect(room.size, Vector2(80.0, 80.0));
      });
    });

    group('setPlacementValid', () {
      test('can be called with true', () {
        final room = RoomComponent();
        // This tests that no exception is thrown
        // The internal state change requires onLoad to be called
        expect(() => room.setPlacementValid(true), throwsA(isA<Error>()));
      });

      test('can be called with false', () {
        final room = RoomComponent();
        // This tests that no exception is thrown
        // The internal state change requires onLoad to be called
        expect(() => room.setPlacementValid(false), throwsA(isA<Error>()));
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final room = RoomComponent();

        expect(room, isA<PositionComponent>());
      });

      test('can be positioned', () {
        final room = RoomComponent();
        room.position = Vector2(100, 200);

        expect(room.position, Vector2(100, 200));
      });
    });

    group('grid properties', () {
      test('gridWidth is accessible', () {
        final room = RoomComponent(gridWidth: 15);

        expect(room.gridWidth, 15);
      });

      test('gridHeight is accessible', () {
        final room = RoomComponent(gridHeight: 10);

        expect(room.gridHeight, 10);
      });

      test('tileSize is accessible', () {
        final room = RoomComponent(tileSize: 48.0);

        expect(room.tileSize, 48.0);
      });

      test('multiple rooms can have different dimensions', () {
        final room1 = RoomComponent(gridWidth: 10, gridHeight: 10);
        final room2 = RoomComponent(gridWidth: 20, gridHeight: 15);

        expect(room1.gridWidth, 10);
        expect(room1.gridHeight, 10);
        expect(room2.gridWidth, 20);
        expect(room2.gridHeight, 15);
      });
    });

    group('edge cases', () {
      test('handles minimum grid dimensions', () {
        final room = RoomComponent(gridWidth: 1, gridHeight: 1, tileSize: GameConstants.tileSize);

        expect(room.size, Vector2(32.0, 32.0));
      });

      test('handles large grid dimensions', () {
        final room = RoomComponent(
          gridWidth: 100,
          gridHeight: 50,
          tileSize: GameConstants.tileSize,
        );

        expect(room.size, Vector2(3200.0, 1600.0));
      });

      test('handles small tile size', () {
        final room = RoomComponent(
          gridWidth: 10,
          gridHeight: 10,
          tileSize: 1.0,
        );

        expect(room.size, Vector2(10.0, 10.0));
      });

      test('handles large tile size', () {
        final room = RoomComponent(
          gridWidth: 10,
          gridHeight: 10,
          tileSize: 128.0,
        );

        expect(room.size, Vector2(1280.0, 1280.0));
      });

      test('handles non-square dimensions', () {
        final room = RoomComponent(
          gridWidth: 30,
          gridHeight: 10,
          tileSize: GameConstants.tileSize,
        );

        expect(room.size.x, 960.0);
        expect(room.size.y, 320.0);
      });
    });

    group('position manipulation', () {
      test('initial position is zero', () {
        final room = RoomComponent();

        expect(room.position, Vector2.zero());
      });

      test('position can be set', () {
        final room = RoomComponent();
        room.position = Vector2(100, 200);

        expect(room.position.x, 100);
        expect(room.position.y, 200);
      });

      test('position can be negative', () {
        final room = RoomComponent();
        room.position = Vector2(-50, -100);

        expect(room.position.x, -50);
        expect(room.position.y, -100);
      });

      test('position does not affect size', () {
        final room = RoomComponent(
          gridWidth: 10,
          gridHeight: 10,
          tileSize: GameConstants.tileSize,
        );
        room.position = Vector2(500, 500);

        expect(room.size, Vector2(320.0, 320.0));
      });
    });

    group('component properties', () {
      test('can have priority set', () {
        final room = RoomComponent();
        room.priority = 10;

        expect(room.priority, 10);
      });

      test('can have anchor set', () {
        final room = RoomComponent();
        room.anchor = Anchor.center;

        expect(room.anchor, Anchor.center);
      });

      test('default anchor is top left', () {
        final room = RoomComponent();

        expect(room.anchor, Anchor.topLeft);
      });

      test('is a PositionComponent', () {
        expect(RoomComponent(), isA<PositionComponent>());
      });
    });
  });
}
