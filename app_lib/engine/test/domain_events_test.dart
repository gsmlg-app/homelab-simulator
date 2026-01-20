import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('DomainEvent', () {
    group('PlayerMoved', () {
      test('equal events are equal', () {
        const event1 = PlayerMoved(GridPosition(5, 5));
        const event2 = PlayerMoved(GridPosition(5, 5));
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different positions are not equal', () {
        const event1 = PlayerMoved(GridPosition(5, 5));
        const event2 = PlayerMoved(GridPosition(6, 5));
        expect(event1, isNot(event2));
      });

      test('props contains newPosition', () {
        const event = PlayerMoved(GridPosition(3, 4));
        expect(event.props, [const GridPosition(3, 4)]);
      });
    });

    group('ShopToggled', () {
      test('equal events are equal', () {
        const event1 = ShopToggled(true);
        const event2 = ShopToggled(true);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different values are not equal', () {
        const event1 = ShopToggled(true);
        const event2 = ShopToggled(false);
        expect(event1, isNot(event2));
      });

      test('props contains isOpen', () {
        const event = ShopToggled(true);
        expect(event.props, [true]);
      });
    });

    group('TemplateSelected', () {
      const template1 = DeviceTemplate(
        id: 'server_basic',
        name: 'Basic Server',
        description: 'A simple server',
        type: DeviceType.server,
        cost: 500,
      );
      const template2 = DeviceTemplate(
        id: 'server_basic',
        name: 'Basic Server',
        description: 'A simple server',
        type: DeviceType.server,
        cost: 500,
      );
      const template3 = DeviceTemplate(
        id: 'router_basic',
        name: 'Basic Router',
        description: 'A simple router',
        type: DeviceType.router,
        cost: 200,
      );

      test('equal events are equal', () {
        const event1 = TemplateSelected(template1);
        const event2 = TemplateSelected(template2);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different templates are not equal', () {
        const event1 = TemplateSelected(template1);
        const event2 = TemplateSelected(template3);
        expect(event1, isNot(event2));
      });

      test('props contains template', () {
        const event = TemplateSelected(template1);
        expect(event.props, [template1]);
      });
    });

    group('PlacementModeChanged', () {
      test('equal events are equal', () {
        const event1 = PlacementModeChanged(PlacementMode.placing);
        const event2 = PlacementModeChanged(PlacementMode.placing);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different modes are not equal', () {
        const event1 = PlacementModeChanged(PlacementMode.placing);
        const event2 = PlacementModeChanged(PlacementMode.none);
        expect(event1, isNot(event2));
      });

      test('props contains mode', () {
        const event = PlacementModeChanged(PlacementMode.placing);
        expect(event.props, [PlacementMode.placing]);
      });
    });

    group('DevicePlaced', () {
      test('equal events are equal', () {
        const event1 = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        const event2 = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different templateId are not equal', () {
        const event1 = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        const event2 = DevicePlaced(
          templateId: 'router_basic',
          position: GridPosition(5, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different position are not equal', () {
        const event1 = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(5, 5),
        );
        const event2 = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(6, 6),
        );
        expect(event1, isNot(event2));
      });

      test('props contains templateId and position', () {
        const event = DevicePlaced(
          templateId: 'server_basic',
          position: GridPosition(3, 4),
        );
        expect(event.props, ['server_basic', const GridPosition(3, 4)]);
      });
    });

    group('DeviceRemoved', () {
      test('equal events are equal', () {
        const event1 = DeviceRemoved('dev-1');
        const event2 = DeviceRemoved('dev-1');
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different deviceId are not equal', () {
        const event1 = DeviceRemoved('dev-1');
        const event2 = DeviceRemoved('dev-2');
        expect(event1, isNot(event2));
      });

      test('props contains deviceId', () {
        const event = DeviceRemoved('dev-1');
        expect(event.props, ['dev-1']);
      });
    });

    group('CreditsChanged', () {
      test('equal events are equal', () {
        const event1 = CreditsChanged(100);
        const event2 = CreditsChanged(100);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different amounts are not equal', () {
        const event1 = CreditsChanged(100);
        const event2 = CreditsChanged(-50);
        expect(event1, isNot(event2));
      });

      test('props contains amount', () {
        const event = CreditsChanged(100);
        expect(event.props, [100]);
      });
    });

    group('GameModeChanged', () {
      test('equal events are equal', () {
        const event1 = GameModeChanged(GameMode.live);
        const event2 = GameModeChanged(GameMode.live);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different modes are not equal', () {
        const event1 = GameModeChanged(GameMode.live);
        const event2 = GameModeChanged(GameMode.sim);
        expect(event1, isNot(event2));
      });

      test('props contains mode', () {
        const event = GameModeChanged(GameMode.live);
        expect(event.props, [GameMode.live]);
      });
    });

    group('GameLoaded', () {
      test('equal events are equal', () {
        const event1 = GameLoaded();
        const event2 = GameLoaded();
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('props is empty', () {
        const event = GameLoaded();
        expect(event.props, isEmpty);
      });
    });

    group('RoomEntered', () {
      test('equal events are equal', () {
        const event1 = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(2, 5),
        );
        const event2 = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(2, 5),
        );
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different roomId are not equal', () {
        const event1 = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(2, 5),
        );
        const event2 = RoomEntered(
          roomId: 'room-2',
          spawnPosition: GridPosition(2, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different spawnPosition are not equal', () {
        const event1 = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(2, 5),
        );
        const event2 = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(3, 6),
        );
        expect(event1, isNot(event2));
      });

      test('props contains roomId and spawnPosition', () {
        const event = RoomEntered(
          roomId: 'room-1',
          spawnPosition: GridPosition(2, 5),
        );
        expect(event.props, ['room-1', const GridPosition(2, 5)]);
      });
    });

    group('RoomAdded', () {
      test('equal events are equal', () {
        const event1 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('equal events with regionCode are equal', () {
        const event1 = RoomAdded(
          name: 'us-east-1',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.bottom,
          doorPosition: 8,
        );
        const event2 = RoomAdded(
          name: 'us-east-1',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.bottom,
          doorPosition: 8,
        );
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different name are not equal', () {
        const event1 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'GCP',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event1, isNot(event2));
      });

      test('events with different type are not equal', () {
        const event1 = RoomAdded(
          name: 'Cloud',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'Cloud',
          type: RoomType.gcp,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event1, isNot(event2));
      });

      test('events with different regionCode are not equal', () {
        const event1 = RoomAdded(
          name: 'Region',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'Region',
          type: RoomType.aws,
          regionCode: 'us-west-2',
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event1, isNot(event2));
      });

      test('events with different doorSide are not equal', () {
        const event1 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.left,
          doorPosition: 5,
        );
        expect(event1, isNot(event2));
      });

      test('events with different doorPosition are not equal', () {
        const event1 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        const event2 = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          doorSide: WallSide.right,
          doorPosition: 8,
        );
        expect(event1, isNot(event2));
      });

      test('props contains all fields', () {
        const event = RoomAdded(
          name: 'AWS',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.right,
          doorPosition: 5,
        );
        expect(event.props, ['AWS', RoomType.aws, 'us-east-1', WallSide.right, 5]);
      });
    });

    group('RoomRemoved', () {
      test('equal events are equal', () {
        const event1 = RoomRemoved('room-1');
        const event2 = RoomRemoved('room-1');
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different roomId are not equal', () {
        const event1 = RoomRemoved('room-1');
        const event2 = RoomRemoved('room-2');
        expect(event1, isNot(event2));
      });

      test('props contains roomId', () {
        const event = RoomRemoved('room-1');
        expect(event.props, ['room-1']);
      });
    });

    group('CloudServiceSelected', () {
      const template1 = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2 Instance',
        description: 'Virtual compute',
      );
      const template2 = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2 Instance',
        description: 'Virtual compute',
      );
      const template3 = CloudServiceTemplate(
        provider: CloudProvider.gcp,
        category: ServiceCategory.compute,
        serviceType: 'ComputeEngine',
        name: 'Compute Engine',
        description: 'GCP compute',
      );

      test('equal events are equal', () {
        const event1 = CloudServiceSelected(template1);
        const event2 = CloudServiceSelected(template2);
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different templates are not equal', () {
        const event1 = CloudServiceSelected(template1);
        const event2 = CloudServiceSelected(template3);
        expect(event1, isNot(event2));
      });

      test('props contains template', () {
        const event = CloudServiceSelected(template1);
        expect(event.props, [template1]);
      });
    });

    group('CloudServicePlaced', () {
      test('equal events are equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different provider are not equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.gcp,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different category are not equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.storage,
          serviceType: 'EC2',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different serviceType are not equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'Lambda',
          name: 'My Service',
          position: GridPosition(5, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different name are not equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'Other EC2',
          position: GridPosition(5, 5),
        );
        expect(event1, isNot(event2));
      });

      test('events with different position are not equal', () {
        const event1 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );
        const event2 = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(6, 6),
        );
        expect(event1, isNot(event2));
      });

      test('props contains all fields', () {
        const event = CloudServicePlaced(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'My EC2',
          position: GridPosition(5, 5),
        );
        expect(event.props, [
          CloudProvider.aws,
          ServiceCategory.compute,
          'EC2',
          'My EC2',
          const GridPosition(5, 5),
        ]);
      });
    });

    group('CloudServiceRemoved', () {
      test('equal events are equal', () {
        const event1 = CloudServiceRemoved('svc-1');
        const event2 = CloudServiceRemoved('svc-1');
        expect(event1, event2);
        expect(event1.hashCode, event2.hashCode);
      });

      test('events with different serviceId are not equal', () {
        const event1 = CloudServiceRemoved('svc-1');
        const event2 = CloudServiceRemoved('svc-2');
        expect(event1, isNot(event2));
      });

      test('props contains serviceId', () {
        const event = CloudServiceRemoved('svc-1');
        expect(event.props, ['svc-1']);
      });
    });

    group('Event type distinction', () {
      test('different event types with same props are not equal', () {
        // DeviceRemoved and RoomRemoved both take a string ID
        const deviceRemoved = DeviceRemoved('id-1');
        const roomRemoved = RoomRemoved('id-1');
        expect(deviceRemoved, isNot(roomRemoved));
      });

      test('ShopToggled and PlacementModeChanged are not equal', () {
        // Both have single bool-like props
        const shopToggled = ShopToggled(true);
        const placementMode = PlacementModeChanged(PlacementMode.placing);
        expect(shopToggled, isNot(placementMode));
      });

      test('CreditsChanged instances with different amounts are distinct', () {
        const credit100 = CreditsChanged(100);
        const creditNeg100 = CreditsChanged(-100);
        expect(credit100, isNot(creditNeg100));
        expect(credit100.amount, 100);
        expect(creditNeg100.amount, -100);
      });
    });
  });
}
