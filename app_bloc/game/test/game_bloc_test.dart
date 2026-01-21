import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_database/app_database.dart';
import 'package:app_bloc_game/app_bloc_game.dart';

class MockGameStorage extends Mock implements GameStorage {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockGameStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(GameModel.initial());
  });

  setUp(() {
    mockStorage = MockGameStorage();
  });

  group('GameBloc', () {
    group('initial state', () {
      test('is GameLoading', () {
        final bloc = GameBloc(storage: mockStorage);
        expect(bloc.state, isA<GameLoading>());
        bloc.close();
      });

      test('currentModel is null when not ready', () {
        final bloc = GameBloc(storage: mockStorage);
        expect(bloc.currentModel, isNull);
        bloc.close();
      });
    });

    group('GameInitialize', () {
      blocTest<GameBloc, GameState>(
        'emits GameReady with initial model when no saved game',
        setUp: () {
          when(() => mockStorage.load()).thenAnswer((_) async => null);
        },
        build: () => GameBloc(storage: mockStorage),
        act: (bloc) => bloc.add(const GameInitialize()),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.credits,
            'credits',
            GameConstants.startingCredits,
          ),
        ],
        verify: (_) {
          verify(() => mockStorage.load()).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'emits GameReady with saved model when game exists',
        setUp: () {
          final savedModel = GameModel.initial().copyWith(credits: 500);
          when(() => mockStorage.load()).thenAnswer((_) async => savedModel);
        },
        build: () => GameBloc(storage: mockStorage),
        act: (bloc) => bloc.add(const GameInitialize()),
        expect: () => [
          isA<GameReady>().having((s) => s.model.credits, 'credits', 500),
        ],
      );

      blocTest<GameBloc, GameState>(
        'emits GameError when storage throws',
        setUp: () {
          when(() => mockStorage.load()).thenThrow(Exception('Storage error'));
        },
        build: () => GameBloc(storage: mockStorage),
        act: (bloc) => bloc.add(const GameInitialize()),
        expect: () => [
          isA<GameError>().having(
            (s) => s.message,
            'message',
            contains('Failed to initialize'),
          ),
        ],
      );
    });

    group('GameMovePlayer', () {
      blocTest<GameBloc, GameState>(
        'moves player in direction',
        setUp: () {
          when(() => mockStorage.load()).thenAnswer((_) async => null);
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GameMovePlayer(Direction.down)),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.playerPosition,
            'playerPosition',
            GameConstants.playerStartPosition + const GridPosition(0, 1),
          ),
        ],
      );

      blocTest<GameBloc, GameState>(
        'does nothing when not ready',
        build: () => GameBloc(storage: mockStorage),
        act: (bloc) => bloc.add(const GameMovePlayer(Direction.up)),
        expect: () => <GameState>[],
      );

      blocTest<GameBloc, GameState>(
        'handles all directions',
        setUp: () {
          when(() => mockStorage.load()).thenAnswer((_) async => null);
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            playerPosition: const GridPosition(10, 6),
          ),
        ),
        act: (bloc) {
          bloc.add(const GameMovePlayer(Direction.up));
          bloc.add(const GameMovePlayer(Direction.down));
          bloc.add(const GameMovePlayer(Direction.left));
          bloc.add(const GameMovePlayer(Direction.right));
        },
        expect: () => [
          isA<GameReady>().having((s) => s.model.playerPosition.y, 'y', 5),
          isA<GameReady>().having((s) => s.model.playerPosition.y, 'y', 6),
          isA<GameReady>().having((s) => s.model.playerPosition.x, 'x', 9),
          isA<GameReady>().having((s) => s.model.playerPosition.x, 'x', 10),
        ],
      );

      blocTest<GameBloc, GameState>(
        'Direction.none emits no state change when position same',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            playerPosition: const GridPosition(10, 6),
          ),
        ),
        act: (bloc) => bloc.add(const GameMovePlayer(Direction.none)),
        // Direction.none creates delta (0,0), which is valid but position unchanged
        // BLoC emits but state is equal, so nothing changes due to Equatable
        expect: () => <GameState>[],
      );
    });

    group('GameMovePlayerTo', () {
      blocTest<GameBloc, GameState>(
        'moves player to position',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GameMovePlayerTo(GridPosition(5, 5))),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.playerPosition,
            'playerPosition',
            const GridPosition(5, 5),
          ),
        ],
      );
    });

    group('GameToggleShop', () {
      blocTest<GameBloc, GameState>(
        'opens shop when closed',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial().copyWith(shopOpen: false)),
        act: (bloc) => bloc.add(const GameToggleShop()),
        expect: () => [
          isA<GameReady>().having((s) => s.model.shopOpen, 'shopOpen', true),
        ],
      );

      blocTest<GameBloc, GameState>(
        'closes shop when open',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial().copyWith(shopOpen: true)),
        act: (bloc) => bloc.add(const GameToggleShop()),
        expect: () => [
          isA<GameReady>().having((s) => s.model.shopOpen, 'shopOpen', false),
        ],
      );

      blocTest<GameBloc, GameState>(
        'sets shop to specific state',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial().copyWith(shopOpen: false)),
        act: (bloc) => bloc.add(const GameToggleShop(isOpen: true)),
        expect: () => [
          isA<GameReady>().having((s) => s.model.shopOpen, 'shopOpen', true),
        ],
      );
    });

    group('GameSelectTemplate', () {
      const template = DeviceTemplate(
        id: 'server_basic',
        name: 'Basic Server',
        description: 'A simple server',
        type: DeviceType.server,
        cost: 500,
      );

      blocTest<GameBloc, GameState>(
        'sets selected template and closes shop',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial().copyWith(shopOpen: true)),
        act: (bloc) => bloc.add(const GameSelectTemplate(template)),
        expect: () => [
          isA<GameReady>()
              .having(
                (s) => s.model.selectedTemplate,
                'selectedTemplate',
                template,
              )
              .having((s) => s.model.shopOpen, 'shopOpen', false)
              .having(
                (s) => s.model.placementMode,
                'placementMode',
                PlacementMode.placing,
              ),
        ],
      );
    });

    group('GameCancelPlacement', () {
      blocTest<GameBloc, GameState>(
        'clears placement mode and template',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            placementMode: PlacementMode.placing,
            selectedTemplate: const DeviceTemplate(
              id: 'server_basic',
              name: 'Server',
              description: 'Desc',
              type: DeviceType.server,
              cost: 100,
            ),
          ),
        ),
        act: (bloc) => bloc.add(const GameCancelPlacement()),
        expect: () => [
          isA<GameReady>()
              .having(
                (s) => s.model.placementMode,
                'placementMode',
                PlacementMode.none,
              )
              .having(
                (s) => s.model.selectedTemplate,
                'selectedTemplate',
                isNull,
              ),
        ],
      );
    });

    group('GamePlaceDevice', () {
      const template = DeviceTemplate(
        id: 'server_basic',
        name: 'Server',
        description: 'A server',
        type: DeviceType.server,
        cost: 500,
      );

      blocTest<GameBloc, GameState>(
        'places device and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            credits: 1000,
            selectedTemplate: template,
            placementMode: PlacementMode.placing,
          ),
        ),
        act: (bloc) => bloc.add(const GamePlaceDevice(GridPosition(5, 5))),
        expect: () => [
          isA<GameReady>()
              .having(
                (s) => s.model.currentRoom.devices.length,
                'devices count',
                1,
              )
              .having(
                (s) => s.model.placementMode,
                'placementMode',
                PlacementMode.none,
              ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'does nothing when no template selected',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GamePlaceDevice(GridPosition(5, 5))),
        expect: () => <GameState>[],
      );
    });

    group('GameRemoveDevice', () {
      blocTest<GameBloc, GameState>(
        'removes device and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () {
          final model = GameModel.initial().copyWith(credits: 1000);
          const device = DeviceModel(
            id: 'dev-1',
            templateId: 'server_basic',
            name: 'Server',
            type: DeviceType.server,
            position: GridPosition(5, 5),
          );
          final roomWithDevice = model.currentRoom.addDevice(device);
          return GameReady(model.updateRoom(roomWithDevice));
        },
        act: (bloc) => bloc.add(const GameRemoveDevice('dev-1')),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.devices.length,
            'devices count',
            0,
          ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );
    });

    group('GameChangeMode', () {
      blocTest<GameBloc, GameState>(
        'changes to live mode',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GameChangeMode(GameMode.live)),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.gameMode,
            'gameMode',
            GameMode.live,
          ),
        ],
      );
    });

    group('GameSave', () {
      blocTest<GameBloc, GameState>(
        'saves current model',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GameSave()),
        expect: () => <GameState>[],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'does nothing when not ready',
        build: () => GameBloc(storage: mockStorage),
        act: (bloc) => bloc.add(const GameSave()),
        expect: () => <GameState>[],
        verify: (_) {
          verifyNever(() => mockStorage.save(any()));
        },
      );
    });

    group('GameEnterRoom', () {
      blocTest<GameBloc, GameState>(
        'enters room via door and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () {
          final model = GameModel.initial();
          // Add a second room
          final newModel = reduce(
            model,
            const RoomAdded(
              name: 'AWS',
              type: RoomType.aws,
              doorSide: WallSide.right,
              doorPosition: 5,
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final newRoom = model.rooms.firstWhere((r) => r.name == 'AWS');
          bloc.add(
            GameEnterRoom(
              roomId: newRoom.id,
              spawnPosition: const GridPosition(1, 5),
            ),
          );
        },
        expect: () => [
          isA<GameReady>()
              .having((s) => s.model.currentRoom.name, 'room name', 'AWS')
              .having(
                (s) => s.model.playerPosition,
                'playerPosition',
                const GridPosition(1, 5),
              ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'does nothing when room does not exist',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(
          const GameEnterRoom(
            roomId: 'nonexistent',
            spawnPosition: GridPosition(1, 1),
          ),
        ),
        expect: () => <GameState>[],
      );
    });

    group('GameAddRoom', () {
      blocTest<GameBloc, GameState>(
        'adds room with door and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(
          const GameAddRoom(
            name: 'AWS',
            type: RoomType.aws,
            doorSide: WallSide.right,
            doorPosition: 5,
          ),
        ),
        expect: () => [
          isA<GameReady>()
              .having((s) => s.model.rooms.length, 'rooms count', 2)
              .having(
                (s) => s.model.currentRoom.doors.length,
                'doors count',
                1,
              ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'adds room with region code',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(
          const GameAddRoom(
            name: 'us-east-1',
            type: RoomType.aws,
            regionCode: 'us-east-1',
            doorSide: WallSide.bottom,
            doorPosition: 8,
          ),
        ),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.rooms
                .firstWhere((r) => r.name == 'us-east-1')
                .regionCode,
            'regionCode',
            'us-east-1',
          ),
        ],
      );
    });

    group('GameRemoveRoom', () {
      blocTest<GameBloc, GameState>(
        'removes room and its door, then saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () {
          final model = GameModel.initial();
          final newModel = reduce(
            model,
            const RoomAdded(
              name: 'AWS',
              type: RoomType.aws,
              doorSide: WallSide.right,
              doorPosition: 5,
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final newRoom = model.rooms.firstWhere((r) => r.name == 'AWS');
          bloc.add(GameRemoveRoom(newRoom.id));
        },
        expect: () => [
          isA<GameReady>()
              .having((s) => s.model.rooms.length, 'rooms count', 1)
              .having(
                (s) => s.model.currentRoom.doors.length,
                'doors count',
                0,
              ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );
    });

    group('GameSelectCloudService', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2 Instance',
        description: 'Virtual compute',
      );

      blocTest<GameBloc, GameState>(
        'sets selected cloud service and closes shop',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial().copyWith(shopOpen: true)),
        act: (bloc) => bloc.add(const GameSelectCloudService(template)),
        expect: () => [
          isA<GameReady>()
              .having(
                (s) => s.model.selectedCloudService,
                'selectedCloudService',
                template,
              )
              .having((s) => s.model.shopOpen, 'shopOpen', false)
              .having(
                (s) => s.model.placementMode,
                'placementMode',
                PlacementMode.placing,
              ),
        ],
      );
    });

    group('GamePlaceCloudService', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2',
        description: 'Compute',
      );

      blocTest<GameBloc, GameState>(
        'places cloud service and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            selectedCloudService: template,
            placementMode: PlacementMode.placing,
          ),
        ),
        act: (bloc) =>
            bloc.add(const GamePlaceCloudService(GridPosition(5, 5))),
        expect: () => [
          isA<GameReady>()
              .having(
                (s) => s.model.currentRoom.cloudServices.length,
                'cloudServices count',
                1,
              )
              .having(
                (s) => s.model.placementMode,
                'placementMode',
                PlacementMode.none,
              ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'does nothing when no cloud service selected',
        build: () => GameBloc(storage: mockStorage),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) =>
            bloc.add(const GamePlaceCloudService(GridPosition(5, 5))),
        expect: () => <GameState>[],
      );
    });

    group('GameRemoveCloudService', () {
      blocTest<GameBloc, GameState>(
        'removes cloud service and saves',
        setUp: () {
          when(() => mockStorage.save(any())).thenAnswer((_) async {});
        },
        build: () => GameBloc(storage: mockStorage),
        seed: () {
          final model = GameModel.initial();
          final newModel = reduce(
            model,
            const CloudServicePlaced(
              provider: CloudProvider.aws,
              category: ServiceCategory.compute,
              serviceType: 'EC2',
              name: 'My EC2',
              position: GridPosition(5, 5),
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final serviceId = model.currentRoom.cloudServices.first.id;
          bloc.add(GameRemoveCloudService(serviceId));
        },
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.cloudServices.length,
            'cloudServices count',
            0,
          ),
        ],
        verify: (_) {
          verify(() => mockStorage.save(any())).called(1);
        },
      );
    });

    group('storage error handling', () {
      late MockAppLogger mockLogger;

      setUp(() {
        mockLogger = MockAppLogger();
      });

      blocTest<GameBloc, GameState>(
        'GamePlaceDevice logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            credits: 1000,
            selectedTemplate: const DeviceTemplate(
              id: 'server_basic',
              name: 'Server',
              description: 'A server',
              type: DeviceType.server,
              cost: 500,
            ),
            placementMode: PlacementMode.placing,
          ),
        ),
        act: (bloc) => bloc.add(const GamePlaceDevice(GridPosition(5, 5))),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.devices.length,
            'devices count',
            1,
          ),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameRemoveDevice logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () {
          final model = GameModel.initial().copyWith(credits: 1000);
          const device = DeviceModel(
            id: 'dev-1',
            templateId: 'server_basic',
            name: 'Server',
            type: DeviceType.server,
            position: GridPosition(5, 5),
          );
          final roomWithDevice = model.currentRoom.addDevice(device);
          return GameReady(model.updateRoom(roomWithDevice));
        },
        act: (bloc) => bloc.add(const GameRemoveDevice('dev-1')),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.devices.length,
            'devices count',
            0,
          ),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameSave logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(const GameSave()),
        expect: () => <GameState>[],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameEnterRoom logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () {
          final model = GameModel.initial();
          final newModel = reduce(
            model,
            const RoomAdded(
              name: 'AWS',
              type: RoomType.aws,
              doorSide: WallSide.right,
              doorPosition: 5,
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final newRoom = model.rooms.firstWhere((r) => r.name == 'AWS');
          bloc.add(
            GameEnterRoom(
              roomId: newRoom.id,
              spawnPosition: const GridPosition(1, 5),
            ),
          );
        },
        expect: () => [
          isA<GameReady>().having((s) => s.model.currentRoom.name, 'name', 'AWS'),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameAddRoom logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () => GameReady(GameModel.initial()),
        act: (bloc) => bloc.add(
          const GameAddRoom(
            name: 'AWS',
            type: RoomType.aws,
            doorSide: WallSide.right,
            doorPosition: 5,
          ),
        ),
        expect: () => [
          isA<GameReady>().having((s) => s.model.rooms.length, 'rooms count', 2),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameRemoveRoom logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () {
          final model = GameModel.initial();
          final newModel = reduce(
            model,
            const RoomAdded(
              name: 'AWS',
              type: RoomType.aws,
              doorSide: WallSide.right,
              doorPosition: 5,
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final newRoom = model.rooms.firstWhere((r) => r.name == 'AWS');
          bloc.add(GameRemoveRoom(newRoom.id));
        },
        expect: () => [
          isA<GameReady>().having((s) => s.model.rooms.length, 'rooms count', 1),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GamePlaceCloudService logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () => GameReady(
          GameModel.initial().copyWith(
            selectedCloudService: const CloudServiceTemplate(
              provider: CloudProvider.aws,
              category: ServiceCategory.compute,
              serviceType: 'EC2',
              name: 'EC2',
              description: 'Compute',
            ),
            placementMode: PlacementMode.placing,
          ),
        ),
        act: (bloc) =>
            bloc.add(const GamePlaceCloudService(GridPosition(5, 5))),
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.cloudServices.length,
            'cloudServices count',
            1,
          ),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'GameRemoveCloudService logs warning when storage fails',
        setUp: () {
          when(() => mockStorage.save(any()))
              .thenThrow(Exception('Storage error'));
          when(() => mockLogger.w(any(), any(), any())).thenReturn(null);
        },
        build: () => GameBloc(storage: mockStorage, logger: mockLogger),
        seed: () {
          final model = GameModel.initial();
          final newModel = reduce(
            model,
            const CloudServicePlaced(
              provider: CloudProvider.aws,
              category: ServiceCategory.compute,
              serviceType: 'EC2',
              name: 'My EC2',
              position: GridPosition(5, 5),
            ),
          );
          return GameReady(newModel);
        },
        act: (bloc) {
          final model = (bloc.state as GameReady).model;
          final serviceId = model.currentRoom.cloudServices.first.id;
          bloc.add(GameRemoveCloudService(serviceId));
        },
        expect: () => [
          isA<GameReady>().having(
            (s) => s.model.currentRoom.cloudServices.length,
            'cloudServices count',
            0,
          ),
        ],
        verify: (_) {
          verify(() => mockLogger.w(any(), any(), any())).called(1);
        },
      );
    });

    group('currentModel', () {
      test('returns model when GameReady', () {
        final bloc = GameBloc(storage: mockStorage);
        final model = GameModel.initial();
        bloc.emit(GameReady(model));
        expect(bloc.currentModel, model);
        bloc.close();
      });

      test('returns null when GameLoading', () {
        final bloc = GameBloc(storage: mockStorage);
        expect(bloc.currentModel, isNull);
        bloc.close();
      });

      test('returns null when GameError', () {
        final bloc = GameBloc(storage: mockStorage);
        bloc.emit(const GameError('error'));
        expect(bloc.currentModel, isNull);
        bloc.close();
      });
    });
  });

  group('GameState', () {
    group('GameLoading', () {
      test('props is empty', () {
        const state = GameLoading();
        expect(state.props, isEmpty);
      });

      test('equal instances are equal', () {
        const state1 = GameLoading();
        const state2 = GameLoading();
        expect(state1, state2);
      });
    });

    group('GameReady', () {
      test('props contains model', () {
        final model = GameModel.initial();
        final state = GameReady(model);
        expect(state.props, [model]);
      });

      test('equal states are equal', () {
        final model = GameModel.initial();
        final state1 = GameReady(model);
        final state2 = GameReady(model);
        expect(state1, state2);
      });
    });

    group('GameError', () {
      test('props contains message', () {
        const state = GameError('error message');
        expect(state.props, ['error message']);
      });

      test('equal states are equal', () {
        const state1 = GameError('error');
        const state2 = GameError('error');
        expect(state1, state2);
      });

      test('different errors are not equal', () {
        const state1 = GameError('error 1');
        const state2 = GameError('error 2');
        expect(state1, isNot(state2));
      });
    });
  });

  group('GameEvent', () {
    group('GameInitialize', () {
      test('equal events are equal', () {
        const event1 = GameInitialize();
        const event2 = GameInitialize();
        expect(event1, event2);
      });
    });

    group('GameMovePlayer', () {
      test('equal events are equal', () {
        const event1 = GameMovePlayer(Direction.up);
        const event2 = GameMovePlayer(Direction.up);
        expect(event1, event2);
      });

      test('different directions are not equal', () {
        const event1 = GameMovePlayer(Direction.up);
        const event2 = GameMovePlayer(Direction.down);
        expect(event1, isNot(event2));
      });
    });

    group('GameMovePlayerTo', () {
      test('equal events are equal', () {
        const event1 = GameMovePlayerTo(GridPosition(5, 5));
        const event2 = GameMovePlayerTo(GridPosition(5, 5));
        expect(event1, event2);
      });
    });

    group('GameToggleShop', () {
      test('equal events are equal', () {
        const event1 = GameToggleShop(isOpen: true);
        const event2 = GameToggleShop(isOpen: true);
        expect(event1, event2);
      });
    });

    group('GameSelectTemplate', () {
      test('equal events are equal', () {
        const template = DeviceTemplate(
          id: 'server',
          name: 'Server',
          description: 'Desc',
          type: DeviceType.server,
          cost: 100,
        );
        const event1 = GameSelectTemplate(template);
        const event2 = GameSelectTemplate(template);
        expect(event1, event2);
      });
    });

    group('GameCancelPlacement', () {
      test('equal events are equal', () {
        const event1 = GameCancelPlacement();
        const event2 = GameCancelPlacement();
        expect(event1, event2);
      });
    });

    group('GamePlaceDevice', () {
      test('equal events are equal', () {
        const event1 = GamePlaceDevice(GridPosition(5, 5));
        const event2 = GamePlaceDevice(GridPosition(5, 5));
        expect(event1, event2);
      });
    });

    group('GameRemoveDevice', () {
      test('equal events are equal', () {
        const event1 = GameRemoveDevice('dev-1');
        const event2 = GameRemoveDevice('dev-1');
        expect(event1, event2);
      });
    });

    group('GameChangeMode', () {
      test('equal events are equal', () {
        const event1 = GameChangeMode(GameMode.live);
        const event2 = GameChangeMode(GameMode.live);
        expect(event1, event2);
      });
    });

    group('GameSave', () {
      test('equal events are equal', () {
        const event1 = GameSave();
        const event2 = GameSave();
        expect(event1, event2);
      });
    });

    group('GameEnterRoom', () {
      test('equal events are equal', () {
        const event1 = GameEnterRoom(
          roomId: 'room-1',
          spawnPosition: GridPosition(1, 1),
        );
        const event2 = GameEnterRoom(
          roomId: 'room-1',
          spawnPosition: GridPosition(1, 1),
        );
        expect(event1, event2);
      });
    });

    group('GameAddRoom', () {
      test('equal events are equal', () {
        const event1 = GameAddRoom(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = GameAddRoom(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event1, event2);
      });
    });

    group('GameRemoveRoom', () {
      test('equal events are equal', () {
        const event1 = GameRemoveRoom('room-1');
        const event2 = GameRemoveRoom('room-1');
        expect(event1, event2);
      });
    });

    group('GameSelectCloudService', () {
      test('equal events are equal', () {
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute',
        );
        const event1 = GameSelectCloudService(template);
        const event2 = GameSelectCloudService(template);
        expect(event1, event2);
      });
    });

    group('GamePlaceCloudService', () {
      test('equal events are equal', () {
        const event1 = GamePlaceCloudService(GridPosition(5, 5));
        const event2 = GamePlaceCloudService(GridPosition(5, 5));
        expect(event1, event2);
      });
    });

    group('GameRemoveCloudService', () {
      test('equal events are equal', () {
        const event1 = GameRemoveCloudService('svc-1');
        const event2 = GameRemoveCloudService('svc-1');
        expect(event1, event2);
      });
    });
  });
}
