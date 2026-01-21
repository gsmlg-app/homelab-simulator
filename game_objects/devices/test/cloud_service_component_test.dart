import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_objects_devices/game_objects_devices.dart';

void main() {
  group('CloudServiceComponent', () {
    late CloudServiceModel awsService;
    late CloudServiceModel gcpService;
    late CloudServiceModel cloudflareService;

    setUp(() {
      awsService = const CloudServiceModel(
        id: 'service-1',
        name: 'AWS EC2 Instance',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        position: GridPosition(5, 3),
      );

      gcpService = const CloudServiceModel(
        id: 'service-2',
        name: 'GCP Cloud Storage',
        provider: CloudProvider.gcp,
        category: ServiceCategory.storage,
        serviceType: 'CloudStorage',
        position: GridPosition(10, 8),
        width: 2,
        height: 2,
      );

      cloudflareService = const CloudServiceModel(
        id: 'service-3',
        name: 'Cloudflare Workers',
        provider: CloudProvider.cloudflare,
        category: ServiceCategory.serverless,
        serviceType: 'Workers',
        position: GridPosition(0, 0),
      );
    });

    group('constructor', () {
      test('stores service model', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service, awsService);
      });

      test('uses default tile size from GameConstants', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.tileSize, GameConstants.tileSize);
      });

      test('accepts custom tile size', () {
        final component = CloudServiceComponent(
          service: awsService,
          tileSize: 64.0,
        );

        expect(component.tileSize, 64.0);
      });
    });

    group('position', () {
      test('initializes from service position and tile size', () {
        const tileSize = 32.0;
        final component = CloudServiceComponent(
          service: awsService,
          tileSize: tileSize,
        );

        // Position (5, 3) * 32 = (160, 96)
        expect(component.position, Vector2(160.0, 96.0));
      });

      test('handles origin position', () {
        final component = CloudServiceComponent(
          service: cloudflareService,
          tileSize: GameConstants.tileSize,
        );

        expect(component.position, Vector2(0, 0));
      });

      test('uses service position for pixel calculation', () {
        final component = CloudServiceComponent(service: gcpService);

        final expectedX = gcpService.position.x * GameConstants.tileSize;
        final expectedY = gcpService.position.y * GameConstants.tileSize;

        expect(component.position, Vector2(expectedX, expectedY));
      });
    });

    group('size', () {
      test('calculates from service width and height', () {
        final component = CloudServiceComponent(
          service: awsService,
          tileSize: GameConstants.tileSize,
        );

        // Default service is 1x1
        expect(component.size, Vector2(32.0, 32.0));
      });

      test('respects service dimensions', () {
        final component = CloudServiceComponent(
          service: gcpService,
          tileSize: GameConstants.tileSize,
        );

        // 2x2 service
        expect(component.size, Vector2(64.0, 64.0));
      });

      test('scales with custom tile size', () {
        final component = CloudServiceComponent(
          service: awsService,
          tileSize: 64.0,
        );

        expect(component.size, Vector2(64.0, 64.0));
      });
    });

    group('service properties', () {
      test('service id is accessible', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.id, 'service-1');
      });

      test('service name is accessible', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.name, 'AWS EC2 Instance');
      });

      test('service provider is accessible', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.provider, CloudProvider.aws);
      });

      test('service category is accessible', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.category, ServiceCategory.compute);
      });

      test('service serviceType is accessible', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.serviceType, 'EC2');
      });
    });

    group('cloud providers', () {
      test('supports AWS', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.provider, CloudProvider.aws);
      });

      test('supports GCP', () {
        final component = CloudServiceComponent(service: gcpService);

        expect(component.service.provider, CloudProvider.gcp);
      });

      test('supports Cloudflare', () {
        final component = CloudServiceComponent(service: cloudflareService);

        expect(component.service.provider, CloudProvider.cloudflare);
      });
    });

    group('service categories', () {
      test('supports compute', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.service.category, ServiceCategory.compute);
      });

      test('supports storage', () {
        final component = CloudServiceComponent(service: gcpService);

        expect(component.service.category, ServiceCategory.storage);
      });

      test('supports serverless', () {
        final component = CloudServiceComponent(service: cloudflareService);

        expect(component.service.category, ServiceCategory.serverless);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component, isA<PositionComponent>());
      });

      test('can have priority set', () {
        final component = CloudServiceComponent(service: awsService);
        component.priority = 10;

        expect(component.priority, 10);
      });

      test('can have anchor set', () {
        final component = CloudServiceComponent(service: awsService);
        component.anchor = Anchor.center;

        expect(component.anchor, Anchor.center);
      });
    });

    group('edge cases', () {
      test('handles service at high position', () {
        const farService = CloudServiceModel(
          id: 'far-service',
          name: 'Far Service',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(100, 100),
        );
        final component = CloudServiceComponent(
          service: farService,
          tileSize: GameConstants.tileSize,
        );

        expect(component.position, Vector2(3200.0, 3200.0));
      });

      test('handles large service dimensions', () {
        const largeService = CloudServiceModel(
          id: 'large-service',
          name: 'Large Service',
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          serviceType: 'Storage',
          position: GridPosition(0, 0),
          width: 5,
          height: 3,
        );
        final component = CloudServiceComponent(
          service: largeService,
          tileSize: GameConstants.tileSize,
        );

        expect(component.size, Vector2(160.0, 96.0));
      });

      test('handles Azure provider', () {
        const azureService = CloudServiceModel(
          id: 'azure-1',
          name: 'Azure Blob',
          provider: CloudProvider.azure,
          category: ServiceCategory.storage,
          serviceType: 'Blob',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: azureService);

        expect(component.service.provider, CloudProvider.azure);
      });

      test('handles DigitalOcean provider', () {
        const doService = CloudServiceModel(
          id: 'do-1',
          name: 'DO Droplet',
          provider: CloudProvider.digitalOcean,
          category: ServiceCategory.compute,
          serviceType: 'Droplet',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: doService);

        expect(component.service.provider, CloudProvider.digitalOcean);
      });

      test('handles Vultr provider', () {
        const vultrService = CloudServiceModel(
          id: 'vultr-1',
          name: 'Vultr Instance',
          provider: CloudProvider.vultr,
          category: ServiceCategory.compute,
          serviceType: 'Instance',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: vultrService);

        expect(component.service.provider, CloudProvider.vultr);
      });

      test('handles database category', () {
        const dbService = CloudServiceModel(
          id: 'db-1',
          name: 'RDS Database',
          provider: CloudProvider.aws,
          category: ServiceCategory.database,
          serviceType: 'RDS',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: dbService);

        expect(component.service.category, ServiceCategory.database);
      });

      test('handles networking category', () {
        const netService = CloudServiceModel(
          id: 'net-1',
          name: 'VPC',
          provider: CloudProvider.aws,
          category: ServiceCategory.networking,
          serviceType: 'VPC',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: netService);

        expect(component.service.category, ServiceCategory.networking);
      });

      test('handles container category', () {
        const containerService = CloudServiceModel(
          id: 'container-1',
          name: 'EKS Cluster',
          provider: CloudProvider.aws,
          category: ServiceCategory.container,
          serviceType: 'EKS',
          position: GridPosition(0, 0),
        );
        final component = CloudServiceComponent(service: containerService);

        expect(component.service.category, ServiceCategory.container);
      });

      test('default anchor is top left', () {
        final component = CloudServiceComponent(service: awsService);

        expect(component.anchor, Anchor.topLeft);
      });
    });

    group('position manipulation', () {
      test('initial position uses service grid position', () {
        final component = CloudServiceComponent(
          service: awsService,
          tileSize: GameConstants.tileSize,
        );

        expect(component.position.x, 160.0); // 5 * 32
        expect(component.position.y, 96.0); // 3 * 32
      });

      test('position can be modified', () {
        final component = CloudServiceComponent(service: awsService);
        component.position = Vector2(500, 600);

        expect(component.position, Vector2(500, 600));
      });
    });
  });
}
