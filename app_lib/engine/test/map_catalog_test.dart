import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> catalogJson() {
  Map<String, dynamic> map(String id, int width, int height) => {
    'id': id,
    'name': id,
    'width': width,
    'height': height,
    'spawns': {
      'entry': [1, 1],
    },
    'terminalPosition': [0, 0],
    'layers': [
      {
        'id': 'floor',
        'foreground': false,
        'cells': List.generate(
          height,
          (_) => List<String?>.filled(width, 'floor'),
        ),
      },
    ],
    'objects': [
      {
        'id': 'rack-a',
        'prefabId': 'rack',
        'position': [2, 2],
        'bindingSlot': 'infra.primary',
      },
    ],
    'portals': [
      {
        'id': 'exit',
        'targetMapId': id == 'lab' ? 'ops' : 'lab',
        'wallSide': 'right',
        'wallPosition': 1,
        'targetSpawnId': 'entry',
      },
    ],
  };
  return {
    'schemaVersion': 1,
    'atlasAsset': 'assets/maps/atlas.png',
    'initialMapId': 'lab',
    'tiles': [
      {
        'id': 'floor',
        'frame': [0, 0, 64, 64],
        'blocksMovement': false,
        'blocksPlacement': false,
      },
      {
        'id': 'wall',
        'frame': [64, 0, 64, 64],
        'blocksMovement': true,
        'blocksPlacement': true,
      },
      {
        'id': 'cable',
        'frame': [128, 0, 64, 64],
        'blocksMovement': false,
        'blocksPlacement': true,
      },
    ],
    'prefabs': [
      {
        'id': 'rack',
        'frame': [0, 64, 128, 192],
        'width': 2,
        'height': 1,
        'drawWidth': 64,
        'drawHeight': 96,
        'blocksMovement': true,
        'blocksPlacement': true,
      },
    ],
    'maps': [map('lab', 6, 5), map('ops', 25, 14)],
  };
}

Map<String, dynamic> firstMap(Map<String, dynamic> json) => json['maps'][0];
List<dynamic> cells(Map<String, dynamic> json) =>
    firstMap(json)['layers'][0]['cells'];

void main() {
  test('resolves two sizes, immutable data, stable IDs and named spawns', () {
    final json = catalogJson();
    final catalog = MapCatalog.fromJson(json);
    final game = catalog.createGame();
    expect(game.currentRoomId, 'lab');
    expect(game.playerPosition, const GridPosition(1, 1));
    expect(game.rooms.map((r) => r.width), [6, 25]);
    expect(game.currentRoom.definition!.tileSize, 32);
    expect(game.currentRoom.doors.single.targetSpawnId, 'entry');
    expect(
      catalog.createGame().currentRoom.doors.single.id,
      game.currentRoom.doors.single.id,
    );
    cells(json)[0][0] = 'wall';
    expect(catalog.maps['lab']!.layers.single.cells[0][0], 'floor');
    expect(() => catalog.maps.clear(), throwsUnsupportedError);
    expect(
      () => catalog.maps['lab']!.layers.single.cells[0].clear(),
      throwsUnsupportedError,
    );
    expect(() => catalog.maps['lab']!.spawns.clear(), throwsUnsupportedError);
  });

  final invalidCases = <String, void Function(Map<String, dynamic>)>{
    'schemaVersion': (j) => j['schemaVersion'] = 2,
    'duplicate': (j) => j['tiles'].add(j['tiles'][0]),
    'initialMapId': (j) => j['initialMapId'] = 'missing',
    'frame': (j) => j['tiles'][0]['frame'][2] = 0,
    'cells': (j) => cells(j)[0] = ['floor'],
    'tile': (j) => cells(j)[0][0] = 'missing',
    'prefab': (j) => firstMap(j)['objects'][0]['prefabId'] = 'missing',
    'footprint': (j) => firstMap(j)['objects'][0]['position'] = [5, 2],
    'spawn': (j) => firstMap(j)['spawns']['entry'] = [2, 2],
    'spawn bounds': (j) => firstMap(j)['spawns']['entry'] = [-1, 0],
    'targetMapId': (j) => firstMap(j)['portals'][0]['targetMapId'] = 'missing',
    'targetSpawnId': (j) =>
        firstMap(j)['portals'][0]['targetSpawnId'] = 'missing',
    'wallPosition': (j) => firstMap(j)['portals'][0]['wallPosition'] = 5,
    'portal interaction': (j) {
      for (var y = 0; y < 5; y++) {
        cells(j)[y][3] = 'wall';
      }
    },
    'atlasAsset': (j) => j['atlasAsset'] = 'https://example.com/atlas.png',
  };
  for (final entry in invalidCases.entries) {
    test('rejects ${entry.key} with an actionable FormatException', () {
      final json = catalogJson();
      entry.value(json);
      expect(
        () => MapCatalog.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
      );
    });
  }

  test(
    'room bounds, static footprints, terrain and dynamic occupancy agree',
    () {
      final json = catalogJson();
      cells(json)[3][1] = 'cable';
      cells(json)[3][0] = 'wall';
      final game = MapCatalog.fromJson(json).createGame();
      final room = game.currentRoom;
      expect(room.containsCell(const GridPosition(6, 1)), isFalse);
      expect(game.rooms.last.canWalk(const GridPosition(24, 13)), isTrue);
      expect(room.canWalk(const GridPosition(3, 2)), isFalse);
      expect(room.canWalk(const GridPosition(0, 3)), isFalse);
      expect(room.canWalk(const GridPosition(1, 3)), isTrue);
      expect(room.canPlaceDevice(const GridPosition(1, 3), 1, 1), isFalse);
      expect(room.canPlaceDevice(const GridPosition(1, 2), 2, 1), isFalse);
      expect(room.canPlaceDevice(const GridPosition(5, 4), 2, 1), isFalse);
      expect(room.canPlaceDevice(const GridPosition(1, 1), 0, 1), isFalse);
      final occupied = room.addDevice(
        const DeviceModel(
          id: 'device',
          templateId: 'server_basic',
          name: 'Device',
          type: DeviceType.server,
          position: GridPosition(4, 3),
          width: 2,
        ),
      );
      expect(occupied.canWalk(const GridPosition(5, 3)), isFalse);
      expect(occupied.canPlaceDevice(const GridPosition(5, 3), 1, 1), isFalse);
    },
  );

  test(
    'four-neighbor paths detour, exclude start and reject unreachable goals',
    () {
      final room = MapCatalog.fromJson(catalogJson()).createGame().currentRoom;
      const start = GridPosition(2, 1);
      const target = GridPosition(2, 3);
      final path = room.findPath(start, target);
      expect(path.last, target);
      expect(path, isNot(contains(start)));
      var previous = start;
      for (final cell in path) {
        expect((cell.x - previous.x).abs() + (cell.y - previous.y).abs(), 1);
        expect(room.canWalk(cell), isTrue);
        previous = cell;
      }
      expect(path.length, greaterThan(2));
      expect(room.findPath(start, const GridPosition(2, 2)), isEmpty);
      final json = catalogJson();
      for (var y = 0; y < 5; y++) {
        cells(json)[y][3] = 'wall';
      }
      firstMap(json)['portals'] = [];
      final divided = MapCatalog.fromJson(json).createGame().currentRoom;
      expect(divided.findPath(start, const GridPosition(4, 3)), isEmpty);
    },
  );

  test(
    'reducer rejects blocked and out-of-room movement and invalid transitions',
    () {
      final game = MapCatalog.fromJson(catalogJson()).createGame();
      expect(reduce(game, const PlayerMoved(GridPosition(2, 2))), game);
      expect(reduce(game, const PlayerMoved(GridPosition(6, 1))), game);
      expect(
        reduce(
          game,
          const RoomEntered(
            roomId: 'missing',
            spawnPosition: GridPosition(1, 1),
          ),
        ),
        game,
      );
      expect(
        reduce(
          game,
          const RoomEntered(roomId: 'ops', spawnPosition: GridPosition(2, 2)),
        ),
        game,
      );
      expect(
        reduce(game, const PlayerMoved(GridPosition(2, 1))).playerPosition,
        const GridPosition(2, 1),
      );
    },
  );

  test(
    'JSON persistence reattaches definitions without replacing IDs or devices',
    () {
      final catalog = MapCatalog.fromJson(catalogJson());
      final original = catalog.createGame();
      final room = original.currentRoom.addDevice(
        const DeviceModel(
          id: 'persistent-device',
          templateId: 'server_basic',
          name: 'Device',
          type: DeviceType.server,
          position: GridPosition(4, 3),
        ),
      );
      final snapshot = GameModel.fromJson(
        original.updateRoom(room).copyWith(credits: 42).toJson(),
      );
      expect(snapshot.currentRoom.definition, isNull);
      expect(snapshot.currentRoom.definitionId, 'lab');
      final restored = catalog.resolveGame(snapshot);
      expect(restored.credits, 42);
      expect(restored.currentRoom.id, room.id);
      expect(restored.currentRoom.devices.single.id, 'persistent-device');
      expect(restored.currentRoom.doors.single, room.doors.single);
      expect(
        restored.currentRoom.definition!.objects.single.bindingSlot,
        'infra.primary',
      );
      expect(
        catalog.resolveGame(GameModel.initial()).currentRoom.definitionId,
        isNull,
      );
    },
  );
  test(
    'rejects a shop terminal with no reachable adjacent interaction cell',
    () {
      final json = catalogJson();
      cells(json)[0][1] = 'wall';
      cells(json)[1][0] = 'wall';
      expect(
        () => MapCatalog.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('terminal'),
          ),
        ),
      );
    },
  );

  test(
    'mapped reducer only accepts one cardinal step while legacy movement remains compatible',
    () {
      final mapped = MapCatalog.fromJson(catalogJson()).createGame();
      expect(reduce(mapped, const PlayerMoved(GridPosition(4, 1))), mapped);
      expect(reduce(mapped, const PlayerMoved(GridPosition(0, 2))), mapped);
      expect(
        reduce(mapped, const PlayerMoved(GridPosition(2, 1))).playerPosition,
        const GridPosition(2, 1),
      );
      final legacy = GameModel.initial();
      expect(
        reduce(legacy, const PlayerMoved(GridPosition(4, 1))).playerPosition,
        const GridPosition(4, 1),
      );
    },
  );

  test('restore refreshes authored portals and retains non-authored doors', () {
    final original = MapCatalog.fromJson(catalogJson()).createGame();
    final savedRoom = original.currentRoom.addDoor(
      const DoorModel(
        id: 'dynamic-door',
        targetRoomId: 'ops',
        wallSide: WallSide.bottom,
        wallPosition: 1,
      ),
    );
    final snapshot = GameModel.fromJson(
      original.updateRoom(savedRoom).toJson(),
    );
    final json = catalogJson();
    firstMap(json)['spawns']['maintenance'] = [4, 3];
    firstMap(json)['portals'][0]['targetMapId'] = 'lab';
    firstMap(json)['portals'][0]['targetSpawnId'] = 'maintenance';
    final updated = MapCatalog.fromJson(json).resolveGame(snapshot);
    final authored = updated.currentRoom.doors.firstWhere(
      (door) => door.id == 'lab:exit',
    );
    expect(authored.targetRoomId, 'lab');
    expect(authored.targetSpawnId, 'maintenance');
    expect(updated.currentRoom.doors.last.id, 'dynamic-door');
    firstMap(json)['portals'] = [];
    expect(
      MapCatalog.fromJson(
        json,
      ).resolveGame(snapshot).currentRoom.doors.single.id,
      'dynamic-door',
    );
  });
}
