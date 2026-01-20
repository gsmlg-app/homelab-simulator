import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_objects_devices/game_objects_devices.dart';

void main() {
  group('DeviceComponent', () {
    late DeviceModel serverDevice;
    late DeviceModel computerDevice;
    late DeviceModel routerDevice;

    setUp(() {
      serverDevice = const DeviceModel(
        id: 'device-1',
        templateId: 'server-1',
        name: 'Test Server',
        type: DeviceType.server,
        position: GridPosition(5, 3),
        isRunning: true,
      );

      computerDevice = const DeviceModel(
        id: 'device-2',
        templateId: 'computer-1',
        name: 'Test Computer',
        type: DeviceType.computer,
        position: GridPosition(10, 8),
        isRunning: false,
        width: 2,
        height: 2,
      );

      routerDevice = const DeviceModel(
        id: 'device-3',
        templateId: 'router-1',
        name: 'Test Router',
        type: DeviceType.router,
        position: GridPosition(0, 0),
        isRunning: true,
      );
    });

    group('constructor', () {
      test('stores device model', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.device, serverDevice);
      });

      test('uses default tile size from GameConstants', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.tileSize, GameConstants.tileSize);
      });

      test('accepts custom tile size', () {
        final component = DeviceComponent(device: serverDevice, tileSize: 64.0);

        expect(component.tileSize, 64.0);
      });
    });

    group('position', () {
      test('initializes from device position and tile size', () {
        const tileSize = 32.0;
        final component = DeviceComponent(
          device: serverDevice,
          tileSize: tileSize,
        );

        // Position (5, 3) * 32 = (160, 96)
        expect(component.position, Vector2(160.0, 96.0));
      });

      test('handles origin position', () {
        final component = DeviceComponent(
          device: routerDevice,
          tileSize: 32.0,
        );

        expect(component.position, Vector2(0, 0));
      });

      test('uses device position for pixel calculation', () {
        final component = DeviceComponent(device: computerDevice);

        final expectedX = computerDevice.position.x * GameConstants.tileSize;
        final expectedY = computerDevice.position.y * GameConstants.tileSize;

        expect(component.position, Vector2(expectedX, expectedY));
      });
    });

    group('size', () {
      test('calculates from device width and height', () {
        final component = DeviceComponent(device: serverDevice, tileSize: 32.0);

        // Default device is 1x1
        expect(component.size, Vector2(32.0, 32.0));
      });

      test('respects device dimensions', () {
        final component = DeviceComponent(
          device: computerDevice,
          tileSize: 32.0,
        );

        // 2x2 device
        expect(component.size, Vector2(64.0, 64.0));
      });

      test('scales with custom tile size', () {
        final component = DeviceComponent(device: serverDevice, tileSize: 64.0);

        expect(component.size, Vector2(64.0, 64.0));
      });
    });

    group('device properties', () {
      test('device id is accessible', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.device.id, 'device-1');
      });

      test('device name is accessible', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.device.name, 'Test Server');
      });

      test('device type is accessible', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.device.type, DeviceType.server);
      });

      test('device isRunning is accessible', () {
        final running = DeviceComponent(device: serverDevice);
        final stopped = DeviceComponent(device: computerDevice);

        expect(running.device.isRunning, true);
        expect(stopped.device.isRunning, false);
      });
    });

    group('device types', () {
      test('supports server type', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.device.type, DeviceType.server);
      });

      test('supports computer type', () {
        final component = DeviceComponent(device: computerDevice);

        expect(component.device.type, DeviceType.computer);
      });

      test('supports router type', () {
        final component = DeviceComponent(device: routerDevice);

        expect(component.device.type, DeviceType.router);
      });
    });

    group('inheritance', () {
      test('extends PositionComponent', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component, isA<PositionComponent>());
      });
    });
  });
}
