import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_world/game_objects_world.dart';

class MockGameBloc extends Mock implements GameBloc {}

class MockWorldBloc extends Mock implements WorldBloc {}

void main() {
  group('HomelabGame', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();

      // Setup default stubs
      when(() => gameBloc.state).thenReturn(const GameLoading());
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.state).thenReturn(const WorldState());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    group('constructor', () {
      test('creates with required blocs', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.gameBloc, gameBloc);
        expect(game.worldBloc, worldBloc);
      });

      test('extends FlameGame', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isA<FlameGame>());
      });
    });

    group('bloc access', () {
      test('gameBloc is accessible', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.gameBloc, same(gameBloc));
      });

      test('worldBloc is accessible', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.worldBloc, same(worldBloc));
      });
    });

    group('with GameReady state', () {
      late GameModel testModel;

      setUp(() {
        testModel = GameModel.initial();
        when(() => gameBloc.state).thenReturn(GameReady(testModel));
      });

      test('game can be created with ready state', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isNotNull);
        expect((gameBloc.state as GameReady).model, testModel);
      });
    });

    group('with custom model', () {
      test('uses model from gameBloc state', () {
        const customRoom = RoomModel(
          id: 'custom-room',
          name: 'Custom Room',
          type: RoomType.aws,
          width: 30,
          height: 20,
        );
        const customModel = GameModel(
          rooms: [customRoom],
          currentRoomId: 'custom-room',
          playerPosition: GridPosition(5, 5),
          credits: 500,
        );
        when(() => gameBloc.state).thenReturn(const GameReady(customModel));

        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isNotNull);
        final state = gameBloc.state as GameReady;
        expect(state.model.credits, 500);
        expect(state.model.currentRoom.name, 'Custom Room');
      });
    });

    group('multiple instances', () {
      test('can create multiple independent games', () {
        final game1 = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        final gameBloc2 = MockGameBloc();
        final worldBloc2 = MockWorldBloc();
        when(() => gameBloc2.state).thenReturn(const GameLoading());
        when(() => gameBloc2.stream).thenAnswer((_) => const Stream.empty());
        when(() => worldBloc2.state).thenReturn(const WorldState());
        when(() => worldBloc2.stream).thenAnswer((_) => const Stream.empty());

        final game2 = HomelabGame(gameBloc: gameBloc2, worldBloc: worldBloc2);

        expect(game1.gameBloc, isNot(same(game2.gameBloc)));
        expect(game1.worldBloc, isNot(same(game2.worldBloc)));
      });
    });
  });

  group('GamepadButton integration', () {
    test('HomelabGame can use GamepadButton values', () {
      // Ensure GamepadButton enum is exported and usable
      expect(GamepadButton.south, isA<GamepadButton>());
      expect(GamepadButton.east, isA<GamepadButton>());
      expect(GamepadButton.north, isA<GamepadButton>());
      expect(GamepadButton.west, isA<GamepadButton>());
      expect(GamepadButton.start, isA<GamepadButton>());
    });
  });

  group('Direction integration', () {
    test('HomelabGame can use Direction values', () {
      expect(Direction.up, isA<Direction>());
      expect(Direction.down, isA<Direction>());
      expect(Direction.left, isA<Direction>());
      expect(Direction.right, isA<Direction>());
      expect(Direction.none, isA<Direction>());
    });
  });

  group('InteractionType integration', () {
    test('HomelabGame can use InteractionType values', () {
      expect(InteractionType.none, isA<InteractionType>());
      expect(InteractionType.door, isA<InteractionType>());
      expect(InteractionType.terminal, isA<InteractionType>());
      expect(InteractionType.device, isA<InteractionType>());
    });
  });

  group('PlacementMode integration', () {
    test('HomelabGame can use PlacementMode values', () {
      expect(PlacementMode.none, isA<PlacementMode>());
      expect(PlacementMode.placing, isA<PlacementMode>());
    });
  });

  group('GridPosition helpers', () {
    test('gridToPixel converts correctly', () {
      final (x, y) = gridToPixel(const GridPosition(5, 3));
      expect(x, 5 * GameConstants.tileSize);
      expect(y, 3 * GameConstants.tileSize);
    });

    test('pixelToGrid converts correctly', () {
      const tileSize = GameConstants.tileSize;
      final gridPos = pixelToGrid(5 * tileSize + 10, 3 * tileSize + 10);
      expect(gridPos.x, 5);
      expect(gridPos.y, 3);
    });

    test('isWithinBounds returns true for valid positions', () {
      expect(isWithinBounds(const GridPosition(0, 0)), isTrue);
      expect(
        isWithinBounds(
          const GridPosition(
            GameConstants.roomWidth - 1,
            GameConstants.roomHeight - 1,
          ),
        ),
        isTrue,
      );
    });

    test('isWithinBounds returns false for out of bounds positions', () {
      expect(isWithinBounds(const GridPosition(-1, 0)), isFalse);
      expect(isWithinBounds(const GridPosition(0, -1)), isFalse);
      expect(
        isWithinBounds(const GridPosition(GameConstants.roomWidth, 0)),
        isFalse,
      );
      expect(
        isWithinBounds(const GridPosition(0, GameConstants.roomHeight)),
        isFalse,
      );
    });
  });

  group('GameConstants', () {
    test('has valid room dimensions', () {
      expect(GameConstants.roomWidth, greaterThan(0));
      expect(GameConstants.roomHeight, greaterThan(0));
      expect(GameConstants.tileSize, greaterThan(0));
    });

    test('has valid player start position', () {
      const startPos = GameConstants.playerStartPosition;
      expect(startPos.x, greaterThanOrEqualTo(0));
      expect(startPos.y, greaterThanOrEqualTo(0));
      expect(startPos.x, lessThan(GameConstants.roomWidth));
      expect(startPos.y, lessThan(GameConstants.roomHeight));
    });

    test('has valid terminal position', () {
      const terminalPos = GameConstants.terminalPosition;
      expect(terminalPos.x, greaterThanOrEqualTo(0));
      expect(terminalPos.y, greaterThanOrEqualTo(0));
      expect(terminalPos.x, lessThan(GameConstants.roomWidth));
      expect(terminalPos.y, lessThan(GameConstants.roomHeight));
    });
  });

  group('GridPosition helpers edge cases', () {
    test('gridToPixel works with zero position', () {
      final (x, y) = gridToPixel(const GridPosition(0, 0));
      expect(x, 0);
      expect(y, 0);
    });

    test('gridToPixel works with large coordinates', () {
      final (x, y) = gridToPixel(const GridPosition(100, 100));
      expect(x, 100 * GameConstants.tileSize);
      expect(y, 100 * GameConstants.tileSize);
    });

    test('pixelToGrid handles zero coordinates', () {
      final gridPos = pixelToGrid(0, 0);
      expect(gridPos.x, 0);
      expect(gridPos.y, 0);
    });

    test('pixelToGrid rounds down fractional tile positions', () {
      const tileSize = GameConstants.tileSize;
      final gridPos = pixelToGrid(tileSize * 2.9, tileSize * 3.9);
      expect(gridPos.x, 2);
      expect(gridPos.y, 3);
    });

    test('isWithinBounds with custom bounds', () {
      // Default bounds use GameConstants
      expect(isWithinBounds(const GridPosition(5, 5)), isTrue);
    });
  });

  group('HomelabGame state transitions', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();
      when(() => gameBloc.state).thenReturn(const GameLoading());
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.state).thenReturn(const WorldState());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    test('game handles GameLoading state', () {
      when(() => gameBloc.state).thenReturn(const GameLoading());

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      expect(game.gameBloc.state, isA<GameLoading>());
    });

    test('game handles GameReady with multiple rooms', () {
      const room1 = RoomModel(
        id: 'room-1',
        name: 'Room 1',
        type: RoomType.serverRoom,
      );
      const room2 = RoomModel(id: 'room-2', name: 'Room 2', type: RoomType.aws);
      const multiRoomModel = GameModel(
        rooms: [room1, room2],
        currentRoomId: 'room-1',
      );
      when(() => gameBloc.state).thenReturn(const GameReady(multiRoomModel));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.rooms.length, 2);
    });
  });

  group('WorldState integration', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();
      when(() => gameBloc.state).thenReturn(const GameLoading());
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    test('game handles WorldState with hovered cell', () {
      const worldState = WorldState(hoveredCell: GridPosition(5, 5));
      when(() => worldBloc.state).thenReturn(worldState);

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      expect(game.worldBloc.state.hoveredCell, const GridPosition(5, 5));
    });

    test('game handles WorldState with selected entity', () {
      const worldState = WorldState(selectedEntityId: 'device-1');
      when(() => worldBloc.state).thenReturn(worldState);

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      expect(game.worldBloc.state.selectedEntityId, 'device-1');
    });

    test('game handles WorldState with interaction available', () {
      const worldState = WorldState(
        interactableEntityId: 'door-1',
        availableInteraction: InteractionType.door,
      );
      when(() => worldBloc.state).thenReturn(worldState);

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      expect(game.worldBloc.state.canInteract, isTrue);
      expect(game.worldBloc.state.availableInteraction, InteractionType.door);
    });
  });

  group('DeviceModel helpers', () {
    test('DeviceModel can be created with valid data', () {
      const device = DeviceModel(
        id: 'device-1',
        templateId: 'template-1',
        name: 'Test Device',
        type: DeviceType.server,
        position: GridPosition(5, 5),
      );

      expect(device.id, 'device-1');
      expect(device.name, 'Test Device');
      expect(device.position, const GridPosition(5, 5));
    });

    test('DeviceModel supports different device types', () {
      for (final type in DeviceType.values) {
        final device = DeviceModel(
          id: 'device-${type.name}',
          templateId: 'template-1',
          name: 'Device ${type.name}',
          type: type,
          position: const GridPosition(0, 0),
        );

        expect(device.type, type);
      }
    });
  });

  group('CloudServiceModel helpers', () {
    test('CloudServiceModel can be created with valid data', () {
      const service = CloudServiceModel(
        id: 'service-1',
        serviceType: 'EC2',
        name: 'Test Service',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        position: GridPosition(3, 3),
      );

      expect(service.id, 'service-1');
      expect(service.name, 'Test Service');
      expect(service.position, const GridPosition(3, 3));
    });

    test('CloudServiceModel supports different providers', () {
      for (final provider in CloudProvider.values) {
        final service = CloudServiceModel(
          id: 'service-${provider.name}',
          serviceType: 'EC2',
          name: 'Service ${provider.name}',
          provider: provider,
          category: ServiceCategory.compute,
          position: const GridPosition(0, 0),
        );

        expect(service.provider, provider);
      }
    });
  });

  group('DoorModel helpers', () {
    test('DoorModel can be created with valid data', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.top,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );

      expect(door.id, 'door-1');
      expect(door.wallSide, WallSide.top);
      expect(door.targetRoomId, 'room-2');
    });

    test('DoorModel supports all wall positions', () {
      for (final wall in WallSide.values) {
        final door = DoorModel(
          id: 'door-${wall.name}',
          wallSide: wall,
          wallPosition: 5,
          targetRoomId: 'room-2',
        );

        expect(door.wallSide, wall);
      }
    });

    test('DoorModel getPosition calculates correctly for top wall', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.top,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );

      final pos = door.getPosition(20, 15);
      expect(pos.y, 0);
      expect(pos.x, 5);
    });

    test('DoorModel getPosition calculates correctly for bottom wall', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.bottom,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );

      final pos = door.getPosition(20, 15);
      expect(pos.y, 14); // height - 1
      expect(pos.x, 5);
    });

    test('DoorModel getPosition calculates correctly for right wall', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.right,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );

      final pos = door.getPosition(20, 15);
      expect(pos.x, 19); // width - 1
      expect(pos.y, 5);
    });

    test('DoorModel getPosition calculates correctly for left wall', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.left,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );

      final pos = door.getPosition(20, 15);
      expect(pos.x, 0);
      expect(pos.y, 5);
    });
  });

  group('RoomModel helpers', () {
    test('RoomModel canPlaceDevice returns true for empty cell', () {
      const room = RoomModel(
        id: 'room-1',
        name: 'Test Room',
        type: RoomType.serverRoom,
        width: 20,
        height: 15,
      );

      expect(room.canPlaceDevice(const GridPosition(5, 5), 1, 1), isTrue);
    });

    test('RoomModel canPlaceDevice returns false for occupied cell', () {
      const device = DeviceModel(
        id: 'device-1',
        templateId: 'template-1',
        name: 'Blocker',
        type: DeviceType.server,
        position: GridPosition(5, 5),
      );
      const room = RoomModel(
        id: 'room-1',
        name: 'Test Room',
        type: RoomType.serverRoom,
        width: 20,
        height: 15,
        devices: [device],
      );

      expect(room.canPlaceDevice(const GridPosition(5, 5), 1, 1), isFalse);
    });

    test('RoomModel canPlaceDevice returns false for out of bounds', () {
      const room = RoomModel(
        id: 'room-1',
        name: 'Test Room',
        type: RoomType.serverRoom,
        width: 20,
        height: 15,
      );

      expect(room.canPlaceDevice(const GridPosition(19, 14), 2, 2), isFalse);
    });
  });

  group('DeviceTemplate helpers', () {
    test('DeviceTemplate can be created', () {
      const template = DeviceTemplate(
        id: 'template-1',
        name: 'Test Server',
        description: 'A test server for unit tests',
        type: DeviceType.server,
        cost: 100,
        width: 2,
        height: 1,
      );

      expect(template.id, 'template-1');
      expect(template.cost, 100);
      expect(template.width, 2);
      expect(template.description, 'A test server for unit tests');
    });
  });

  group('CloudServiceTemplate helpers', () {
    test('CloudServiceTemplate can be created', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'Test Service',
        description: 'A test cloud service for unit tests',
      );

      expect(template.serviceType, 'EC2');
      expect(template.provider, CloudProvider.aws);
      expect(template.description, 'A test cloud service for unit tests');
    });
  });

  group('HomelabGame model synchronization patterns', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.state).thenReturn(const WorldState());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    test('game handles room with devices', () {
      const device = DeviceModel(
        id: 'device-1',
        templateId: 'template-1',
        name: 'Server',
        type: DeviceType.server,
        position: GridPosition(5, 5),
      );
      const room = RoomModel(
        id: 'room-1',
        name: 'Server Room',
        type: RoomType.serverRoom,
        devices: [device],
      );
      const model = GameModel(rooms: [room], currentRoomId: 'room-1');
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.currentRoom.devices.length, 1);
      expect(state.model.currentRoom.devices.first.id, 'device-1');
    });

    test('game handles room with cloud services', () {
      const service = CloudServiceModel(
        id: 'service-1',
        serviceType: 'EC2',
        name: 'EC2',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        position: GridPosition(3, 3),
      );
      const room = RoomModel(
        id: 'room-1',
        name: 'AWS Room',
        type: RoomType.aws,
        cloudServices: [service],
      );
      const model = GameModel(rooms: [room], currentRoomId: 'room-1');
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.currentRoom.cloudServices.length, 1);
      expect(state.model.currentRoom.cloudServices.first.id, 'service-1');
    });

    test('game handles room with doors', () {
      const door = DoorModel(
        id: 'door-1',
        wallSide: WallSide.top,
        wallPosition: 5,
        targetRoomId: 'room-2',
      );
      const room1 = RoomModel(
        id: 'room-1',
        name: 'Room 1',
        type: RoomType.serverRoom,
        doors: [door],
      );
      const room2 = RoomModel(id: 'room-2', name: 'Room 2', type: RoomType.aws);
      const model = GameModel(rooms: [room1, room2], currentRoomId: 'room-1');
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.currentRoom.doors.length, 1);
      expect(state.model.currentRoom.doors.first.targetRoomId, 'room-2');
    });

    test('game handles empty room', () {
      const room = RoomModel(
        id: 'room-1',
        name: 'Empty Room',
        type: RoomType.serverRoom,
      );
      const model = GameModel(rooms: [room], currentRoomId: 'room-1');
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.currentRoom.devices, isEmpty);
      expect(state.model.currentRoom.cloudServices, isEmpty);
      expect(state.model.currentRoom.doors, isEmpty);
    });
  });

  group('HomelabGame placement mode patterns', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.state).thenReturn(const WorldState());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    test('game handles placement mode with device template', () {
      const template = DeviceTemplate(
        id: 'template-1',
        name: 'Server',
        description: 'A test server',
        type: DeviceType.server,
        cost: 100,
      );
      const room = RoomModel(
        id: 'room-1',
        name: 'Room',
        type: RoomType.serverRoom,
      );
      const model = GameModel(
        rooms: [room],
        currentRoomId: 'room-1',
        placementMode: PlacementMode.placing,
        selectedTemplate: template,
      );
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.placementMode, PlacementMode.placing);
      expect(state.model.selectedTemplate, isNotNull);
      expect(state.model.selectedTemplate!.id, 'template-1');
    });

    test('game handles placement mode with cloud service template', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2 Instance',
        description: 'A test cloud service',
      );
      const room = RoomModel(id: 'room-1', name: 'Room', type: RoomType.aws);
      const model = GameModel(
        rooms: [room],
        currentRoomId: 'room-1',
        placementMode: PlacementMode.placing,
        selectedCloudService: template,
      );
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.placementMode, PlacementMode.placing);
      expect(state.model.selectedCloudService, isNotNull);
      expect(state.model.selectedCloudService!.serviceType, 'EC2');
    });

    test('game handles no placement mode', () {
      const room = RoomModel(
        id: 'room-1',
        name: 'Room',
        type: RoomType.serverRoom,
      );
      const model = GameModel(
        rooms: [room],
        currentRoomId: 'room-1',
        placementMode: PlacementMode.none,
      );
      when(() => gameBloc.state).thenReturn(const GameReady(model));

      final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

      final state = game.gameBloc.state as GameReady;
      expect(state.model.placementMode, PlacementMode.none);
      expect(state.model.selectedTemplate, isNull);
      expect(state.model.selectedCloudService, isNull);
    });
  });
}
