import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements GameStorage {}

MapCatalog _catalog() => MapCatalog.fromJson({
  'schemaVersion': 1,
  'atlasAsset': 'assets/maps/atlas.png',
  'initialMapId': 'mapped',
  'tiles': [],
  'prefabs': [],
  'maps': [
    {
      'id': 'mapped',
      'name': 'Mapped',
      'width': 12,
      'height': 10,
      'spawns': {
        'entry': [1, 1],
      },
      'terminalPosition': [0, 0],
      'layers': [],
      'objects': [],
      'portals': [],
    },
  ],
});

void main() {
  test('initialize installs exactly one cloud center for a new game', () async {
    final storage = _Storage();
    when(() => storage.load()).thenAnswer((_) async => null);
    final bloc = GameBloc(storage: storage);
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere((state) => state is GameReady);
    bloc.add(const GameInitialize());
    final model = ((await ready) as GameReady).model;
    final centers = model.rooms.where(
      (room) => room.type.name == 'cloudCenter',
    );
    expect(centers, hasLength(1));
    expect(
      model.currentRoom.doors.where(
        (door) => door.targetRoomId == centers.single.id,
      ),
      hasLength(1),
    );
  });

  test(
    'reloading legacy saves with a map catalog preserves player, devices and doors',
    () async {
      const device = DeviceModel(
        id: 'user-device',
        templateId: 'server_basic',
        name: 'User server',
        type: DeviceType.server,
        position: GridPosition(3, 3),
      );
      const door = DoorModel(
        id: 'user-door',
        targetRoomId: 'annex',
        wallSide: WallSide.bottom,
        wallPosition: 4,
      );
      GameModel saved = const GameModel(
        currentRoomId: 'legacy',
        playerPosition: GridPosition(2, 2),
        credits: 321,
        rooms: [
          RoomModel(
            id: 'legacy',
            name: 'Legacy',
            devices: [device],
            doors: [door],
          ),
          RoomModel(id: 'annex', name: 'Annex'),
        ],
      );
      final storage = _Storage();
      when(() => storage.load()).thenAnswer((_) async => saved);
      for (var login = 0; login < 5; login++) {
        final bloc = GameBloc(
          storage: storage,
          mapCatalogLoader: () async => _catalog(),
        );
        final ready = bloc.stream.firstWhere((state) => state is GameReady);
        bloc.add(const GameInitialize());
        final model = ((await ready) as GameReady).model;
        expect(model.currentRoomId, 'legacy');
        expect(model.playerPosition, const GridPosition(2, 2));
        expect(model.credits, 321);
        expect(model.currentRoom.devices, [device]);
        expect(model.currentRoom.doors, contains(door));
        expect(
          model.rooms.where((room) => room.type.name == 'cloudCenter'),
          hasLength(1),
        );
        saved = GameModel.fromJson(model.toJson());
        await bloc.close();
      }
    },
  );
}
