import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('DeviceTemplate', () {
    group('constructor', () {
      test('creates template with required fields', () {
        const template = DeviceTemplate(
          id: 'test-1',
          name: 'Test Device',
          description: 'A test device',
          type: DeviceType.server,
          cost: 100,
        );

        expect(template.id, 'test-1');
        expect(template.name, 'Test Device');
        expect(template.description, 'A test device');
        expect(template.type, DeviceType.server);
        expect(template.cost, 100);
      });

      test('has default width of 1', () {
        const template = DeviceTemplate(
          id: 'test-1',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );

        expect(template.width, 1);
      });

      test('has default height of 1', () {
        const template = DeviceTemplate(
          id: 'test-1',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );

        expect(template.height, 1);
      });

      test('accepts custom width and height', () {
        const template = DeviceTemplate(
          id: 'test-1',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
          width: 2,
          height: 3,
        );

        expect(template.width, 2);
        expect(template.height, 3);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const template = DeviceTemplate(
          id: 'server-1',
          name: 'Server',
          description: 'A server',
          type: DeviceType.server,
          cost: 500,
          width: 2,
          height: 1,
        );

        final json = template.toJson();

        expect(json['id'], 'server-1');
        expect(json['name'], 'Server');
        expect(json['description'], 'A server');
        expect(json['type'], 'server');
        expect(json['cost'], 500);
        expect(json['width'], 2);
        expect(json['height'], 1);
      });

      test('serializes all device types correctly', () {
        for (final type in DeviceType.values) {
          final template = DeviceTemplate(
            id: 'test',
            name: 'Test',
            description: 'Test',
            type: type,
            cost: 100,
          );

          expect(template.toJson()['type'], type.name);
        }
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'router-1',
          'name': 'Router',
          'description': 'A router',
          'type': 'router',
          'cost': 150,
          'width': 1,
          'height': 1,
        };

        final template = DeviceTemplate.fromJson(json);

        expect(template.id, 'router-1');
        expect(template.name, 'Router');
        expect(template.description, 'A router');
        expect(template.type, DeviceType.router);
        expect(template.cost, 150);
        expect(template.width, 1);
        expect(template.height, 1);
      });

      test('defaults width to 1 when missing', () {
        final json = {
          'id': 'test',
          'name': 'Test',
          'description': 'Test',
          'type': 'server',
          'cost': 100,
        };

        final template = DeviceTemplate.fromJson(json);

        expect(template.width, 1);
      });

      test('defaults height to 1 when missing', () {
        final json = {
          'id': 'test',
          'name': 'Test',
          'description': 'Test',
          'type': 'server',
          'cost': 100,
        };

        final template = DeviceTemplate.fromJson(json);

        expect(template.height, 1);
      });

      test('deserializes all device types correctly', () {
        for (final type in DeviceType.values) {
          final json = {
            'id': 'test',
            'name': 'Test',
            'description': 'Test',
            'type': type.name,
            'cost': 100,
          };

          final template = DeviceTemplate.fromJson(json);

          expect(template.type, type);
        }
      });
    });

    group('round-trip serialization', () {
      test('toJson and fromJson preserves all data', () {
        const original = DeviceTemplate(
          id: 'nas-1',
          name: 'NAS',
          description: 'Network storage',
          type: DeviceType.nas,
          cost: 400,
          width: 2,
          height: 2,
        );

        final json = original.toJson();
        final restored = DeviceTemplate.fromJson(json);

        expect(restored, original);
      });
    });

    group('Equatable', () {
      test('equal templates are equal', () {
        const t1 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        const t2 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );

        expect(t1, t2);
        expect(t1.hashCode, t2.hashCode);
      });

      test('different ids are not equal', () {
        const t1 = DeviceTemplate(
          id: 'test1',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        const t2 = DeviceTemplate(
          id: 'test2',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );

        expect(t1, isNot(t2));
      });

      test('different types are not equal', () {
        const t1 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        const t2 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.router,
          cost: 100,
        );

        expect(t1, isNot(t2));
      });

      test('different costs are not equal', () {
        const t1 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        );
        const t2 = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 200,
        );

        expect(t1, isNot(t2));
      });

      test('props includes all fields', () {
        const template = DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
          width: 2,
          height: 3,
        );

        expect(template.props, [
          'test',
          'Test',
          'Test',
          DeviceType.server,
          100,
          2,
          3,
        ]);
      });
    });
  });

  group('defaultDeviceTemplates', () {
    test('contains expected number of templates', () {
      expect(defaultDeviceTemplates.length, 7);
    });

    test('all templates have unique ids', () {
      final ids = defaultDeviceTemplates.map((t) => t.id).toSet();
      expect(ids.length, defaultDeviceTemplates.length);
    });

    test('all templates have non-empty names', () {
      for (final template in defaultDeviceTemplates) {
        expect(template.name, isNotEmpty);
      }
    });

    test('all templates have non-empty descriptions', () {
      for (final template in defaultDeviceTemplates) {
        expect(template.description, isNotEmpty);
      }
    });

    test('all templates have positive costs', () {
      for (final template in defaultDeviceTemplates) {
        expect(template.cost, greaterThan(0));
      }
    });

    test('all templates have valid dimensions', () {
      for (final template in defaultDeviceTemplates) {
        expect(template.width, greaterThan(0));
        expect(template.height, greaterThan(0));
      }
    });

    test('contains server template', () {
      final servers = defaultDeviceTemplates.where(
        (t) => t.type == DeviceType.server,
      );
      expect(servers, isNotEmpty);
    });

    test('contains router template', () {
      final routers = defaultDeviceTemplates.where(
        (t) => t.type == DeviceType.router,
      );
      expect(routers, isNotEmpty);
    });

    test('contains nas template', () {
      final nas = defaultDeviceTemplates.where((t) => t.type == DeviceType.nas);
      expect(nas, isNotEmpty);
    });

    test('contains iot template', () {
      final iot = defaultDeviceTemplates.where((t) => t.type == DeviceType.iot);
      expect(iot, isNotEmpty);
    });
  });
}
