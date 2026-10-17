import 'dart:convert';
import 'dart:io';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'legacy installation is stable across JSON reloads without changing saved actor or objects',
    () {
      final original = GameModel.initial();
      final installed = installCloudCenter(original);
      expect(installed.currentRoomId, original.currentRoomId);
      expect(installed.playerPosition, original.playerPosition);
      expect(
        installed.rooms.where((room) => room.type == RoomType.cloudCenter),
        hasLength(1),
      );
      expect(
        installed.cloudCenterEntryStatus,
        CloudCenterEntryStatus.available,
      );
      for (var repeat = 0; repeat < 5; repeat++) {
        expect(
          installCloudCenter(GameModel.fromJson(installed.toJson())),
          installed,
        );
      }
      expect(
        GameModel.fromJson(
          installed.copyWith(cloudPanelOpen: true).toJson(),
        ).cloudPanelOpen,
        isFalse,
      );
    },
  );

  test(
    'shipped maps keep their art, portals, player and stable cloud gateway through reloads',
    () {
      final catalog = MapCatalog.fromJson(
        jsonDecode(File('../../assets/maps/catalog.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final original = catalog.createGame();
      final installed = installCloudCenter(original);
      expect(
        installed.cloudCenterEntryStatus,
        CloudCenterEntryStatus.available,
      );
      final source = installed.currentRoom;
      expect(source.definition, same(original.currentRoom.definition));
      expect(source.doors, containsAll(original.currentRoom.doors));
      expect(installed.playerPosition, original.playerPosition);
      final entrance = source.doors.singleWhere(
        (door) => door.id == CloudCenterIds.entrance,
      );
      final staging = entrance.getSpawnPosition(source.width, source.height);
      expect(source.findPath(installed.playerPosition, staging), isNotEmpty);
      final entered = reduce(
        installed,
        RoomEntered(
          roomId: CloudCenterIds.room,
          spawnPosition: entrance.targetSpawnPosition!,
        ),
      );
      final center = entered.currentRoom;
      expect(center.cloudConsoles, hasLength(4));
      expect(
        center.cloudConsoles.map((console) => console.id).toSet(),
        hasLength(4),
      );
      for (final console in center.cloudConsoles) {
        expect(CloudConsoleModel.fromJson(console.toJson()), console);
        final interactionCells =
            [
              for (var y = 0; y < center.height; y++)
                for (var x = 0; x < center.width; x++) GridPosition(x, y),
            ].where(
              (cell) => console.distanceTo(cell) == 1 && center.canWalk(cell),
            );
        expect(interactionCells, isNotEmpty);
        for (final cell in interactionCells) {
          expect(
            cell == entered.playerPosition ||
                center.findPath(entered.playerPosition, cell).isNotEmpty,
            isTrue,
          );
        }
        for (var y = 0; y < console.height; y++) {
          for (var x = 0; x < console.width; x++) {
            final occupied = console.position + GridPosition(x, y);
            expect(center.canWalk(occupied), isFalse);
            expect(center.canPlaceDevice(occupied, 1, 1), isFalse);
          }
        }
      }
      final exit = center.doors.singleWhere(
        (door) => door.id == CloudCenterIds.exit,
      );
      final returned = reduce(
        entered,
        RoomEntered(
          roomId: exit.targetRoomId,
          spawnPosition: exit.targetSpawnPosition!,
        ),
      );
      expect(returned.currentRoomId, original.currentRoomId);
      expect(returned.currentRoom.canWalk(returned.playerPosition), isTrue);
      expect(
        installCloudCenter(
          catalog.resolveGame(GameModel.fromJson(installed.toJson())),
        ),
        installed,
      );
    },
  );

  test(
    'crowded saved layouts expose unavailable entrance and preserve every occupied cell',
    () {
      final devices = [
        for (var y = 0; y < 3; y++)
          for (var x = 0; x < 3; x++)
            if (x != 1 || y != 1)
              DeviceModel(
                id: '$x:$y',
                templateId: 'server_basic',
                name: 'Saved',
                type: DeviceType.server,
                position: GridPosition(x, y),
              ),
      ];
      final room = RoomModel(
        id: 'crowded',
        name: 'Crowded',
        width: 3,
        height: 3,
        devices: devices,
      );
      final original = GameModel(
        currentRoomId: room.id,
        rooms: [room],
        playerPosition: const GridPosition(1, 1),
      );
      final installed = installCloudCenter(original);
      expect(
        installed.cloudCenterEntryStatus,
        CloudCenterEntryStatus.noReachableEntrance,
      );
      expect(installed.currentRoom, room);
      expect(installed.playerPosition, original.playerPosition);
      expect(installCloudCenter(installed), installed);
    },
  );

  test(
    'reserved room ID collision is explicit and never overwrites user content',
    () {
      const original = GameModel(
        currentRoomId: CloudCenterIds.room,
        rooms: [RoomModel(id: CloudCenterIds.room, name: 'Saved user room')],
      );
      final result = installCloudCenter(original);
      expect(
        result.cloudCenterEntryStatus,
        CloudCenterEntryStatus.roomIdConflict,
      );
      expect(result.rooms, original.rooms);
    },
  );

  test(
    'one interaction ranking uses distance then stable ID for every target type',
    () {
      const console = CloudConsoleModel(
        id: 'a-console',
        roomId: 'room',
        position: GridPosition(3, 2),
        target: ProviderConsoleTarget(CloudProvider.aws),
      );
      const door = DoorModel(
        id: 'z-door',
        targetRoomId: 'other',
        wallSide: WallSide.left,
        wallPosition: 2,
        gridPosition: GridPosition(2, 1),
      );
      const room = RoomModel(
        id: 'room',
        name: 'Room',
        terminalPosition: GridPosition(2, 3),
        cloudConsoles: [console],
        doors: [door],
      );
      expect(
        selectInteractionTarget(room, const GridPosition(2, 2))!.id,
        console.id,
      );
      expect(
        selectInteractionTarget(room, const GridPosition(2, 1))!.id,
        door.id,
      );
      expect(selectInteractionTarget(room, const GridPosition(10, 8)), isNull);
    },
  );

  test(
    'old wall door JSON and new explicit gateway coordinates both round trip',
    () {
      const old = DoorModel(
        id: 'old',
        targetRoomId: 'other',
        wallSide: WallSide.right,
        wallPosition: 4,
      );
      final restored = DoorModel.fromJson(old.toJson());
      expect(restored, old);
      expect(restored.getPosition(20, 12), const GridPosition(19, 4));
      const gateway = DoorModel(
        id: 'new',
        targetRoomId: 'cloud-center',
        wallSide: WallSide.left,
        wallPosition: 3,
        gridPosition: GridPosition(4, 3),
        targetSpawnPosition: GridPosition(1, 6),
      );
      expect(DoorModel.fromJson(gateway.toJson()), gateway);
      expect(gateway.getPosition(20, 12), const GridPosition(4, 3));
      expect(gateway.getSpawnPosition(20, 12), const GridPosition(4, 3));
    },
  );
}
