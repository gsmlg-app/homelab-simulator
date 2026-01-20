import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  group('DoorComponent', () {
    late DoorModel testDoorTop;
    late DoorModel testDoorBottom;
    late DoorModel testDoorLeft;
    late DoorModel testDoorRight;

    setUp(() {
      testDoorTop = const DoorModel(
        id: 'door-top',
        targetRoomId: 'room-2',
        wallSide: WallSide.top,
        wallPosition: 10,
      );
      testDoorBottom = const DoorModel(
        id: 'door-bottom',
        targetRoomId: 'room-3',
        wallSide: WallSide.bottom,
        wallPosition: 5,
      );
      testDoorLeft = const DoorModel(
        id: 'door-left',
        targetRoomId: 'room-4',
        wallSide: WallSide.left,
        wallPosition: 6,
      );
      testDoorRight = const DoorModel(
        id: 'door-right',
        targetRoomId: 'room-5',
        wallSide: WallSide.right,
        wallPosition: 3,
      );
    });

    group('constructor', () {
      test('stores door model', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.door, testDoorTop);
      });

      test('uses default values from GameConstants', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.roomWidth, GameConstants.roomWidth);
        expect(component.roomHeight, GameConstants.roomHeight);
        expect(component.tileSize, GameConstants.tileSize);
      });

      test('accepts custom dimensions', () {
        final component = DoorComponent(
          door: testDoorTop,
          roomWidth: 30,
          roomHeight: 20,
          tileSize: 64.0,
        );

        expect(component.roomWidth, 30);
        expect(component.roomHeight, 20);
        expect(component.tileSize, 64.0);
      });
    });

    group('size', () {
      test('is one tile size', () {
        final component = DoorComponent(door: testDoorTop, tileSize: 32.0);

        expect(component.size, Vector2.all(32.0));
      });

      test('respects custom tile size', () {
        final component = DoorComponent(door: testDoorTop, tileSize: 64.0);

        expect(component.size, Vector2.all(64.0));
      });
    });

    group('gridPosition', () {
      test('returns correct position for top wall door', () {
        final component = DoorComponent(
          door: testDoorTop,
          roomWidth: 20,
          roomHeight: 12,
        );

        expect(component.gridPosition, const GridPosition(10, 0));
      });

      test('returns correct position for bottom wall door', () {
        final component = DoorComponent(
          door: testDoorBottom,
          roomWidth: 20,
          roomHeight: 12,
        );

        // wallPosition 5, roomHeight 12 -> y = 11
        expect(component.gridPosition, const GridPosition(5, 11));
      });

      test('returns correct position for left wall door', () {
        final component = DoorComponent(
          door: testDoorLeft,
          roomWidth: 20,
          roomHeight: 12,
        );

        expect(component.gridPosition, const GridPosition(0, 6));
      });

      test('returns correct position for right wall door', () {
        final component = DoorComponent(
          door: testDoorRight,
          roomWidth: 20,
          roomHeight: 12,
        );

        // wallPosition 3, roomWidth 20 -> x = 19
        expect(component.gridPosition, const GridPosition(19, 3));
      });

      test('uses custom room dimensions for position calculation', () {
        final component = DoorComponent(
          door: testDoorBottom,
          roomWidth: 30,
          roomHeight: 15,
        );

        // wallPosition 5, roomHeight 15 -> y = 14
        expect(component.gridPosition, const GridPosition(5, 14));
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component, isA<PositionComponent>());
      });

      test('can have position set', () {
        final component = DoorComponent(door: testDoorTop);
        component.position = Vector2(100, 200);

        expect(component.position, Vector2(100, 200));
      });
    });

    group('door model properties', () {
      test('door id is accessible', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.door.id, 'door-top');
      });

      test('door targetRoomId is accessible', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.door.targetRoomId, 'room-2');
      });

      test('door wallSide is accessible', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.door.wallSide, WallSide.top);
      });

      test('door wallPosition is accessible', () {
        final component = DoorComponent(door: testDoorTop);

        expect(component.door.wallPosition, 10);
      });
    });

    group('wall positions', () {
      test('all four wall sides are supported', () {
        final topComponent = DoorComponent(door: testDoorTop);
        final bottomComponent = DoorComponent(door: testDoorBottom);
        final leftComponent = DoorComponent(door: testDoorLeft);
        final rightComponent = DoorComponent(door: testDoorRight);

        expect(topComponent.door.wallSide, WallSide.top);
        expect(bottomComponent.door.wallSide, WallSide.bottom);
        expect(leftComponent.door.wallSide, WallSide.left);
        expect(rightComponent.door.wallSide, WallSide.right);
      });
    });
  });
}
