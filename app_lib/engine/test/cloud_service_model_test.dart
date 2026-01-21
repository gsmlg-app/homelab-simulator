import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('CloudServiceModel', () {
    late CloudServiceModel service;

    setUp(() {
      service = const CloudServiceModel(
        id: 'svc-1',
        name: 'My EC2 Instance',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        position: GridPosition(5, 5),
        width: 2,
        height: 1,
        metadata: {'instanceType': 't3.micro'},
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(service.id, 'svc-1');
        expect(service.name, 'My EC2 Instance');
        expect(service.provider, CloudProvider.aws);
        expect(service.category, ServiceCategory.compute);
        expect(service.serviceType, 'EC2');
        expect(service.position, const GridPosition(5, 5));
        expect(service.width, 2);
        expect(service.height, 1);
        expect(service.metadata, {'instanceType': 't3.micro'});
      });

      test('creates with default width and height', () {
        const simple = CloudServiceModel(
          id: 'svc-2',
          name: 'S3 Bucket',
          provider: CloudProvider.aws,
          category: ServiceCategory.storage,
          serviceType: 'S3',
          position: GridPosition(10, 10),
        );

        expect(simple.width, 1);
        expect(simple.height, 1);
        expect(simple.metadata, isEmpty);
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = service.toJson();

        expect(json['id'], 'svc-1');
        expect(json['name'], 'My EC2 Instance');
        expect(json['provider'], 'aws');
        expect(json['category'], 'compute');
        expect(json['serviceType'], 'EC2');
        expect(json['position'], {'x': 5, 'y': 5});
        expect(json['width'], 2);
        expect(json['height'], 1);
        expect(json['metadata'], {'instanceType': 't3.micro'});
      });

      test('fromJson produces correct model', () {
        final json = service.toJson();
        final restored = CloudServiceModel.fromJson(json);

        expect(restored.id, service.id);
        expect(restored.name, service.name);
        expect(restored.provider, service.provider);
        expect(restored.category, service.category);
        expect(restored.serviceType, service.serviceType);
        expect(restored.position, service.position);
        expect(restored.width, service.width);
        expect(restored.height, service.height);
        expect(restored.metadata, service.metadata);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'svc-min',
          'name': 'Minimal',
          'provider': 'gcp',
          'category': 'serverless',
          'serviceType': 'CloudRun',
          'position': {'x': 3, 'y': 4},
        };

        final restored = CloudServiceModel.fromJson(json);

        expect(restored.id, 'svc-min');
        expect(restored.name, 'Minimal');
        expect(restored.provider, CloudProvider.gcp);
        expect(restored.category, ServiceCategory.serverless);
        expect(restored.serviceType, 'CloudRun');
        expect(restored.position, const GridPosition(3, 4));
        expect(restored.width, 1);
        expect(restored.height, 1);
        expect(restored.metadata, isEmpty);
      });

      test('round-trip serialization for all providers', () {
        final providers = [
          CloudProvider.aws,
          CloudProvider.gcp,
          CloudProvider.azure,
          CloudProvider.cloudflare,
          CloudProvider.vultr,
          CloudProvider.digitalOcean,
        ];

        for (final provider in providers) {
          final original = CloudServiceModel(
            id: 'svc-${provider.name}',
            name: '${provider.name} Service',
            provider: provider,
            category: ServiceCategory.compute,
            serviceType: 'Compute',
            position: const GridPosition(1, 1),
          );

          final restored = CloudServiceModel.fromJson(original.toJson());
          expect(restored, original);
        }
      });

      test('round-trip serialization for all categories', () {
        final categories = [
          ServiceCategory.compute,
          ServiceCategory.storage,
          ServiceCategory.database,
          ServiceCategory.networking,
          ServiceCategory.container,
          ServiceCategory.serverless,
          ServiceCategory.other,
        ];

        for (final category in categories) {
          final original = CloudServiceModel(
            id: 'svc-${category.name}',
            name: '${category.name} Service',
            provider: CloudProvider.aws,
            category: category,
            serviceType: 'Test',
            position: const GridPosition(1, 1),
          );

          final restored = CloudServiceModel.fromJson(original.toJson());
          expect(restored, original);
        }
      });

      test('round-trip serialization preserves nested metadata', () {
        const serviceWithNestedMetadata = CloudServiceModel(
          id: 'svc-nested',
          name: 'Nested Metadata Service',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(1, 1),
          metadata: {
            'config': {
              'enabled': true,
              'timeout': 5000,
            },
            'tags': ['production', 'critical'],
          },
        );

        final json = serviceWithNestedMetadata.toJson();
        final restored = CloudServiceModel.fromJson(json);

        expect(restored.metadata['config'], {'enabled': true, 'timeout': 5000});
        expect(restored.metadata['tags'], ['production', 'critical']);
        expect(restored, serviceWithNestedMetadata);
      });

      test('round-trip serialization preserves empty metadata', () {
        const serviceWithEmptyMetadata = CloudServiceModel(
          id: 'svc-empty-meta',
          name: 'Empty Metadata Service',
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          serviceType: 'CloudStorage',
          position: GridPosition(2, 2),
          metadata: {},
        );

        final restored = CloudServiceModel.fromJson(
          serviceWithEmptyMetadata.toJson(),
        );

        expect(restored.metadata, isEmpty);
        expect(restored, serviceWithEmptyMetadata);
      });

      test('round-trip serialization preserves unicode in metadata', () {
        const serviceWithUnicode = CloudServiceModel(
          id: 'svc-unicode',
          name: 'Unicode Service',
          provider: CloudProvider.azure,
          category: ServiceCategory.database,
          serviceType: 'CosmosDB',
          position: GridPosition(3, 3),
          metadata: {
            'label': '日本語テスト',
            'emoji': '🚀✨',
            'special': 'Ñoño & <script>',
          },
        );

        final restored = CloudServiceModel.fromJson(serviceWithUnicode.toJson());

        expect(restored.metadata['label'], '日本語テスト');
        expect(restored.metadata['emoji'], '🚀✨');
        expect(restored.metadata['special'], 'Ñoño & <script>');
        expect(restored, serviceWithUnicode);
      });

      test('round-trip serialization preserves numeric metadata values', () {
        const serviceWithNumbers = CloudServiceModel(
          id: 'svc-numbers',
          name: 'Numeric Service',
          provider: CloudProvider.vultr,
          category: ServiceCategory.compute,
          serviceType: 'VPS',
          position: GridPosition(4, 4),
          metadata: {
            'cpu': 4,
            'memory': 8192,
            'price': 19.99,
            'ratio': 0.5,
          },
        );

        final restored = CloudServiceModel.fromJson(serviceWithNumbers.toJson());

        expect(restored.metadata['cpu'], 4);
        expect(restored.metadata['memory'], 8192);
        expect(restored.metadata['price'], 19.99);
        expect(restored.metadata['ratio'], 0.5);
        expect(restored, serviceWithNumbers);
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final modified = service.copyWith(
          name: 'New Name',
          position: const GridPosition(8, 8),
        );

        expect(modified.name, 'New Name');
        expect(modified.position, const GridPosition(8, 8));
        expect(modified.id, service.id);
        expect(modified.provider, service.provider);
      });

      test('preserves unmodified fields', () {
        final modified = service.copyWith(width: 3);

        expect(modified.id, 'svc-1');
        expect(modified.name, 'My EC2 Instance');
        expect(modified.provider, CloudProvider.aws);
        expect(modified.category, ServiceCategory.compute);
        expect(modified.serviceType, 'EC2');
        expect(modified.position, const GridPosition(5, 5));
        expect(modified.width, 3);
        expect(modified.height, 1);
        expect(modified.metadata, {'instanceType': 't3.micro'});
      });
    });

    group('cell occupancy', () {
      test('occupiedCells returns correct cells for 1x1 service', () {
        const small = CloudServiceModel(
          id: 'svc-small',
          name: 'Small',
          provider: CloudProvider.aws,
          category: ServiceCategory.storage,
          serviceType: 'S3',
          position: GridPosition(3, 4),
          width: 1,
          height: 1,
        );

        final cells = small.occupiedCells;
        expect(cells.length, 1);
        expect(cells, contains(const GridPosition(3, 4)));
      });

      test('occupiedCells returns correct cells for 2x2 service', () {
        const large = CloudServiceModel(
          id: 'svc-large',
          name: 'Large',
          provider: CloudProvider.aws,
          category: ServiceCategory.database,
          serviceType: 'RDS',
          position: GridPosition(5, 5),
          width: 2,
          height: 2,
        );

        final cells = large.occupiedCells;
        expect(cells.length, 4);
        expect(cells, contains(const GridPosition(5, 5)));
        expect(cells, contains(const GridPosition(6, 5)));
        expect(cells, contains(const GridPosition(5, 6)));
        expect(cells, contains(const GridPosition(6, 6)));
      });

      test('occupiedCells returns correct cells for 3x1 service', () {
        const wide = CloudServiceModel(
          id: 'svc-wide',
          name: 'Wide',
          provider: CloudProvider.aws,
          category: ServiceCategory.container,
          serviceType: 'ECS',
          position: GridPosition(2, 3),
          width: 3,
          height: 1,
        );

        final cells = wide.occupiedCells;
        expect(cells.length, 3);
        expect(cells, contains(const GridPosition(2, 3)));
        expect(cells, contains(const GridPosition(3, 3)));
        expect(cells, contains(const GridPosition(4, 3)));
      });

      test('occupiesCell returns true for occupied cells', () {
        // Service at (5,5) with width=2, height=1
        expect(service.occupiesCell(const GridPosition(5, 5)), isTrue);
        expect(service.occupiesCell(const GridPosition(6, 5)), isTrue);
      });

      test('occupiesCell returns false for non-occupied cells', () {
        expect(service.occupiesCell(const GridPosition(4, 5)), isFalse);
        expect(service.occupiesCell(const GridPosition(7, 5)), isFalse);
        expect(service.occupiesCell(const GridPosition(5, 4)), isFalse);
        expect(service.occupiesCell(const GridPosition(5, 6)), isFalse);
      });
    });

    group('equality', () {
      test('equal services are equal', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        const service2 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );

        expect(service1, service2);
      });

      test('different services are not equal', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        final service2 = service1.copyWith(name: 'Different');

        expect(service1, isNot(service2));
      });

      test('equal services have same hashCode', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        const service2 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );

        expect(service1.hashCode, service2.hashCode);
      });

      test('services can be used in Set collections', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        const service2 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        const service3 = CloudServiceModel(
          id: 'svc-3',
          name: 'S3',
          provider: CloudProvider.aws,
          category: ServiceCategory.storage,
          serviceType: 'S3',
          position: GridPosition(10, 10),
        );

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final serviceSet = {service1, service2, service3};
        expect(serviceSet.length, 2);
        expect(serviceSet.contains(service1), isTrue);
        expect(serviceSet.contains(service3), isTrue);
      });

      test('services can be used as Map keys', () {
        const service1 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );
        const service2 = CloudServiceModel(
          id: 'svc-1',
          name: 'EC2',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          position: GridPosition(5, 5),
        );

        final serviceMap = <CloudServiceModel, String>{service1: 'first'};
        serviceMap[service2] = 'second';

        expect(serviceMap.length, 1);
        expect(serviceMap[service1], 'second');
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final str = service.toString();
        expect(str, contains('CloudServiceModel'));
        expect(str, contains('svc-1'));
        expect(str, contains('CloudProvider.aws'));
        expect(str, contains('EC2'));
      });
    });
  });

  group('CloudServiceTemplate', () {
    test('toString returns descriptive string', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.gcp,
        category: ServiceCategory.compute,
        serviceType: 'ComputeEngine',
        name: 'Compute Engine',
        description: 'Virtual machines',
      );
      final str = template.toString();
      expect(str, contains('CloudServiceTemplate'));
      expect(str, contains('CloudProvider.gcp'));
      expect(str, contains('ComputeEngine'));
    });

    test('creates with required fields', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.storage,
        serviceType: 'S3',
        name: 'S3 Bucket',
        description: 'Object storage',
      );

      expect(template.provider, CloudProvider.aws);
      expect(template.category, ServiceCategory.storage);
      expect(template.serviceType, 'S3');
      expect(template.name, 'S3 Bucket');
      expect(template.description, 'Object storage');
    });

    test('has default width of 1', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2',
        description: 'VM',
      );

      expect(template.width, 1);
    });

    test('has default height of 1', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        name: 'EC2',
        description: 'VM',
      );

      expect(template.height, 1);
    });

    test('accepts custom width and height', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.azure,
        category: ServiceCategory.database,
        serviceType: 'CosmosDB',
        name: 'Cosmos DB',
        description: 'Database',
        width: 2,
        height: 3,
      );

      expect(template.width, 2);
      expect(template.height, 3);
    });

    test('supports all cloud providers', () {
      for (final provider in CloudProvider.values) {
        final template = CloudServiceTemplate(
          provider: provider,
          category: ServiceCategory.compute,
          serviceType: 'Test',
          name: 'Test',
          description: 'Test',
        );
        expect(template.provider, provider);
      }
    });

    test('supports all service categories', () {
      for (final category in ServiceCategory.values) {
        final template = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: category,
          serviceType: 'Test',
          name: 'Test',
          description: 'Test',
        );
        expect(template.category, category);
      }
    });

    test('toString includes name field', () {
      const template = CloudServiceTemplate(
        provider: CloudProvider.vultr,
        category: ServiceCategory.container,
        serviceType: 'K8s',
        name: 'Kubernetes Cluster',
        description: 'Managed K8s',
      );
      final str = template.toString();
      expect(str, contains('Kubernetes Cluster'));
    });

    group('equality', () {
      test('equal templates are equal', () {
        const template1 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2 Instance',
          description: 'Virtual machines',
        );
        const template2 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2 Instance',
          description: 'Virtual machines',
        );

        expect(template1, template2);
        expect(template1.hashCode, template2.hashCode);
      });

      test('different templates are not equal', () {
        const template1 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2 Instance',
          description: 'Virtual machines',
        );
        const template2 = CloudServiceTemplate(
          provider: CloudProvider.gcp,
          category: ServiceCategory.compute,
          serviceType: 'ComputeEngine',
          name: 'Compute Engine',
          description: 'GCP VMs',
        );

        expect(template1, isNot(template2));
      });

      test('templates can be used in Set collections', () {
        const template1 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'VMs',
        );
        const template2 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'VMs',
        );
        const template3 = CloudServiceTemplate(
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          serviceType: 'CloudStorage',
          name: 'Cloud Storage',
          description: 'Object storage',
        );

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final templateSet = <CloudServiceTemplate>{
          template1,
          template2,
          template3,
        };
        expect(templateSet.length, 2);
        expect(templateSet.contains(template1), isTrue);
        expect(templateSet.contains(template3), isTrue);
      });

      test('templates can be used as Map keys', () {
        const template1 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'VMs',
        );
        const template2 = CloudServiceTemplate(
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
          name: 'EC2',
          description: 'VMs',
        );

        final templateMap = <CloudServiceTemplate, String>{template1: 'first'};
        templateMap[template2] = 'second';

        expect(templateMap.length, 1);
        expect(templateMap[template1], 'second');
      });
    });
  });

  group('CloudServiceCatalog', () {
    test('getServicesForProvider returns AWS services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.aws,
      );

      expect(services, isNotEmpty);
      expect(services.every((s) => s.provider == CloudProvider.aws), isTrue);
      expect(services.any((s) => s.serviceType == 'EC2'), isTrue);
      expect(services.any((s) => s.serviceType == 'S3'), isTrue);
      expect(services.any((s) => s.serviceType == 'Lambda'), isTrue);
    });

    test('getServicesForProvider returns GCP services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.gcp,
      );

      expect(services, isNotEmpty);
      expect(services.every((s) => s.provider == CloudProvider.gcp), isTrue);
      expect(services.any((s) => s.serviceType == 'ComputeEngine'), isTrue);
      expect(services.any((s) => s.serviceType == 'CloudRun'), isTrue);
    });

    test('getServicesForProvider returns Azure services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.azure,
      );

      expect(services, isNotEmpty);
      expect(services.every((s) => s.provider == CloudProvider.azure), isTrue);
      expect(services.any((s) => s.serviceType == 'VM'), isTrue);
      expect(services.any((s) => s.serviceType == 'Functions'), isTrue);
    });

    test('getServicesForProvider returns Cloudflare services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.cloudflare,
      );

      expect(services, isNotEmpty);
      expect(
        services.every((s) => s.provider == CloudProvider.cloudflare),
        isTrue,
      );
      expect(services.any((s) => s.serviceType == 'Workers'), isTrue);
      expect(services.any((s) => s.serviceType == 'R2'), isTrue);
    });

    test('getServicesForProvider returns Vultr services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.vultr,
      );

      expect(services, isNotEmpty);
      expect(services.every((s) => s.provider == CloudProvider.vultr), isTrue);
      expect(services.any((s) => s.serviceType == 'VPS'), isTrue);
    });

    test('getServicesForProvider returns DigitalOcean services', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.digitalOcean,
      );

      expect(services, isNotEmpty);
      expect(
        services.every((s) => s.provider == CloudProvider.digitalOcean),
        isTrue,
      );
      expect(services.any((s) => s.serviceType == 'Droplet'), isTrue);
    });

    test('getServicesForProvider returns empty for none', () {
      final services = CloudServiceCatalog.getServicesForProvider(
        CloudProvider.none,
      );

      expect(services, isEmpty);
    });

    test('allServices returns services from all providers', () {
      final services = CloudServiceCatalog.allServices;

      expect(services, isNotEmpty);
      expect(services.any((s) => s.provider == CloudProvider.aws), isTrue);
      expect(services.any((s) => s.provider == CloudProvider.gcp), isTrue);
      expect(services.any((s) => s.provider == CloudProvider.azure), isTrue);
      expect(
        services.any((s) => s.provider == CloudProvider.cloudflare),
        isTrue,
      );
      expect(services.any((s) => s.provider == CloudProvider.vultr), isTrue);
      expect(
        services.any((s) => s.provider == CloudProvider.digitalOcean),
        isTrue,
      );
    });

    test('all templates have required fields', () {
      for (final template in CloudServiceCatalog.allServices) {
        expect(template.provider, isNot(CloudProvider.none));
        expect(template.serviceType, isNotEmpty);
        expect(template.name, isNotEmpty);
        expect(template.description, isNotEmpty);
        expect(template.width, greaterThan(0));
        expect(template.height, greaterThan(0));
      }
    });

    test('all service categories are covered', () {
      final allCategories = CloudServiceCatalog.allServices
          .map((s) => s.category)
          .toSet();

      expect(allCategories, contains(ServiceCategory.compute));
      expect(allCategories, contains(ServiceCategory.storage));
      expect(allCategories, contains(ServiceCategory.database));
      expect(allCategories, contains(ServiceCategory.networking));
      expect(allCategories, contains(ServiceCategory.container));
      expect(allCategories, contains(ServiceCategory.serverless));
    });
  });
}
