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
          tileSize: 32.0,
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
          tileSize: 32.0,
        );

        // Default service is 1x1
        expect(component.size, Vector2(32.0, 32.0));
      });

      test('respects service dimensions', () {
        final component = CloudServiceComponent(
          service: gcpService,
          tileSize: 32.0,
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
    });
  });
}
