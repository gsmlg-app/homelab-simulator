import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('RoomModel', () {
    late RoomModel room;

    setUp(() {
      room = const RoomModel(
        id: 'room-1',
        name: 'Test Room',
        type: RoomType.serverRoom,
        width: 20,
        height: 12,
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(room.id, 'room-1');
        expect(room.name, 'Test Room');
        expect(room.type, RoomType.serverRoom);
        expect(room.width, 20);
        expect(room.height, 12);
        expect(room.parentId, isNull);
        expect(room.devices, isEmpty);
        expect(room.doors, isEmpty);
        expect(room.cloudServices, isEmpty);
        expect(room.regionCode, isNull);
      });

      test('serverRoom factory creates correct type', () {
        final serverRoom = RoomModel.serverRoom(
          id: 'sr-1',
          name: 'My Server Room',
        );

        expect(serverRoom.id, 'sr-1');
        expect(serverRoom.name, 'My Server Room');
        expect(serverRoom.type, RoomType.serverRoom);
        expect(serverRoom.parentId, isNull);
      });

      test('provider factory creates correct type', () {
        final awsRoom = RoomModel.provider(
          id: 'aws-1',
          type: RoomType.aws,
          name: 'AWS',
          parentId: 'root-1',
        );

        expect(awsRoom.id, 'aws-1');
        expect(awsRoom.name, 'AWS');
        expect(awsRoom.type, RoomType.aws);
        expect(awsRoom.parentId, 'root-1');
      });

      test('region factory creates correct type', () {
        final regionRoom = RoomModel.region(
          id: 'region-1',
          name: 'us-east-1',
          parentId: 'aws-1',
          regionCode: 'us-east-1',
          type: RoomType.aws,
        );

        expect(regionRoom.id, 'region-1');
        expect(regionRoom.name, 'us-east-1');
        expect(regionRoom.parentId, 'aws-1');
        expect(regionRoom.regionCode, 'us-east-1');
        expect(regionRoom.type, RoomType.aws);
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = room.toJson();

        expect(json['id'], 'room-1');
        expect(json['name'], 'Test Room');
        expect(json['type'], 'serverRoom');
        expect(json['width'], 20);
        expect(json['height'], 12);
        expect(json['parentId'], isNull);
        expect(json['devices'], isEmpty);
        expect(json['doors'], isEmpty);
        expect(json['cloudServices'], isEmpty);
      });

      test('fromJson produces correct model', () {
        final json = room.toJson();
        final restored = RoomModel.fromJson(json);

        expect(restored.id, room.id);
        expect(restored.name, room.name);
        expect(restored.type, room.type);
        expect(restored.width, room.width);
        expect(restored.height, room.height);
      });

      test('fromJson handles missing optional fields with defaults', () {
        final json = {'id': 'room-2', 'name': 'Minimal Room'};

        final restored = RoomModel.fromJson(json);

        expect(restored.id, 'room-2');
        expect(restored.name, 'Minimal Room');
        expect(restored.type, RoomType.serverRoom);
        expect(restored.width, GameConstants.roomWidth);
        expect(restored.height, GameConstants.roomHeight);
        expect(restored.devices, isEmpty);
        expect(restored.doors, isEmpty);
        expect(restored.cloudServices, isEmpty);
      });

      test('round-trip serialization with nested objects', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(3, 3),
        );
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        const service = CloudServiceModel(
          id: 'service-1',
          name: 'EC2 Instance',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );

        final fullRoom = room.copyWith(
          devices: [device],
          doors: [door],
          cloudServices: [service],
          regionCode: 'us-west-2',
        );

        final json = fullRoom.toJson();
        final restored = RoomModel.fromJson(json);

        expect(restored.devices.length, 1);
        expect(restored.devices.first.id, 'dev-1');
        expect(restored.doors.length, 1);
        expect(restored.doors.first.id, 'door-1');
        expect(restored.cloudServices.length, 1);
        expect(restored.cloudServices.first.id, 'service-1');
        expect(restored.regionCode, 'us-west-2');
      });

      test('round-trip serialization preserves origin terminal position', () {
        final roomWithOriginTerminal = room.copyWith(
          terminalPosition: const GridPosition(0, 0),
        );

        final restored = RoomModel.fromJson(roomWithOriginTerminal.toJson());

        expect(restored.terminalPosition, const GridPosition(0, 0));
      });

      test('round-trip serialization preserves boundary terminal positions', () {
        final positions = [
          const GridPosition(0, 0),
          const GridPosition(19, 0),
          const GridPosition(0, 11),
          const GridPosition(19, 11),
        ];

        for (final pos in positions) {
          final roomWithTerminal = room.copyWith(terminalPosition: pos);
          final restored = RoomModel.fromJson(roomWithTerminal.toJson());

          expect(restored.terminalPosition, pos);
        }
      });

      test('round-trip serialization preserves devices at boundary positions', () {
        const deviceAtOrigin = DeviceModel(
          id: 'dev-origin',
          templateId: 'tmpl-origin',
          name: 'Origin Device',
          type: DeviceType.server,
          position: GridPosition(0, 0),
        );
        const deviceAtCorner = DeviceModel(
          id: 'dev-corner',
          templateId: 'tmpl-corner',
          name: 'Corner Device',
          type: DeviceType.nas,
          position: GridPosition(19, 11),
        );

        final roomWithDevices = room.copyWith(
          devices: [deviceAtOrigin, deviceAtCorner],
        );

        final restored = RoomModel.fromJson(roomWithDevices.toJson());

        expect(restored.devices.length, 2);
        expect(restored.devices[0].position, const GridPosition(0, 0));
        expect(restored.devices[1].position, const GridPosition(19, 11));
      });

      test('round-trip serialization preserves cloud services at boundary positions', () {
        const serviceAtOrigin = CloudServiceModel(
          id: 'svc-origin',
          name: 'Origin Service',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(0, 0),
        );
        const serviceAtCorner = CloudServiceModel(
          id: 'svc-corner',
          name: 'Corner Service',
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          serviceType: 'CloudStorage',
          position: GridPosition(19, 11),
        );

        final roomWithServices = room.copyWith(
          cloudServices: [serviceAtOrigin, serviceAtCorner],
        );

        final restored = RoomModel.fromJson(roomWithServices.toJson());

        expect(restored.cloudServices.length, 2);
        expect(restored.cloudServices[0].position, const GridPosition(0, 0));
        expect(restored.cloudServices[1].position, const GridPosition(19, 11));
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final modified = room.copyWith(name: 'New Name', type: RoomType.aws);

        expect(modified.name, 'New Name');
        expect(modified.type, RoomType.aws);
        expect(modified.id, room.id);
        expect(modified.width, room.width);
      });

      test('clearParentId sets parentId to null', () {
        final withParent = room.copyWith(parentId: 'parent-1');
        expect(withParent.parentId, 'parent-1');

        final cleared = withParent.copyWith(clearParentId: true);
        expect(cleared.parentId, isNull);
      });

      test('clearRegionCode sets regionCode to null', () {
        final withRegion = room.copyWith(regionCode: 'us-east-1');
        expect(withRegion.regionCode, 'us-east-1');

        final cleared = withRegion.copyWith(clearRegionCode: true);
        expect(cleared.regionCode, isNull);
      });
    });

    group('cell occupancy', () {
      late DeviceModel device;
      late CloudServiceModel service;

      setUp(() {
        device = const DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
          width: 2,
          height: 2,
        );
        service = const CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
          width: 1,
          height: 1,
        );
      });

      test('isCellOccupied returns true for device cells', () {
        final roomWithDevice = room.addDevice(device);

        expect(roomWithDevice.isCellOccupied(const GridPosition(5, 5)), isTrue);
        expect(roomWithDevice.isCellOccupied(const GridPosition(6, 5)), isTrue);
        expect(roomWithDevice.isCellOccupied(const GridPosition(5, 6)), isTrue);
        expect(roomWithDevice.isCellOccupied(const GridPosition(6, 6)), isTrue);
        expect(
          roomWithDevice.isCellOccupied(const GridPosition(4, 5)),
          isFalse,
        );
        expect(
          roomWithDevice.isCellOccupied(const GridPosition(7, 5)),
          isFalse,
        );
      });

      test('isCellOccupied returns true for service cells', () {
        final roomWithService = room.addCloudService(service);

        expect(
          roomWithService.isCellOccupied(const GridPosition(10, 10)),
          isTrue,
        );
        expect(
          roomWithService.isCellOccupied(const GridPosition(10, 11)),
          isFalse,
        );
      });

      test('getDeviceAt returns correct device', () {
        final roomWithDevice = room.addDevice(device);

        expect(
          roomWithDevice.getDeviceAt(const GridPosition(5, 5))?.id,
          'dev-1',
        );
        expect(
          roomWithDevice.getDeviceAt(const GridPosition(6, 6))?.id,
          'dev-1',
        );
        expect(roomWithDevice.getDeviceAt(const GridPosition(4, 4)), isNull);
      });

      test('getCloudServiceAt returns correct service', () {
        final roomWithService = room.addCloudService(service);

        expect(
          roomWithService.getCloudServiceAt(const GridPosition(10, 10))?.id,
          'svc-1',
        );
        expect(
          roomWithService.getCloudServiceAt(const GridPosition(11, 11)),
          isNull,
        );
      });
    });

    group('door management', () {
      test('hasDoorAt returns true for door position', () {
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        final roomWithDoor = room.addDoor(door);

        // Right wall at position 5 in a 20-width room = GridPosition(19, 5)
        expect(roomWithDoor.hasDoorAt(const GridPosition(19, 5)), isTrue);
        expect(roomWithDoor.hasDoorAt(const GridPosition(19, 6)), isFalse);
      });

      test('getDoorAt returns correct door', () {
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.top,
          wallPosition: 10,
        );
        final roomWithDoor = room.addDoor(door);

        // Top wall at position 10 = GridPosition(10, 0)
        expect(roomWithDoor.getDoorAt(const GridPosition(10, 0))?.id, 'door-1');
        expect(roomWithDoor.getDoorAt(const GridPosition(10, 1)), isNull);
      });

      test('addDoor adds door to list', () {
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 8,
        );

        final roomWithDoor = room.addDoor(door);

        expect(roomWithDoor.doors.length, 1);
        expect(roomWithDoor.doors.first.id, 'door-1');
      });

      test('removeDoor removes door from list', () {
        const door1 = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.bottom,
          wallPosition: 8,
        );
        const door2 = DoorModel(
          id: 'door-2',
          targetRoomId: 'room-3',
          wallSide: WallSide.left,
          wallPosition: 5,
        );

        final roomWithDoors = room.addDoor(door1).addDoor(door2);
        expect(roomWithDoors.doors.length, 2);

        final roomAfterRemove = roomWithDoors.removeDoor('door-1');
        expect(roomAfterRemove.doors.length, 1);
        expect(roomAfterRemove.doors.first.id, 'door-2');
      });
    });

    group('device management', () {
      test('addDevice adds device to list', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );

        final roomWithDevice = room.addDevice(device);

        expect(roomWithDevice.devices.length, 1);
        expect(roomWithDevice.devices.first.id, 'dev-1');
      });

      test('removeDevice removes device from list', () {
        const device1 = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const device2 = DeviceModel(
          id: 'dev-2',
          templateId: 'router-template',
          name: 'Router 1',
          type: DeviceType.router,
          position: GridPosition(8, 8),
        );

        final roomWithDevices = room.addDevice(device1).addDevice(device2);
        expect(roomWithDevices.devices.length, 2);

        final roomAfterRemove = roomWithDevices.removeDevice('dev-1');
        expect(roomAfterRemove.devices.length, 1);
        expect(roomAfterRemove.devices.first.id, 'dev-2');
      });
    });

    group('cloud service management', () {
      test('addCloudService adds service to list', () {
        const service = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
        );

        final roomWithService = room.addCloudService(service);

        expect(roomWithService.cloudServices.length, 1);
        expect(roomWithService.cloudServices.first.id, 'svc-1');
      });

      test('removeCloudService removes service from list', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
        );
        const service2 = CloudServiceModel(
          id: 'svc-2',
          name: 'S3',
          provider: CloudProvider.aws,
          category: ServiceCategory.storage,
          serviceType: 'S3',
          position: GridPosition(12, 10),
        );

        final roomWithServices = room
            .addCloudService(service1)
            .addCloudService(service2);
        expect(roomWithServices.cloudServices.length, 2);

        final roomAfterRemove = roomWithServices.removeCloudService('svc-1');
        expect(roomAfterRemove.cloudServices.length, 1);
        expect(roomAfterRemove.cloudServices.first.id, 'svc-2');
      });
    });

    group('canPlaceDevice', () {
      test('returns true for valid empty position', () {
        expect(room.canPlaceDevice(const GridPosition(5, 5), 1, 1), isTrue);
        expect(room.canPlaceDevice(const GridPosition(5, 5), 2, 2), isTrue);
      });

      test('returns false for out of bounds position', () {
        expect(room.canPlaceDevice(const GridPosition(19, 5), 2, 1), isFalse);
        expect(room.canPlaceDevice(const GridPosition(5, 11), 1, 2), isFalse);
        expect(room.canPlaceDevice(const GridPosition(-1, 5), 1, 1), isFalse);
      });

      test('returns false for occupied position', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
          width: 2,
          height: 2,
        );
        final roomWithDevice = room.addDevice(device);

        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(5, 5), 1, 1),
          isFalse,
        );
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(4, 4), 2, 2),
          isFalse,
        );
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(8, 8), 1, 1),
          isTrue,
        );
      });

      test('returns false for terminal position', () {
        expect(room.canPlaceDevice(const GridPosition(2, 2), 1, 1), isFalse);
        expect(room.canPlaceDevice(const GridPosition(1, 1), 2, 2), isFalse);
      });

      test('returns false for door position', () {
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        final roomWithDoor = room.addDoor(door);

        // Right wall at position 5 in 20-width room = GridPosition(19, 5)
        expect(
          roomWithDoor.canPlaceDevice(const GridPosition(18, 5), 2, 1),
          isFalse,
        );
      });

      test(
        'returns true for exact boundary placement (device fits exactly)',
        () {
          // Room is 20x12, so max valid position for 1x1 is (19, 11)
          expect(room.canPlaceDevice(const GridPosition(19, 11), 1, 1), isTrue);
          // Max valid position for 2x2 is (18, 10)
          expect(room.canPlaceDevice(const GridPosition(18, 10), 2, 2), isTrue);
        },
      );

      test('returns false when device extends one cell beyond boundary', () {
        // Device at (19, 11) with width 2 extends to x=20 (out of bounds)
        expect(room.canPlaceDevice(const GridPosition(19, 11), 2, 1), isFalse);
        // Device at (18, 11) with height 2 extends to y=12 (out of bounds)
        expect(room.canPlaceDevice(const GridPosition(18, 11), 1, 2), isFalse);
      });

      test('returns false for position at origin (0, 0) when valid', () {
        // Origin should be valid unless something is there
        expect(room.canPlaceDevice(const GridPosition(0, 0), 1, 1), isTrue);
      });

      test('returns false for cloud service occupation', () {
        const service = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
        );
        final roomWithService = room.addCloudService(service);

        expect(
          roomWithService.canPlaceDevice(const GridPosition(10, 10), 1, 1),
          isFalse,
        );
        // Adjacent should be fine
        expect(
          roomWithService.canPlaceDevice(const GridPosition(11, 10), 1, 1),
          isTrue,
        );
      });

      test('returns false for large device overlapping multiple obstacles', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const service = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(8, 5),
        );
        final roomWithBoth = room.addDevice(device).addCloudService(service);

        // 4x1 device from (4, 5) to (7, 5) would hit the device at (5,5)
        expect(
          roomWithBoth.canPlaceDevice(const GridPosition(4, 5), 4, 1),
          isFalse,
        );
        // 5x1 device from (4, 5) to (8, 5) would hit both
        expect(
          roomWithBoth.canPlaceDevice(const GridPosition(4, 5), 5, 1),
          isFalse,
        );
      });

      test('returns true for placement adjacent to obstacles', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server',
          type: DeviceType.server,
          position: GridPosition(5, 5),
          width: 2,
          height: 2,
        );
        final roomWithDevice = room.addDevice(device);

        // Just below the device (y=7)
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(5, 7), 2, 2),
          isTrue,
        );
        // Just to the right of the device (x=7)
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(7, 5), 2, 2),
          isTrue,
        );
        // Just above the device (y=3)
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(5, 3), 2, 2),
          isTrue,
        );
        // Just to the left of the device (x=3)
        expect(
          roomWithDevice.canPlaceDevice(const GridPosition(3, 5), 2, 2),
          isTrue,
        );
      });
    });

    group('object counts', () {
      test('getObjectCounts returns correct counts', () {
        const device1 = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const device2 = DeviceModel(
          id: 'dev-2',
          templateId: 'server-template',
          name: 'Server 2',
          type: DeviceType.server,
          position: GridPosition(7, 5),
        );
        const device3 = DeviceModel(
          id: 'dev-3',
          templateId: 'router-template',
          name: 'Router 1',
          type: DeviceType.router,
          position: GridPosition(9, 5),
        );
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
        );
        const service2 = CloudServiceModel(
          id: 'svc-2',
          name: 'EC2 2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(12, 10),
        );
        const service3 = CloudServiceModel(
          id: 'svc-3',
          name: 'Droplet',
          provider: CloudProvider.digitalOcean,
          category: ServiceCategory.compute,
          serviceType: 'Droplet',
          position: GridPosition(14, 10),
        );

        final fullRoom = room
            .addDevice(device1)
            .addDevice(device2)
            .addDevice(device3)
            .addCloudService(service1)
            .addCloudService(service2)
            .addCloudService(service3);

        final counts = fullRoom.getObjectCounts();

        expect(counts['device:server'], 2);
        expect(counts['device:router'], 1);
        expect(counts['aws:EC2'], 2);
        expect(counts['digitalOcean:Droplet'], 1);
      });

      test('totalObjectCount returns correct total', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'server-template',
          name: 'Server 1',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const service = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(10, 10),
        );

        final fullRoom = room.addDevice(device).addCloudService(service);

        expect(fullRoom.totalObjectCount, 2);
      });
    });

    group('equality', () {
      test('equal rooms are equal', () {
        const room1 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        const room2 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );

        expect(room1, room2);
      });

      test('different rooms are not equal', () {
        const room1 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        final room2 = room1.copyWith(name: 'Different');

        expect(room1, isNot(room2));
      });

      test('equal rooms have same hashCode', () {
        const room1 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        const room2 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );

        expect(room1.hashCode, room2.hashCode);
      });

      test('rooms can be used in Set collections', () {
        const room1 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        const room2 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        const room3 = RoomModel(
          id: 'room-3',
          name: 'Other Room',
          type: RoomType.aws,
        );

        final roomSet = {room1, room2, room3};
        expect(roomSet.length, 2);
        expect(roomSet.contains(room1), isTrue);
        expect(roomSet.contains(room3), isTrue);
      });

      test('rooms can be used as Map keys', () {
        const room1 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );
        const room2 = RoomModel(
          id: 'room-1',
          name: 'Test Room',
          type: RoomType.serverRoom,
        );

        final roomMap = <RoomModel, String>{room1: 'first'};
        roomMap[room2] = 'second';

        expect(roomMap.length, 1);
        expect(roomMap[room1], 'second');
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final str = room.toString();
        expect(str, contains('RoomModel'));
        expect(str, contains(room.id));
        expect(str, contains(room.name));
        expect(str, contains('RoomType.serverRoom'));
      });

      test('includes device and door counts', () {
        const device = DeviceModel(
          id: 'dev-1',
          templateId: 'tmpl',
          name: 'Server',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const door = DoorModel(
          id: 'door-1',
          targetRoomId: 'room-2',
          wallSide: WallSide.right,
          wallPosition: 5,
        );
        final fullRoom = room.addDevice(device).addDoor(door);
        final str = fullRoom.toString();
        expect(str, contains('devices: 1'));
        expect(str, contains('doors: 1'));
      });
    });
  });
}
