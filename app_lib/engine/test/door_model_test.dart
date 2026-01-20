import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('WallSide', () {
    test('opposite returns correct wall side', () {
      expect(WallSide.top.opposite, WallSide.bottom);
      expect(WallSide.bottom.opposite, WallSide.top);
      expect(WallSide.left.opposite, WallSide.right);
      expect(WallSide.right.opposite, WallSide.left);
    });
  });

  group('DoorModel', () {
    late DoorModel door;

    setUp(() {
      door = const DoorModel(
        id: 'door-1',
        targetRoomId: 'room-2',
        wallSide: WallSide.right,
        wallPosition: 5,
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(door.id, 'door-1');
        expect(door.targetRoomId, 'room-2');
        expect(door.wallSide, WallSide.right);
        expect(door.wallPosition, 5);
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = door.toJson();

        expect(json['id'], 'door-1');
        expect(json['targetRoomId'], 'room-2');
        expect(json['wallSide'], 'right');
        expect(json['wallPosition'], 5);
      });

      test('fromJson produces correct model', () {
        final json = door.toJson();
        final restored = DoorModel.fromJson(json);

        expect(restored.id, door.id);
        expect(restored.targetRoomId, door.targetRoomId);
        expect(restored.wallSide, door.wallSide);
        expect(restored.wallPosition, door.wallPosition);
      });

      test('round-trip serialization preserves all fields', () {
        const doors = [
          DoorModel(
            id: 'd1',
            targetRoomId: 'r1',
            wallSide: WallSide.top,
            wallPosition: 10,
          ),
          DoorModel(
            id: 'd2',
            targetRoomId: 'r2',
            wallSide: WallSide.bottom,
            wallPosition: 8,
          ),
          DoorModel(
            id: 'd3',
            targetRoomId: 'r3',
            wallSide: WallSide.left,
            wallPosition: 3,
          ),
          DoorModel(
            id: 'd4',
            targetRoomId: 'r4',
            wallSide: WallSide.right,
            wallPosition: 6,
          ),
        ];

        for (final original in doors) {
          final restored = DoorModel.fromJson(original.toJson());
          expect(restored, original);
        }
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final modified = door.copyWith(targetRoomId: 'room-3', wallPosition: 8);

        expect(modified.targetRoomId, 'room-3');
        expect(modified.wallPosition, 8);
        expect(modified.id, door.id);
        expect(modified.wallSide, door.wallSide);
      });

      test('preserves unmodified fields', () {
        final modified = door.copyWith(wallSide: WallSide.left);

        expect(modified.id, 'door-1');
        expect(modified.targetRoomId, 'room-2');
        expect(modified.wallSide, WallSide.left);
        expect(modified.wallPosition, 5);
      });
    });

    group('getPosition', () {
      const roomWidth = 20;
      const roomHeight = 12;

      test('returns correct position for top wall', () {
        const topDoor = DoorModel(
          id: 'door-top',
          targetRoomId: 'room-2',
          wallSide: WallSide.top,
          wallPosition: 10,
        );

        final pos = topDoor.getPosition(roomWidth, roomHeight);
        expect(pos.x, 10);
        expect(pos.y, 0);
      });

      test('returns correct position for bottom wall', () {
        const bottomDoor = DoorModel(
          id: 'door-bottom',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 8,
        );

        final pos = bottomDoor.getPosition(roomWidth, roomHeight);
        expect(pos.x, 8);
        expect(pos.y, 11); // roomHeight - 1
      });

      test('returns correct position for left wall', () {
        const leftDoor = DoorModel(
          id: 'door-left',
          targetRoomId: 'room-2',
          wallSide: WallSide.left,
          wallPosition: 5,
        );

        final pos = leftDoor.getPosition(roomWidth, roomHeight);
        expect(pos.x, 0);
        expect(pos.y, 5);
      });

      test('returns correct position for right wall', () {
        const rightDoor = DoorModel(
          id: 'door-right',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 6,
        );

        final pos = rightDoor.getPosition(roomWidth, roomHeight);
        expect(pos.x, 19); // roomWidth - 1
        expect(pos.y, 6);
      });
    });

    group('getSpawnPosition', () {
      const roomWidth = 20;
      const roomHeight = 12;

      test('returns position one step inward from top wall', () {
        const topDoor = DoorModel(
          id: 'door-top',
          targetRoomId: 'room-2',
          wallSide: WallSide.top,
          wallPosition: 10,
        );

        final spawn = topDoor.getSpawnPosition(roomWidth, roomHeight);
        expect(spawn.x, 10);
        expect(spawn.y, 1);
      });

      test('returns position one step inward from bottom wall', () {
        const bottomDoor = DoorModel(
          id: 'door-bottom',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 8,
        );

        final spawn = bottomDoor.getSpawnPosition(roomWidth, roomHeight);
        expect(spawn.x, 8);
        expect(spawn.y, 10); // roomHeight - 2
      });

      test('returns position one step inward from left wall', () {
        const leftDoor = DoorModel(
          id: 'door-left',
          targetRoomId: 'room-2',
          wallSide: WallSide.left,
          wallPosition: 5,
        );

        final spawn = leftDoor.getSpawnPosition(roomWidth, roomHeight);
        expect(spawn.x, 1);
        expect(spawn.y, 5);
      });

      test('returns position one step inward from right wall', () {
        const rightDoor = DoorModel(
          id: 'door-right',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 6,
        );

        final spawn = rightDoor.getSpawnPosition(roomWidth, roomHeight);
        expect(spawn.x, 18); // roomWidth - 2
        expect(spawn.y, 6);
      });
    });

    group('equality', () {
      test('equal doors are equal', () {
        const door1 = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        const door2 = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );

        expect(door1, door2);
      });

      test('different doors are not equal', () {
        const door1 = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        final door2 = door1.copyWith(wallPosition: 6);

        expect(door1, isNot(door2));
      });
    });

    group('edge cases', () {
      test('getPosition at wall position 0', () {
        const doorAtStart = DoorModel(
          id: 'door-0',
          targetRoomId: 'room-2',
          wallSide: WallSide.top,
          wallPosition: 0,
        );

        final pos = doorAtStart.getPosition(20, 12);
        expect(pos.x, 0);
        expect(pos.y, 0);
      });

      test('getPosition at maximum wall position', () {
        // For top/bottom walls, max position is roomWidth - 1
        const doorAtEnd = DoorModel(
          id: 'door-end',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 19, // roomWidth - 1
        );

        final pos = doorAtEnd.getPosition(20, 12);
        expect(pos.x, 19);
        expect(pos.y, 11);
      });

      test('getSpawnPosition at wall position 0', () {
        const doorAtStart = DoorModel(
          id: 'door-0',
          targetRoomId: 'room-2',
          wallSide: WallSide.left,
          wallPosition: 0,
        );

        final spawn = doorAtStart.getSpawnPosition(20, 12);
        expect(spawn.x, 1);
        expect(spawn.y, 0);
      });

      test('getPosition with small room dimensions', () {
        const door = DoorModel(
          id: 'door-small',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 2,
        );

        // Minimum viable room: 3x3
        final pos = door.getPosition(3, 3);
        expect(pos.x, 2);
        expect(pos.y, 2);
      });

      test('getSpawnPosition with small room dimensions', () {
        const door = DoorModel(
          id: 'door-small',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 1,
        );

        // 3x3 room
        final spawn = door.getSpawnPosition(3, 3);
        expect(spawn.x, 1); // roomWidth - 2 = 1
        expect(spawn.y, 1);
      });

      test('all WallSide values have opposite', () {
        for (final side in WallSide.values) {
          expect(side.opposite.opposite, side);
        }
      });

      test('WallSide name matches enum', () {
        expect(WallSide.top.name, 'top');
        expect(WallSide.bottom.name, 'bottom');
        expect(WallSide.left.name, 'left');
        expect(WallSide.right.name, 'right');
      });
    });
  });
}
