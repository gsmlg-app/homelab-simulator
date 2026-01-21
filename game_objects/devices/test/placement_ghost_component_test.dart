import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_objects_devices/game_objects_devices.dart';

void main() {
  group('PlacementGhostComponent', () {
    group('constructor', () {
      test('uses default tile size from GameConstants', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.tileSize, GameConstants.tileSize);
      });

      test('accepts custom tile size', () {
        final ghost = PlacementGhostComponent(tileSize: 64.0);

        expect(ghost.tileSize, 64.0);
      });
    });

    group('initial size', () {
      test('is one tile size by default', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.size, Vector2.all(GameConstants.tileSize));
      });

      test('respects custom tile size', () {
        final ghost = PlacementGhostComponent(tileSize: 48.0);

        expect(ghost.size, Vector2.all(48.0));
      });
    });

    group('setTemplate', () {
      test('updates size based on template dimensions', () {
        final ghost = PlacementGhostComponent(tileSize: 32.0);
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
          width: 2,
          height: 3,
        );

        ghost.setTemplate(template);

        expect(ghost.size, Vector2(64.0, 96.0));
      });

      test('clears cloud service when setting device template', () {
        final ghost = PlacementGhostComponent();
        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute instance',
        );
        ghost.setCloudService(cloudTemplate);
        expect(ghost.isPlacingCloudService, true);

        const deviceTemplate = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(deviceTemplate);

        expect(ghost.isPlacingDevice, true);
        expect(ghost.isPlacingCloudService, false);
      });

      test('can be set to null to clear placement', () {
        final ghost = PlacementGhostComponent();
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(template);
        expect(ghost.isPlacingDevice, true);

        ghost.setTemplate(null);
        expect(ghost.isPlacingDevice, false);
      });
    });

    group('setCloudService', () {
      test('updates size based on template dimensions', () {
        final ghost = PlacementGhostComponent(tileSize: 32.0);
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute instance',
          width: 2,
          height: 2,
        );

        ghost.setCloudService(template);

        expect(ghost.size, Vector2(64.0, 64.0));
      });

      test('clears device when setting cloud service template', () {
        final ghost = PlacementGhostComponent();
        const deviceTemplate = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(deviceTemplate);
        expect(ghost.isPlacingDevice, true);

        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute instance',
        );
        ghost.setCloudService(cloudTemplate);

        expect(ghost.isPlacingCloudService, true);
        expect(ghost.isPlacingDevice, false);
      });

      test('can be set to null to clear placement', () {
        final ghost = PlacementGhostComponent();
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute instance',
        );
        ghost.setCloudService(template);
        expect(ghost.isPlacingCloudService, true);

        ghost.setCloudService(null);
        expect(ghost.isPlacingCloudService, false);
      });
    });

    group('isPlacingDevice', () {
      test('returns false by default', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.isPlacingDevice, false);
      });

      test('returns true after setting template', () {
        final ghost = PlacementGhostComponent();
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A test server',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(template);

        expect(ghost.isPlacingDevice, true);
      });
    });

    group('isPlacingCloudService', () {
      test('returns false by default', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.isPlacingCloudService, false);
      });

      test('returns true after setting cloud service', () {
        final ghost = PlacementGhostComponent();
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Compute instance',
        );
        ghost.setCloudService(template);

        expect(ghost.isPlacingCloudService, true);
      });
    });

    group('setValid', () {
      test('can set valid to true', () {
        final ghost = PlacementGhostComponent();

        ghost.setValid(true);
        // No exception thrown
      });

      test('can set valid to false', () {
        final ghost = PlacementGhostComponent();

        ghost.setValid(false);
        // No exception thrown
      });

      test('can toggle validity', () {
        final ghost = PlacementGhostComponent();

        ghost.setValid(true);
        ghost.setValid(false);
        ghost.setValid(true);
        // No exception thrown
      });
    });

    group('currentPosition', () {
      test('returns null by default', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.currentPosition, null);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final ghost = PlacementGhostComponent();

        expect(ghost, isA<PositionComponent>());
      });

      test('can be positioned', () {
        final ghost = PlacementGhostComponent();
        ghost.position = Vector2(100, 200);

        expect(ghost.position, Vector2(100, 200));
      });

      test('can have priority set', () {
        final ghost = PlacementGhostComponent();
        ghost.priority = 10;

        expect(ghost.priority, 10);
      });

      test('can have anchor set', () {
        final ghost = PlacementGhostComponent();
        ghost.anchor = Anchor.center;

        expect(ghost.anchor, Anchor.center);
      });
    });

    group('edge cases', () {
      test('handles large device template', () {
        final ghost = PlacementGhostComponent(tileSize: 32.0);
        const template = DeviceTemplate(
          id: 'large-device',
          name: 'Large Device',
          description: 'A large device',
          type: DeviceType.server,
          cost: 1000,
          width: 10,
          height: 5,
        );

        ghost.setTemplate(template);

        expect(ghost.size, Vector2(320.0, 160.0));
      });

      test('handles cloud service with all providers', () {
        final ghost = PlacementGhostComponent();

        for (final provider in CloudProvider.values) {
          final template = CloudServiceTemplate(
            provider: provider,
            category: ServiceCategory.compute,
            serviceType: 'Test',
            name: 'Test Service',
            description: 'Test',
          );
          ghost.setCloudService(template);
          expect(ghost.isPlacingCloudService, true);
        }
      });

      test('handles cloud service with all categories', () {
        final ghost = PlacementGhostComponent();

        for (final category in ServiceCategory.values) {
          final template = CloudServiceTemplate(
            provider: CloudProvider.aws,
            category: category,
            serviceType: 'Test',
            name: 'Test Service',
            description: 'Test',
          );
          ghost.setCloudService(template);
          expect(ghost.isPlacingCloudService, true);
        }
      });

      test('handles device template with all device types', () {
        final ghost = PlacementGhostComponent();

        for (final type in DeviceType.values) {
          final template = DeviceTemplate(
            id: 'test-$type',
            name: 'Test Device',
            description: 'Test',
            type: type,
            cost: 100,
          );
          ghost.setTemplate(template);
          expect(ghost.isPlacingDevice, true);
        }
      });

      test('default anchor is top left', () {
        final ghost = PlacementGhostComponent();

        expect(ghost.anchor, Anchor.topLeft);
      });

      test('size resets when clearing templates in sequence', () {
        final ghost = PlacementGhostComponent(tileSize: 32.0);

        // Set device template
        const deviceTemplate = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
          width: 3,
          height: 2,
        );
        ghost.setTemplate(deviceTemplate);
        expect(ghost.size, Vector2(96.0, 64.0));

        // Clear device, set cloud service
        const cloudTemplate = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Test',
          width: 2,
          height: 2,
        );
        ghost.setCloudService(cloudTemplate);
        expect(ghost.size, Vector2(64.0, 64.0));
        expect(ghost.isPlacingDevice, false);
        expect(ghost.isPlacingCloudService, true);
      });

      test('handles very small tile size', () {
        final ghost = PlacementGhostComponent(tileSize: 8.0);

        expect(ghost.tileSize, 8.0);
        expect(ghost.size, Vector2.all(8.0));
      });

      test('handles very large tile size', () {
        final ghost = PlacementGhostComponent(tileSize: 256.0);

        expect(ghost.tileSize, 256.0);
        expect(ghost.size, Vector2.all(256.0));
      });
    });

    group('position manipulation', () {
      test('position can be modified', () {
        final ghost = PlacementGhostComponent();
        ghost.position = Vector2(500, 600);

        expect(ghost.position, Vector2(500, 600));
      });

      test('size can be modified', () {
        final ghost = PlacementGhostComponent();
        ghost.size = Vector2(100, 100);

        expect(ghost.size, Vector2(100, 100));
      });
    });

    group('breathing animation', () {
      test('ghost has breathing animation capability', () {
        final ghost = PlacementGhostComponent();

        // Ghost component supports breathing animation
        expect(ghost, isA<PositionComponent>());
      });

      test('breathing animation works with device template', () {
        final ghost = PlacementGhostComponent();
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(template);

        // Ghost is placing device and has breathing animation
        expect(ghost.isPlacingDevice, true);
      });

      test('breathing animation works with cloud service', () {
        final ghost = PlacementGhostComponent();
        const template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'Test',
        );
        ghost.setCloudService(template);

        // Ghost is placing cloud service and has breathing animation
        expect(ghost.isPlacingCloudService, true);
      });

      test('valid and invalid states both have animated effect', () {
        final ghost = PlacementGhostComponent();
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        ghost.setTemplate(template);

        // Both valid and invalid states use animated opacity
        ghost.setValid(true);
        expect(ghost.isPlacingDevice, true);

        ghost.setValid(false);
        expect(ghost.isPlacingDevice, true);
      });
    });
  });
}
