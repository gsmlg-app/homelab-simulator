import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('findDeviceTemplateById', () {
    test('returns template when found', () {
      final result = findDeviceTemplateById('server_basic');

      expect(result, isNotNull);
      expect(result!.id, 'server_basic');
      expect(result.name, 'Basic Server');
    });

    test('returns null when template not found', () {
      final result = findDeviceTemplateById('nonexistent_template');

      expect(result, isNull);
    });

    test('finds all default templates by ID', () {
      for (final template in defaultDeviceTemplates) {
        final result = findDeviceTemplateById(template.id);
        expect(
          result,
          isNotNull,
          reason: 'Should find template ${template.id}',
        );
        expect(result!.id, template.id);
      }
    });

    test('returns correct template from multiple options', () {
      final result = findDeviceTemplateById('router_basic');

      expect(result, isNotNull);
      expect(result!.id, 'router_basic');
      expect(result.type, DeviceType.router);
    });
  });

  group('reduce', () {
    late GameModel model;

    setUp(() {
      model = GameModel.initial();
    });

    group('PlayerMoved', () {
      test('moves player to valid position', () {
        const newPos = GridPosition(5, 5);
        final result = reduce(model, const PlayerMoved(newPos));

        expect(result.playerPosition, newPos);
      });

      test('ignores move to out of bounds position', () {
        final originalPos = model.playerPosition;
        const outOfBounds = GridPosition(-1, 5);
        final result = reduce(model, const PlayerMoved(outOfBounds));

        expect(result.playerPosition, originalPos);
      });

      test('ignores move to occupied cell', () {
        // First place a device
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server_basic',
          name: 'Server',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        final roomWithDevice = model.currentRoom.addDevice(device);
        final modelWithDevice = model.updateRoom(roomWithDevice);

        // Try to move to occupied position
        final originalPos = modelWithDevice.playerPosition;
        final result = reduce(
          modelWithDevice,
          const PlayerMoved(GridPosition(5, 5)),
        );

        expect(result.playerPosition, originalPos);
      });
    });

    group('ShopToggled', () {
      test('opens shop', () {
        final result = reduce(model, const ShopToggled(true));
        expect(result.shopOpen, isTrue);
      });

      test('closes shop', () {
        final openModel = model.copyWith(shopOpen: true);
        final result = reduce(openModel, const ShopToggled(false));
        expect(result.shopOpen, isFalse);
      });
    });

    group('TemplateSelected', () {
      test('sets selected template and placement mode', () {
        const template = DeviceTemplate(
          id: 'server_basic',
          name: 'Basic Server',
          description: 'A simple rack server',
          type: DeviceType.server,
          cost: 500,
        );

        final result = reduce(model, const TemplateSelected(template));

        expect(result.selectedTemplate, template);
        expect(result.placementMode, PlacementMode.placing);
      });
    });

    group('PlacementModeChanged', () {
      test('changes placement mode', () {
        final result = reduce(
          model,
          const PlacementModeChanged(PlacementMode.placing),
        );
        expect(result.placementMode, PlacementMode.placing);
      });

      test('clears selected template when mode is none', () {
        const template = DeviceTemplate(
          id: 'server_basic',
          name: 'Server',
          description: 'Desc',
          type: DeviceType.server,
          cost: 100,
        );
        final withTemplate = model.copyWith(
          selectedTemplate: template,
          placementMode: PlacementMode.placing,
        );

        final result = reduce(
          withTemplate,
          const PlacementModeChanged(PlacementMode.none),
        );

        expect(result.placementMode, PlacementMode.none);
        expect(result.selectedTemplate, isNull);
      });

      test('clears selected cloud service when mode is none', () {
        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute',
        );
        final withService = model.copyWith(
          selectedCloudService: cloudTemplate,
          placementMode: PlacementMode.placing,
        );

        final result = reduce(
          withService,
          const PlacementModeChanged(PlacementMode.none),
        );

        expect(result.selectedCloudService, isNull);
      });
    });

    group('DevicePlaced', () {
      test('places device at valid position', () {
        final modelWithCredits = model.copyWith(credits: GameConstants.startingCredits);
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );

        final result = reduce(modelWithCredits, event);

        expect(result.currentRoom.devices.length, 1);
        expect(
          result.currentRoom.devices.first.position,
          const GridPosition(5, 5),
        );
        expect(result.credits, lessThan(1000)); // Cost deducted
        expect(result.placementMode, PlacementMode.none);
      });

      test('does not place device if insufficient credits', () {
        final poorModel = model.copyWith(credits: 0);
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );

        final result = reduce(poorModel, event);

        expect(result.currentRoom.devices.length, 0);
        expect(result.credits, 0);
      });

      test('does not place device at invalid position', () {
        final modelWithCredits = model.copyWith(credits: GameConstants.startingCredits);
        // Terminal position is typically at (2,2)
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(2, 2),
        );

        final result = reduce(modelWithCredits, event);

        expect(result.currentRoom.devices.length, 0);
      });

      test('checks position validity before checking credits', () {
        // With 0 credits and invalid position, should fail on position first
        // (no credit error thrown, just returns unchanged model)
        final poorModel = model.copyWith(credits: 0);
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(2, 2), // Terminal position - invalid
        );

        final result = reduce(poorModel, event);

        // Model unchanged - position check came first
        expect(result.currentRoom.devices.length, 0);
        expect(result.credits, 0);
      });

      test('deducts exact template cost', () {
        // server_basic costs 500
        final modelWithExactCredits = model.copyWith(credits: 500);
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );

        final result = reduce(modelWithExactCredits, event);

        expect(result.currentRoom.devices.length, 1);
        expect(result.credits, 0); // Exactly 0 after placement
      });

      test('fails when credits are one short of cost', () {
        // server_basic costs 500, try with 499
        final modelWithAlmostEnough = model.copyWith(credits: 499);
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );

        final result = reduce(modelWithAlmostEnough, event);

        expect(result.currentRoom.devices.length, 0);
        expect(result.credits, 499);
      });

      test('returns unchanged model if templateId not found', () {
        final modelWithCredits = model.copyWith(credits: 10000);
        const event = DevicePlaced(
          templateId: 'nonexistent_template',
          position: GridPosition(5, 5),
        );

        final result = reduce(modelWithCredits, event);

        // Should return unchanged model (no device placed)
        expect(result.currentRoom.devices.length, 0);
        expect(result.credits, 10000);
      });
    });

    group('DeviceRemoved', () {
      test('removes device and refunds partial cost', () {
        // First place a device
        final modelWithCredits = model.copyWith(credits: GameConstants.startingCredits);
        const placeEvent = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        final afterPlace = reduce(modelWithCredits, placeEvent);
        final creditsAfterPlace = afterPlace.credits;
        final deviceId = afterPlace.currentRoom.devices.first.id;

        // Remove the device
        final result = reduce(afterPlace, DeviceRemoved(deviceId));

        expect(result.currentRoom.devices.length, 0);
        expect(
          result.credits,
          greaterThan(creditsAfterPlace),
        ); // Partial refund
      });

      test('refunds exactly half for even cost (integer division)', () {
        // server_basic has cost of 500, so refund should be 250
        final modelWithCredits = model.copyWith(credits: GameConstants.startingCredits);
        const placeEvent = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        final afterPlace = reduce(modelWithCredits, placeEvent);
        final creditsAfterPlace = afterPlace.credits;
        final deviceId = afterPlace.currentRoom.devices.first.id;

        final result = reduce(afterPlace, DeviceRemoved(deviceId));

        // Expect exactly half refund (500 / 2 = 250)
        expect(result.credits, creditsAfterPlace + 250);
      });

      test('returns unchanged model when removing nonexistent device', () {
        final result = reduce(model, const DeviceRemoved('nonexistent-device'));
        expect(result, model);
      });
    });

    group('CreditsChanged', () {
      test('increases credits', () {
        final result = reduce(model, const CreditsChanged(100));
        expect(result.credits, model.credits + 100);
      });

      test('decreases credits', () {
        final result = reduce(model, const CreditsChanged(-100));
        expect(result.credits, model.credits - 100);
      });

      test('allows credits to go negative with large negative amount', () {
        // This tests that the reducer does not prevent negative credits
        final result = reduce(model, const CreditsChanged(-100000));
        expect(result.credits, lessThan(0));
      });

      test('handles zero change', () {
        final result = reduce(model, const CreditsChanged(0));
        expect(result.credits, model.credits);
      });

      test('handles very large positive amount', () {
        final result = reduce(model, const CreditsChanged(999999999));
        expect(result.credits, model.credits + 999999999);
      });
    });

    group('GameModeChanged', () {
      test('changes game mode to live', () {
        final result = reduce(model, const GameModeChanged(GameMode.live));
        expect(result.gameMode, GameMode.live);
      });

      test('changes game mode to sim', () {
        final liveModel = model.copyWith(gameMode: GameMode.live);
        final result = reduce(liveModel, const GameModeChanged(GameMode.sim));
        expect(result.gameMode, GameMode.sim);
      });
    });

    group('GameLoaded', () {
      test('returns model unchanged', () {
        final result = reduce(model, const GameLoaded());
        expect(result, model);
      });
    });

    group('RoomEntered', () {
      test('enters room via door', () {
        // Add a second room
        const addRoomEvent = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        final modelWithRoom = reduce(model, addRoomEvent);
        final newRoomId = modelWithRoom.rooms
            .firstWhere((r) => r.name == 'AWS')
            .id;

        // Enter the room
        final result = reduce(
          modelWithRoom,
          RoomEntered(
            roomId: newRoomId,
            spawnPosition: const GridPosition(2, 5),
          ),
        );

        expect(result.currentRoomId, newRoomId);
        expect(result.playerPosition, const GridPosition(2, 5));
      });
    });

    group('RoomAdded', () {
      test('adds room with door connection', () {
        const event = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );

        final result = reduce(model, event);

        // Should have 2 rooms now
        expect(result.rooms.length, 2);

        // New room should exist
        final newRoom = result.rooms.firstWhere((r) => r.name == 'AWS');
        expect(newRoom.type, RoomType.aws);
        expect(newRoom.parentId, model.currentRoomId);

        // Current room should have a door to new room
        final updatedCurrentRoom = result.getRoomById(model.currentRoomId);
        expect(updatedCurrentRoom!.doors.length, 1);
        expect(updatedCurrentRoom.doors.first.targetRoomId, newRoom.id);
        expect(updatedCurrentRoom.doors.first.wallSide, WallSide.right);

        // New room should have a door back
        expect(newRoom.doors.length, 1);
        expect(newRoom.doors.first.targetRoomId, model.currentRoomId);
        expect(newRoom.doors.first.wallSide, WallSide.left); // Opposite
      });

      test('adds room with region code', () {
        const event = RoomAdded(
          name: 'us-east-1',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.bottom,
          doorPosition: 8,
        );

        final result = reduce(model, event);
        final newRoom = result.rooms.firstWhere((r) => r.name == 'us-east-1');

        expect(newRoom.regionCode, 'us-east-1');
      });
    });

    group('RoomRemoved', () {
      test('removes room', () {
        // First add a room
        const addEvent = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        final modelWithRoom = reduce(model, addEvent);
        final newRoomId = modelWithRoom.rooms
            .firstWhere((r) => r.name == 'AWS')
            .id;

        // Remove the room
        final result = reduce(modelWithRoom, RoomRemoved(newRoomId));

        expect(result.rooms.length, 1);
        expect(result.getRoomById(newRoomId), isNull);

        // Door should be removed from original room
        expect(result.currentRoom.doors.length, 0);
      });
    });

    group('CloudServiceSelected', () {
      test('sets selected cloud service and placement mode', () {
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2 Instance',
          description: 'Virtual compute',
        );

        final result = reduce(model, const CloudServiceSelected(template));

        expect(result.selectedCloudService, template);
        expect(result.placementMode, PlacementMode.placing);
        expect(result.selectedTemplate, isNull); // Device template cleared
      });
    });

    group('CloudServicePlaced', () {
      test('places cloud service at valid position', () {
        const event = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );

        final result = reduce(model, event);

        expect(result.currentRoom.cloudServices.length, 1);
        expect(
          result.currentRoom.cloudServices.first.position,
          const GridPosition(5, 5),
        );
        expect(
          result.currentRoom.cloudServices.first.provider,
          CloudProvider.aws,
        );
        expect(result.placementMode, PlacementMode.none);
      });

      test('does not place cloud service at invalid position', () {
        // Terminal position is typically at (2,2)
        const event = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(2, 2),
        );

        final result = reduce(model, event);

        expect(result.currentRoom.cloudServices.length, 0);
      });
    });

    group('CloudServiceRemoved', () {
      test('removes cloud service', () {
        // First place a service
        const placeEvent = CloudServicePlaced(
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          serviceType: 'CloudStorage',
          name: 'My Storage',
          position: GridPosition(6, 6),
        );
        final afterPlace = reduce(model, placeEvent);
        final serviceId = afterPlace.currentRoom.cloudServices.first.id;

        // Remove the service
        final result = reduce(afterPlace, CloudServiceRemoved(serviceId));

        expect(result.currentRoom.cloudServices.length, 0);
      });

      test('returns unchanged model when removing nonexistent service', () {
        final result = reduce(
          model,
          const CloudServiceRemoved('nonexistent-id'),
        );

        expect(result.currentRoom.cloudServices.length, 0);
        // Model should be functionally equivalent (same structure, different room instance)
        expect(result.currentRoomId, model.currentRoomId);
      });
    });

    group('DeviceRemoved edge cases', () {
      test('refunds 0 credits when template not found', () {
        // Add a device with unknown template directly to room
        const deviceWithUnknownTemplate = DeviceModel(
          id: 'orphan-device',
          templateId: 'deleted_template',
          name: 'Orphan Device',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        final roomWithOrphan = model.currentRoom.addDevice(
          deviceWithUnknownTemplate,
        );
        final modelWithOrphan = model.updateRoom(roomWithOrphan);

        final result = reduce(
          modelWithOrphan,
          const DeviceRemoved('orphan-device'),
        );

        // Device should be removed
        expect(result.currentRoom.devices.length, 0);
        // Credits should be unchanged (0 refund for unknown template)
        expect(result.credits, modelWithOrphan.credits);
      });

      test('uses integer division for odd cost refund', () {
        // iot_sensor has cost 50, so refund should be 25 (50 ~/ 2)
        final modelWithCredits = model.copyWith(credits: GameConstants.startingCredits);
        const placeEvent = DevicePlaced(
          templateId: 'iot_sensor',
          position: GridPosition(5, 5),
        );
        final afterPlace = reduce(modelWithCredits, placeEvent);
        final creditsAfterPlace = afterPlace.credits;
        final deviceId = afterPlace.currentRoom.devices.first.id;

        final result = reduce(afterPlace, DeviceRemoved(deviceId));

        // Expect exactly half refund (50 / 2 = 25)
        expect(result.credits, creditsAfterPlace + 25);
      });
    });

    group('PlayerMoved edge cases', () {
      test('allows move to cell adjacent to device', () {
        // Place a device at (5, 5)
        const device = DeviceModel(
          id: 'blocker',
          templateId: 'server_basic',
          name: 'Blocker',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        final roomWithDevice = model.currentRoom.addDevice(device);
        final modelWithDevice = model.updateRoom(roomWithDevice);

        // Move to adjacent cell (should succeed)
        final result = reduce(
          modelWithDevice,
          const PlayerMoved(GridPosition(4, 5)),
        );

        expect(result.playerPosition, const GridPosition(4, 5));
      });

      test('ignores move to out of bounds high position', () {
        const outOfBounds = GridPosition(100, 100);
        final result = reduce(model, const PlayerMoved(outOfBounds));

        expect(result.playerPosition, model.playerPosition);
      });
    });

    group('RoomAdded edge cases', () {
      test('creates bidirectional doors for top wall', () {
        const event = RoomAdded(
          name: 'Top Room',
          type: RoomType.gcp,
          doorSide: WallSide.top,
          doorPosition: 5,
        );

        final result = reduce(model, event);
        final newRoom = result.rooms.firstWhere((r) => r.name == 'Top Room');

        // Current room should have door on top
        final currentRoom = result.getRoomById(model.currentRoomId);
        expect(currentRoom!.doors.first.wallSide, WallSide.top);

        // New room should have door on bottom (opposite)
        expect(newRoom.doors.first.wallSide, WallSide.bottom);
      });

      test('creates bidirectional doors for left wall', () {
        const event = RoomAdded(
          name: 'Left Room',
          type: RoomType.vultr,
          doorSide: WallSide.left,
          doorPosition: 5,
        );

        final result = reduce(model, event);
        final newRoom = result.rooms.firstWhere((r) => r.name == 'Left Room');

        final currentRoom = result.getRoomById(model.currentRoomId);
        expect(currentRoom!.doors.first.wallSide, WallSide.left);
        expect(newRoom.doors.first.wallSide, WallSide.right);
      });
    });
  });
}
