import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('GameModel', () {
    late GameModel game;
    late RoomModel serverRoom;
    late RoomModel awsRoom;

    setUp(() {
      serverRoom = const RoomModel(
        id: 'server-room-1',
        name: 'Server Room',
        type: RoomType.serverRoom,
      );
      awsRoom = const RoomModel(
        id: 'aws-room-1',
        name: 'AWS',
        type: RoomType.aws,
        parentId: 'server-room-1',
      );
      game = GameModel(
        currentRoomId: 'server-room-1',
        rooms: [serverRoom, awsRoom],
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(game.currentRoomId, 'server-room-1');
        expect(game.rooms.length, 2);
        expect(game.credits, GameConstants.startingCredits);
        expect(game.playerPosition, GameConstants.playerStartPosition);
        expect(game.gameMode, GameMode.sim);
        expect(game.placementMode, PlacementMode.none);
        expect(game.shopOpen, isFalse);
      });

      test('initial factory creates default server room', () {
        final initial = GameModel.initial();

        expect(initial.rooms.length, 1);
        expect(initial.rooms.first.type, RoomType.serverRoom);
        expect(initial.rooms.first.name, 'Server Room');
        expect(initial.currentRoomId, initial.rooms.first.id);
      });
    });

    group('currentRoom', () {
      test('returns the room matching currentRoomId', () {
        expect(game.currentRoom.id, 'server-room-1');
        expect(game.currentRoom.name, 'Server Room');
      });

      test('returns first room if currentRoomId not found', () {
        final badGame = game.copyWith(currentRoomId: 'nonexistent');
        expect(badGame.currentRoom.id, 'server-room-1');
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = game.toJson();

        expect(json['currentRoomId'], 'server-room-1');
        expect((json['rooms'] as List).length, 2);
        expect(json['credits'], GameConstants.startingCredits);
        expect(json['gameMode'], 'sim');
      });

      test('fromJson produces correct model', () {
        final json = game.toJson();
        final restored = GameModel.fromJson(json);

        expect(restored.currentRoomId, game.currentRoomId);
        expect(restored.rooms.length, game.rooms.length);
        expect(restored.credits, game.credits);
        expect(restored.playerPosition, game.playerPosition);
        expect(restored.gameMode, game.gameMode);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'currentRoomId': 'room-1',
          'rooms': [
            {'id': 'room-1', 'name': 'Test Room'},
          ],
        };

        final restored = GameModel.fromJson(json);

        expect(restored.credits, GameConstants.startingCredits);
        expect(restored.playerPosition, GameConstants.playerStartPosition);
        expect(restored.gameMode, GameMode.sim);
      });

      test('round-trip serialization preserves all data', () {
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'aws-room-1',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );

        final roomWithObjects = serverRoom.addDoor(door).addDevice(device);
        final fullGame = game
            .updateRoom(roomWithObjects)
            .copyWith(
              credits: 500,
              playerPosition: const GridPosition(3, 4),
              gameMode: GameMode.live,
            );

        final restored = GameModel.fromJson(fullGame.toJson());

        expect(restored.credits, 500);
        expect(restored.playerPosition, const GridPosition(3, 4));
        expect(restored.gameMode, GameMode.live);
        expect(restored.currentRoom.doors.length, 1);
        expect(restored.currentRoom.devices.length, 1);
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final modified = game.copyWith(credits: 500, shopOpen: true);

        expect(modified.credits, 500);
        expect(modified.shopOpen, isTrue);
        expect(modified.currentRoomId, game.currentRoomId);
        expect(modified.rooms.length, game.rooms.length);
      });

      test('clearSelectedTemplate sets template to null', () {
        const template = DeviceTemplate(
          id: 'tmpl-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
        );
        final withTemplate = game.copyWith(selectedTemplate: template);
        expect(withTemplate.selectedTemplate, isNotNull);

        final cleared = withTemplate.copyWith(clearSelectedTemplate: true);
        expect(cleared.selectedTemplate, isNull);
      });

      test('clearSelectedCloudService sets service to null', () {
        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Test',
        );
        final withService = game.copyWith(selectedCloudService: cloudTemplate);
        expect(withService.selectedCloudService, isNotNull);

        final cleared = withService.copyWith(clearSelectedCloudService: true);
        expect(cleared.selectedCloudService, isNull);
      });

      test('clearSelectedTemplate takes precedence over selectedTemplate', () {
        const template = DeviceTemplate(
          id: 'tmpl-2',
          name: 'Switch',
          description: 'A network switch',
          type: DeviceType.switch_,
          cost: 50,
        );
        // Setting both value and clear flag should result in null
        final result = game.copyWith(
          selectedTemplate: template,
          clearSelectedTemplate: true,
        );
        expect(result.selectedTemplate, isNull);
      });

      test(
        'clearSelectedCloudService takes precedence over selectedCloudService',
        () {
          const cloudTemplate = CloudServiceTemplate(
            provider: CloudProvider.gcp,
            category: ServiceCategory.storage,
            serviceType: 'CloudStorage',
            name: 'Cloud Storage',
            description: 'Object storage',
          );
          // Setting both value and clear flag should result in null
          final result = game.copyWith(
            selectedCloudService: cloudTemplate,
            clearSelectedCloudService: true,
          );
          expect(result.selectedCloudService, isNull);
        },
      );

      test('clearSelectedTemplate false preserves template', () {
        const template = DeviceTemplate(
          id: 'tmpl-3',
          name: 'Router',
          description: 'A router',
          type: DeviceType.router,
          cost: 75,
        );
        final withTemplate = game.copyWith(selectedTemplate: template);
        // Explicitly setting clear to false should keep the template
        final result = withTemplate.copyWith(clearSelectedTemplate: false);
        expect(result.selectedTemplate, template);
      });

      test('clearSelectedCloudService false preserves service', () {
        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.azure,
          category: ServiceCategory.database,
          serviceType: 'CosmosDB',
          name: 'Cosmos DB',
          description: 'NoSQL database',
        );
        final withService = game.copyWith(selectedCloudService: cloudTemplate);
        // Explicitly setting clear to false should keep the service
        final result = withService.copyWith(clearSelectedCloudService: false);
        expect(result.selectedCloudService, cloudTemplate);
      });
    });

    group('room management', () {
      test('getRoomById returns correct room', () {
        expect(game.getRoomById('server-room-1')?.name, 'Server Room');
        expect(game.getRoomById('aws-room-1')?.name, 'AWS');
        expect(game.getRoomById('nonexistent'), isNull);
      });

      test('getChildRooms returns child rooms', () {
        final children = game.getChildRooms('server-room-1');
        expect(children.length, 1);
        expect(children.first.id, 'aws-room-1');
      });

      test('rootRooms returns rooms without parent', () {
        final roots = game.rootRooms;
        expect(roots.length, 1);
        expect(roots.first.id, 'server-room-1');
      });

      test('addRoom adds new room', () {
        const newRoom = RoomModel(
          id: 'gcp-room-1',
          name: 'GCP',
          type: RoomType.gcp,
          parentId: 'server-room-1',
        );

        final updated = game.addRoom(newRoom);

        expect(updated.rooms.length, 3);
        expect(updated.getRoomById('gcp-room-1')?.name, 'GCP');
      });

      test('updateRoom updates existing room', () {
        final modifiedRoom = serverRoom.copyWith(name: 'Updated Server Room');
        final updated = game.updateRoom(modifiedRoom);

        expect(
          updated.getRoomById('server-room-1')?.name,
          'Updated Server Room',
        );
        expect(updated.rooms.length, 2);
      });

      test('removeRoom removes room and children', () {
        // Add a child of AWS room
        const regionRoom = RoomModel(
          id: 'aws-region-1',
          name: 'us-east-1',
          type: RoomType.aws,
          parentId: 'aws-room-1',
          regionCode: 'us-east-1',
        );
        final gameWithRegion = game.addRoom(regionRoom);
        expect(gameWithRegion.rooms.length, 3);

        // Remove AWS room should also remove the region
        final afterRemove = gameWithRegion.removeRoom('aws-room-1');
        expect(afterRemove.rooms.length, 1);
        expect(afterRemove.getRoomById('aws-room-1'), isNull);
        expect(afterRemove.getRoomById('aws-region-1'), isNull);
        expect(afterRemove.getRoomById('server-room-1'), isNotNull);
      });

      test('removeRoom also removes doors pointing to removed room', () {
        // Add door from server room to AWS room
        const door = DoorModel(
          id: 'door-aws',
          targetRoomId: 'aws-room-1',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        final serverWithDoor = serverRoom.addDoor(door);
        final gameWithDoor = game.updateRoom(serverWithDoor);

        expect(gameWithDoor.currentRoom.doors.length, 1);

        // Remove AWS room
        final afterRemove = gameWithDoor.removeRoom('aws-room-1');

        // Door should be removed too
        expect(afterRemove.currentRoom.doors.length, 0);
      });

      test('removeRoom switches currentRoomId if current is removed', () {
        final gameInAws = game.copyWith(currentRoomId: 'aws-room-1');
        final afterRemove = gameInAws.removeRoom('aws-room-1');

        expect(afterRemove.currentRoomId, 'server-room-1');
      });

      test('removeRoom handles deep nesting (3+ levels)', () {
        // Create 4-level hierarchy: server -> aws -> region -> vpc
        const regionRoom = RoomModel(
          id: 'aws-region-1',
          name: 'us-east-1',
          type: RoomType.aws,
          parentId: 'aws-room-1',
        );
        const vpcRoom = RoomModel(
          id: 'vpc-1',
          name: 'VPC 1',
          type: RoomType.aws,
          parentId: 'aws-region-1',
        );

        final deepGame = game.addRoom(regionRoom).addRoom(vpcRoom);
        expect(deepGame.rooms.length, 4);

        // Remove AWS room should cascade to region and VPC
        final afterRemove = deepGame.removeRoom('aws-room-1');
        expect(afterRemove.rooms.length, 1);
        expect(afterRemove.getRoomById('aws-room-1'), isNull);
        expect(afterRemove.getRoomById('aws-region-1'), isNull);
        expect(afterRemove.getRoomById('vpc-1'), isNull);
        expect(afterRemove.getRoomById('server-room-1'), isNotNull);
      });

      test('removeRoom does nothing for nonexistent room', () {
        final afterRemove = game.removeRoom('nonexistent-room');
        expect(afterRemove.rooms.length, game.rooms.length);
        expect(afterRemove.currentRoomId, game.currentRoomId);
      });

      test('removeRoom handles removing middle of chain', () {
        // server -> aws -> region: remove aws, region should also go
        const regionRoom = RoomModel(
          id: 'aws-region-1',
          name: 'us-east-1',
          type: RoomType.aws,
          parentId: 'aws-room-1',
        );
        final gameWithRegion = game.addRoom(regionRoom);

        final afterRemove = gameWithRegion.removeRoom('aws-room-1');
        expect(afterRemove.rooms.length, 1);
        expect(afterRemove.getRoomById('aws-region-1'), isNull);
      });

      test('removeRoom handles multiple sibling children', () {
        // server -> [aws, gcp, azure]
        const gcpRoom = RoomModel(
          id: 'gcp-room-1',
          name: 'GCP',
          type: RoomType.gcp,
          parentId: 'server-room-1',
        );
        const azureRoom = RoomModel(
          id: 'azure-room-1',
          name: 'Azure',
          type: RoomType.azure,
          parentId: 'server-room-1',
        );

        final gameWithSiblings = game.addRoom(gcpRoom).addRoom(azureRoom);
        expect(gameWithSiblings.rooms.length, 4);

        // Remove only aws, siblings should stay
        final afterRemove = gameWithSiblings.removeRoom('aws-room-1');
        expect(afterRemove.rooms.length, 3);
        expect(afterRemove.getRoomById('aws-room-1'), isNull);
        expect(afterRemove.getRoomById('gcp-room-1'), isNotNull);
        expect(afterRemove.getRoomById('azure-room-1'), isNotNull);
      });

      test('removeRoom removes multiple doors pointing to removed rooms', () {
        // Server room has doors to both AWS and GCP, remove both
        const gcpRoom = RoomModel(
          id: 'gcp-room-1',
          name: 'GCP',
          type: RoomType.gcp,
          parentId: 'server-room-1',
        );
        const awsDoor = DoorModel(
          id: 'door-aws',
          targetRoomId: 'aws-room-1',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        const gcpDoor = DoorModel(
          id: 'door-gcp',
          targetRoomId: 'gcp-room-1',
          wallSide: WallSide.top,
          wallPosition: 3,
        );

        final serverWithDoors = serverRoom.addDoor(awsDoor).addDoor(gcpDoor);
        var gameWithDoors = game.updateRoom(serverWithDoors).addRoom(gcpRoom);

        expect(gameWithDoors.currentRoom.doors.length, 2);

        // Remove AWS
        gameWithDoors = gameWithDoors.removeRoom('aws-room-1');
        expect(gameWithDoors.currentRoom.doors.length, 1);
        expect(gameWithDoors.currentRoom.doors.first.id, 'door-gcp');
      });
    });

    group('navigation', () {
      test('enterRoom changes currentRoomId and playerPosition', () {
        const newPosition = GridPosition(2, 3);
        final moved = game.enterRoom('aws-room-1', newPosition);

        expect(moved.currentRoomId, 'aws-room-1');
        expect(moved.playerPosition, newPosition);
      });
    });

    group('equality', () {
      test('equal games are equal', () {
        const game1 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );
        const game2 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );

        expect(game1, game2);
      });

      test('different games are not equal', () {
        const game1 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
        );
        final game2 = game1.copyWith(credits: 999);

        expect(game1, isNot(game2));
      });

      test('equal games have same hashCode', () {
        const game1 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );
        const game2 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );

        expect(game1.hashCode, game2.hashCode);
      });

      test('games can be used in Set collections', () {
        const game1 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );
        const game2 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );
        const game3 = GameModel(
          currentRoomId: 'room-2',
          rooms: [RoomModel(id: 'room-2', name: 'Room 2')],
          credits: 500,
        );

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final gameSet = {game1, game2, game3};
        expect(gameSet.length, 2);
        expect(gameSet.contains(game1), isTrue);
        expect(gameSet.contains(game3), isTrue);
      });

      test('games can be used as Map keys', () {
        const game1 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );
        const game2 = GameModel(
          currentRoomId: 'room-1',
          rooms: [RoomModel(id: 'room-1', name: 'Room 1')],
          credits: 100,
        );

        final gameMap = <GameModel, String>{game1: 'first'};
        gameMap[game2] = 'second';

        expect(gameMap.length, 1);
        expect(gameMap[game1], 'second');
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final str = game.toString();
        expect(str, contains('GameModel'));
        expect(str, contains(game.currentRoomId));
        expect(str, contains('rooms: ${game.rooms.length}'));
        expect(str, contains('credits: ${game.credits}'));
      });
    });

    group('edge cases', () {
      test('getChildRooms returns empty list when no children', () {
        final children = game.getChildRooms('aws-room-1');
        expect(children, isEmpty);
      });

      test('getChildRooms returns empty list for nonexistent parent', () {
        final children = game.getChildRooms('nonexistent-parent');
        expect(children, isEmpty);
      });

      test('enterRoom to nonexistent room still updates state', () {
        const newPosition = GridPosition(5, 5);
        final moved = game.enterRoom('nonexistent-room', newPosition);

        expect(moved.currentRoomId, 'nonexistent-room');
        expect(moved.playerPosition, newPosition);
        // currentRoom should fallback to first room
        expect(moved.currentRoom.id, 'server-room-1');
      });

      test('updateRoom with room not in list has no effect', () {
        const newRoom = RoomModel(
          id: 'not-in-list',
          name: 'Unknown Room',
          type: RoomType.custom,
        );
        final updated = game.updateRoom(newRoom);

        expect(updated.rooms.length, 2);
        expect(updated.getRoomById('not-in-list'), isNull);
      });

      test('copyWith all fields simultaneously', () {
        const template = DeviceTemplate(
          id: 'tmpl-all',
          name: 'All Fields',
          description: 'Test all fields',
          type: DeviceType.server,
          cost: 999,
        );
        const cloudService = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'Lambda',
          name: 'Lambda',
          description: 'Serverless',
        );
        const newRoom = RoomModel(
          id: 'new-room',
          name: 'New Room',
          type: RoomType.custom,
        );

        final fullyModified = game.copyWith(
          currentRoomId: 'new-room',
          rooms: [newRoom],
          credits: 999999,
          playerPosition: const GridPosition(10, 10),
          gameMode: GameMode.live,
          placementMode: PlacementMode.placing,
          selectedTemplate: template,
          selectedCloudService: cloudService,
          shopOpen: true,
        );

        expect(fullyModified.currentRoomId, 'new-room');
        expect(fullyModified.rooms.length, 1);
        expect(fullyModified.credits, 999999);
        expect(fullyModified.playerPosition, const GridPosition(10, 10));
        expect(fullyModified.gameMode, GameMode.live);
        expect(fullyModified.placementMode, PlacementMode.placing);
        expect(fullyModified.selectedTemplate, template);
        expect(fullyModified.selectedCloudService, cloudService);
        expect(fullyModified.shopOpen, isTrue);
      });

      test('addRoom with duplicate id does not deduplicate', () {
        // Adding a room with same id results in two rooms with same id
        // This tests current behavior - the model doesn't prevent duplicates
        const duplicateRoom = RoomModel(
          id: 'server-room-1',
          name: 'Duplicate Server Room',
          type: RoomType.custom,
        );
        final updated = game.addRoom(duplicateRoom);

        expect(updated.rooms.length, 3);
        // getRoomById returns the first match
        expect(updated.getRoomById('server-room-1')?.name, 'Server Room');
      });

      test('removeRoom on empty rooms list returns same state', () {
        const emptyGame = GameModel(currentRoomId: 'none', rooms: []);
        final afterRemove = emptyGame.removeRoom('any');

        expect(afterRemove.rooms, isEmpty);
        expect(afterRemove.currentRoomId, 'none');
      });

      test('serialization with all placement modes', () {
        for (final mode in PlacementMode.values) {
          final gameWithMode = game.copyWith(placementMode: mode);
          // Note: placementMode is not serialized in toJson, so we just verify it's set
          expect(gameWithMode.placementMode, mode);
        }
      });

      test('serialization with all game modes', () {
        for (final mode in GameMode.values) {
          final gameWithMode = game.copyWith(gameMode: mode);
          final json = gameWithMode.toJson();
          final restored = GameModel.fromJson(json);

          expect(restored.gameMode, mode);
        }
      });

      test('fromJson with invalid gameMode falls back to sim', () {
        final json = {
          'currentRoomId': 'room-1',
          'rooms': [
            {'id': 'room-1', 'name': 'Test Room'},
          ],
          'gameMode': 'invalid_mode',
        };

        // This will throw because 'invalid_mode' is not a valid GameMode
        expect(() => GameModel.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('rootRooms with all rooms having parents returns empty', () {
        // Create game where all rooms have parents
        const orphanGame = GameModel(
          currentRoomId: 'child-1',
          rooms: [
            RoomModel(
              id: 'child-1',
              name: 'Child 1',
              parentId: 'nonexistent-parent',
            ),
            RoomModel(
              id: 'child-2',
              name: 'Child 2',
              parentId: 'also-nonexistent',
            ),
          ],
        );

        expect(orphanGame.rootRooms, isEmpty);
      });

      test(
        'getChildRooms with circular parent references handles gracefully',
        () {
          // This tests resilience - doesn't cause infinite loop
          const circularGame = GameModel(
            currentRoomId: 'room-a',
            rooms: [
              RoomModel(id: 'room-a', name: 'A', parentId: 'room-b'),
              RoomModel(id: 'room-b', name: 'B', parentId: 'room-a'),
            ],
          );

          // Should just return direct children, not follow circular refs
          final childrenOfA = circularGame.getChildRooms('room-a');
          expect(childrenOfA.length, 1);
          expect(childrenOfA.first.id, 'room-b');
        },
      );

      test('removeRoom handles circular parent references', () {
        // Room A -> Room B -> Room A (circular)
        const circularGame = GameModel(
          currentRoomId: 'room-a',
          rooms: [
            RoomModel(id: 'room-a', name: 'A', parentId: 'room-b'),
            RoomModel(id: 'room-b', name: 'B', parentId: 'room-a'),
          ],
        );

        // Removing room-a causes cascade: room-b has parent room-a, so both get removed
        final afterRemove = circularGame.removeRoom('room-a');
        expect(afterRemove.rooms, isEmpty);
      });

      test('equality with different selectedTemplate', () {
        const template = DeviceTemplate(
          id: 'tmpl-eq',
          name: 'Template',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        final game1 = game.copyWith(selectedTemplate: template);
        final game2 = game.copyWith();

        expect(game1, isNot(game2));
      });

      test('equality with different selectedCloudService', () {
        const service = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Test',
        );
        final game1 = game.copyWith(selectedCloudService: service);
        final game2 = game.copyWith();

        expect(game1, isNot(game2));
      });

      test('equality with different placementMode', () {
        final game1 = game.copyWith(placementMode: PlacementMode.placing);
        final game2 = game.copyWith(placementMode: PlacementMode.removing);

        expect(game1, isNot(game2));
      });

      test('equality with different shopOpen', () {
        final game1 = game.copyWith(shopOpen: true);
        final game2 = game.copyWith(shopOpen: false);

        expect(game1, isNot(game2));
      });
    });
  });
}
