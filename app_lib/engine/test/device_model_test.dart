import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('DeviceModel', () {
    late DeviceModel device;

    setUp(() {
      device = const DeviceModel(
        id: 'dev-1',
        templateId: 'server-template',
        name: 'My Server',
        type: DeviceType.server,
        position: GridPosition(5, 5),
        width: 2,
        height: 1,
        isRunning: true,
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(device.id, 'dev-1');
        expect(device.templateId, 'server-template');
        expect(device.name, 'My Server');
        expect(device.type, DeviceType.server);
        expect(device.position, const GridPosition(5, 5));
        expect(device.width, 2);
        expect(device.height, 1);
        expect(device.isRunning, isTrue);
      });

      test('creates with default width, height, and isRunning', () {
        const simple = DeviceModel(
          id: 'dev-2',
          templateId: 'router-template',
          name: 'Router',
          type: DeviceType.router,
          position: GridPosition(3, 3),
        );

        expect(simple.width, 1);
        expect(simple.height, 1);
        expect(simple.isRunning, isFalse);
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = device.toJson();

        expect(json['id'], 'dev-1');
        expect(json['templateId'], 'server-template');
        expect(json['name'], 'My Server');
        expect(json['type'], 'server');
        expect(json['position'], {'x': 5, 'y': 5});
        expect(json['width'], 2);
        expect(json['height'], 1);
        expect(json['isRunning'], isTrue);
      });

      test('fromJson produces correct model', () {
        final json = device.toJson();
        final restored = DeviceModel.fromJson(json);

        expect(restored.id, device.id);
        expect(restored.templateId, device.templateId);
        expect(restored.name, device.name);
        expect(restored.type, device.type);
        expect(restored.position, device.position);
        expect(restored.width, device.width);
        expect(restored.height, device.height);
        expect(restored.isRunning, device.isRunning);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'dev-min',
          'templateId': 'tmpl',
          'name': 'Minimal',
          'type': 'nas',
          'position': {'x': 1, 'y': 2},
        };

        final restored = DeviceModel.fromJson(json);

        expect(restored.id, 'dev-min');
        expect(restored.name, 'Minimal');
        expect(restored.type, DeviceType.nas);
        expect(restored.position, const GridPosition(1, 2));
        expect(restored.width, 1);
        expect(restored.height, 1);
        expect(restored.isRunning, isFalse);
      });

      test('round-trip serialization for all device types', () {
        final types = [
          DeviceType.server,
          DeviceType.computer,
          DeviceType.phone,
          DeviceType.router,
          DeviceType.switch_,
          DeviceType.nas,
          DeviceType.iot,
        ];

        for (final type in types) {
          final original = DeviceModel(
            id: 'dev-${type.name}',
            templateId: 'tmpl-${type.name}',
            name: '${type.name} Device',
            type: type,
            position: const GridPosition(1, 1),
          );

          final restored = DeviceModel.fromJson(original.toJson());
          expect(restored, original);
        }
      });

      test('round-trip serialization preserves origin position (0,0)', () {
        const deviceAtOrigin = DeviceModel(
          id: 'dev-origin',
          templateId: 'tmpl-origin',
          name: 'Origin Device',
          type: DeviceType.server,
          position: GridPosition(0, 0),
        );

        final restored = DeviceModel.fromJson(deviceAtOrigin.toJson());

        expect(restored.position, const GridPosition(0, 0));
        expect(restored, deviceAtOrigin);
      });

      test('round-trip serialization preserves boundary positions', () {
        // Test device at room grid boundaries (19x11 is typical max)
        const positions = [
          GridPosition(0, 0), // top-left
          GridPosition(19, 0), // top-right
          GridPosition(0, 11), // bottom-left
          GridPosition(19, 11), // bottom-right
        ];

        for (final pos in positions) {
          final original = DeviceModel(
            id: 'dev-boundary-${pos.x}-${pos.y}',
            templateId: 'tmpl-boundary',
            name: 'Boundary Device',
            type: DeviceType.nas,
            position: pos,
          );

          final restored = DeviceModel.fromJson(original.toJson());
          expect(restored.position, pos);
          expect(restored, original);
        }
      });

      test('round-trip serialization preserves large position values', () {
        const deviceAtLargePos = DeviceModel(
          id: 'dev-large',
          templateId: 'tmpl-large',
          name: 'Large Position Device',
          type: DeviceType.iot,
          position: GridPosition(1000, 1000),
        );

        final restored = DeviceModel.fromJson(deviceAtLargePos.toJson());

        expect(restored.position, const GridPosition(1000, 1000));
        expect(restored, deviceAtLargePos);
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final modified = device.copyWith(name: 'New Name', isRunning: false);

        expect(modified.name, 'New Name');
        expect(modified.isRunning, isFalse);
        expect(modified.id, device.id);
        expect(modified.templateId, device.templateId);
        expect(modified.type, device.type);
        expect(modified.position, device.position);
      });

      test('preserves unmodified fields', () {
        final modified = device.copyWith(width: 3);

        expect(modified.id, 'dev-1');
        expect(modified.templateId, 'server-template');
        expect(modified.name, 'My Server');
        expect(modified.type, DeviceType.server);
        expect(modified.position, const GridPosition(5, 5));
        expect(modified.width, 3);
        expect(modified.height, 1);
        expect(modified.isRunning, isTrue);
      });
    });

    group('cell occupancy', () {
      test('occupiedCells returns correct cells for 1x1 device', () {
        const small = DeviceModel(
          id: 'dev-small',
          templateId: 'tmpl',
          name: 'Small',
          type: DeviceType.iot,
          position: GridPosition(3, 4),
          width: 1,
          height: 1,
        );

        final cells = small.occupiedCells;
        expect(cells.length, 1);
        expect(cells, contains(const GridPosition(3, 4)));
      });

      test('occupiedCells returns correct cells for 2x2 device', () {
        const large = DeviceModel(
          id: 'dev-large',
          templateId: 'tmpl',
          name: 'Large',
          type: DeviceType.server,
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

      test('occupiedCells returns correct cells for 3x1 device', () {
        const wide = DeviceModel(
          id: 'dev-wide',
          templateId: 'tmpl',
          name: 'Wide',
          type: DeviceType.switch_,
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
        // Device at (5,5) with width=2, height=1
        expect(device.occupiesCell(const GridPosition(5, 5)), isTrue);
        expect(device.occupiesCell(const GridPosition(6, 5)), isTrue);
      });

      test('occupiesCell returns false for non-occupied cells', () {
        expect(device.occupiesCell(const GridPosition(4, 5)), isFalse);
        expect(device.occupiesCell(const GridPosition(7, 5)), isFalse);
        expect(device.occupiesCell(const GridPosition(5, 4)), isFalse);
        expect(device.occupiesCell(const GridPosition(5, 6)), isFalse);
      });

      group('dimension edge cases', () {
        test('occupiedCells returns empty list for zero width', () {
          const zeroWidth = DeviceModel(
            id: 'dev-zero-w',
            templateId: 'tmpl',
            name: 'Zero Width',
            type: DeviceType.iot,
            position: GridPosition(5, 5),
            width: 0,
            height: 1,
          );

          expect(zeroWidth.occupiedCells, isEmpty);
        });

        test('occupiedCells returns empty list for zero height', () {
          const zeroHeight = DeviceModel(
            id: 'dev-zero-h',
            templateId: 'tmpl',
            name: 'Zero Height',
            type: DeviceType.iot,
            position: GridPosition(5, 5),
            width: 1,
            height: 0,
          );

          expect(zeroHeight.occupiedCells, isEmpty);
        });

        test('occupiedCells returns empty list for both zero dimensions', () {
          const zeroSize = DeviceModel(
            id: 'dev-zero',
            templateId: 'tmpl',
            name: 'Zero Size',
            type: DeviceType.iot,
            position: GridPosition(5, 5),
            width: 0,
            height: 0,
          );

          expect(zeroSize.occupiedCells, isEmpty);
        });

        test('occupiedCells handles large dimensions (10x10)', () {
          const large = DeviceModel(
            id: 'dev-large',
            templateId: 'tmpl',
            name: 'Large',
            type: DeviceType.server,
            position: GridPosition(0, 0),
            width: 10,
            height: 10,
          );

          final cells = large.occupiedCells;
          expect(cells.length, 100);
          expect(cells, contains(const GridPosition(0, 0)));
          expect(cells, contains(const GridPosition(9, 9)));
          expect(cells, contains(const GridPosition(5, 5)));
        });

        test('occupiesCell with negative coordinates returns false', () {
          // Device at (5,5) with width=2, height=1
          expect(device.occupiesCell(const GridPosition(-1, 5)), isFalse);
          expect(device.occupiesCell(const GridPosition(5, -1)), isFalse);
          expect(device.occupiesCell(const GridPosition(-5, -5)), isFalse);
        });

        test('occupiesCell boundary check at device edges', () {
          // Device at (5,5) with width=2, height=1 occupies (5,5) and (6,5)
          // Just before: (4,5) - should be false
          expect(device.occupiesCell(const GridPosition(4, 5)), isFalse);
          // First cell: (5,5) - should be true
          expect(device.occupiesCell(const GridPosition(5, 5)), isTrue);
          // Last cell: (6,5) - should be true
          expect(device.occupiesCell(const GridPosition(6, 5)), isTrue);
          // Just after: (7,5) - should be false
          expect(device.occupiesCell(const GridPosition(7, 5)), isFalse);
        });

        test('occupiedCells with position at origin (0,0)', () {
          const atOrigin = DeviceModel(
            id: 'dev-origin',
            templateId: 'tmpl',
            name: 'At Origin',
            type: DeviceType.iot,
            position: GridPosition(0, 0),
            width: 2,
            height: 2,
          );

          final cells = atOrigin.occupiedCells;
          expect(cells.length, 4);
          expect(cells, contains(const GridPosition(0, 0)));
          expect(cells, contains(const GridPosition(1, 0)));
          expect(cells, contains(const GridPosition(0, 1)));
          expect(cells, contains(const GridPosition(1, 1)));
        });

        test('occupiesCell for tall narrow device (1x5)', () {
          const tall = DeviceModel(
            id: 'dev-tall',
            templateId: 'tmpl',
            name: 'Tall',
            type: DeviceType.server,
            position: GridPosition(3, 2),
            width: 1,
            height: 5,
          );

          expect(tall.occupiesCell(const GridPosition(3, 2)), isTrue);
          expect(tall.occupiesCell(const GridPosition(3, 3)), isTrue);
          expect(tall.occupiesCell(const GridPosition(3, 4)), isTrue);
          expect(tall.occupiesCell(const GridPosition(3, 5)), isTrue);
          expect(tall.occupiesCell(const GridPosition(3, 6)), isTrue);
          expect(tall.occupiesCell(const GridPosition(3, 7)), isFalse);
          expect(tall.occupiesCell(const GridPosition(2, 4)), isFalse);
          expect(tall.occupiesCell(const GridPosition(4, 4)), isFalse);
        });
      });
    });

    group('equality', () {
      test('equal devices are equal', () {
        const device1 = DeviceModel(
          id: 'dev-1',
          templateId: 'tmpl',
          name: 'Device',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        const device2 = DeviceModel(
          id: 'dev-1',
          templateId: 'tmpl',
          name: 'Device',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );

        expect(device1, device2);
      });

      test('different devices are not equal', () {
        const device1 = DeviceModel(
          id: 'dev-1',
          templateId: 'tmpl',
          name: 'Device',
          type: DeviceType.server,
          position: GridPosition(5, 5),
        );
        final device2 = device1.copyWith(name: 'Different');

        expect(device1, isNot(device2));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final str = device.toString();
        expect(str, contains('DeviceModel'));
        expect(str, contains('dev-1'));
        expect(str, contains('My Server'));
        expect(str, contains('DeviceType.server'));
      });
    });
  });

  group('DeviceTemplate', () {
    late DeviceTemplate template;

    setUp(() {
      template = const DeviceTemplate(
        id: 'tmpl-1',
        name: 'Basic Server',
        description: 'A simple rack server',
        type: DeviceType.server,
        cost: 500,
        width: 2,
        height: 1,
      );
    });

    group('construction', () {
      test('creates with required fields', () {
        expect(template.id, 'tmpl-1');
        expect(template.name, 'Basic Server');
        expect(template.description, 'A simple rack server');
        expect(template.type, DeviceType.server);
        expect(template.cost, 500);
        expect(template.width, 2);
        expect(template.height, 1);
      });

      test('creates with default width and height', () {
        const simple = DeviceTemplate(
          id: 'tmpl-2',
          name: 'Simple',
          description: 'A simple device',
          type: DeviceType.iot,
          cost: 50,
        );

        expect(simple.width, 1);
        expect(simple.height, 1);
      });
    });

    group('serialization', () {
      test('toJson produces correct map', () {
        final json = template.toJson();

        expect(json['id'], 'tmpl-1');
        expect(json['name'], 'Basic Server');
        expect(json['description'], 'A simple rack server');
        expect(json['type'], 'server');
        expect(json['cost'], 500);
        expect(json['width'], 2);
        expect(json['height'], 1);
      });

      test('fromJson produces correct model', () {
        final json = template.toJson();
        final restored = DeviceTemplate.fromJson(json);

        expect(restored.id, template.id);
        expect(restored.name, template.name);
        expect(restored.description, template.description);
        expect(restored.type, template.type);
        expect(restored.cost, template.cost);
        expect(restored.width, template.width);
        expect(restored.height, template.height);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'tmpl-min',
          'name': 'Minimal',
          'description': 'A minimal template',
          'type': 'router',
          'cost': 100,
        };

        final restored = DeviceTemplate.fromJson(json);

        expect(restored.id, 'tmpl-min');
        expect(restored.name, 'Minimal');
        expect(restored.type, DeviceType.router);
        expect(restored.cost, 100);
        expect(restored.width, 1);
        expect(restored.height, 1);
      });
    });

    group('equality', () {
      test('equal templates are equal', () {
        const template1 = DeviceTemplate(
          id: 'tmpl-1',
          name: 'Server',
          description: 'Desc',
          type: DeviceType.server,
          cost: 100,
        );
        const template2 = DeviceTemplate(
          id: 'tmpl-1',
          name: 'Server',
          description: 'Desc',
          type: DeviceType.server,
          cost: 100,
        );

        expect(template1, template2);
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final str = template.toString();
        expect(str, contains('DeviceTemplate'));
        expect(str, contains('tmpl-1'));
        expect(str, contains('Basic Server'));
        expect(str, contains('DeviceType.server'));
        expect(str, contains('500'));
      });
    });
  });

  group('defaultDeviceTemplates', () {
    test('contains expected templates', () {
      expect(defaultDeviceTemplates, isNotEmpty);
      expect(
        defaultDeviceTemplates.any((t) => t.type == DeviceType.server),
        isTrue,
      );
      expect(
        defaultDeviceTemplates.any((t) => t.type == DeviceType.router),
        isTrue,
      );
      expect(
        defaultDeviceTemplates.any((t) => t.type == DeviceType.nas),
        isTrue,
      );
    });

    test('all templates have required fields', () {
      for (final template in defaultDeviceTemplates) {
        expect(template.id, isNotEmpty);
        expect(template.name, isNotEmpty);
        expect(template.description, isNotEmpty);
        expect(template.cost, greaterThan(0));
        expect(template.width, greaterThan(0));
        expect(template.height, greaterThan(0));
      }
    });
  });
}
