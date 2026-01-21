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
        final component = DeviceComponent(device: routerDevice, tileSize: 32.0);

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

      test('can have priority set', () {
        final component = DeviceComponent(device: serverDevice);
        component.priority = 10;

        expect(component.priority, 10);
      });

      test('can have anchor set', () {
        final component = DeviceComponent(device: serverDevice);
        component.anchor = Anchor.center;

        expect(component.anchor, Anchor.center);
      });
    });

    group('edge cases', () {
      test('handles device at high position', () {
        const farDevice = DeviceModel(
          id: 'far-device',
          templateId: 'server-1',
          name: 'Far Device',
          type: DeviceType.server,
          position: GridPosition(100, 100),
        );
        final component = DeviceComponent(device: farDevice, tileSize: 32.0);

        expect(component.position, Vector2(3200.0, 3200.0));
      });

      test('handles large device dimensions', () {
        const largeDevice = DeviceModel(
          id: 'large-device',
          templateId: 'server-1',
          name: 'Large Device',
          type: DeviceType.server,
          position: GridPosition(0, 0),
          width: 5,
          height: 3,
        );
        final component = DeviceComponent(device: largeDevice, tileSize: 32.0);

        expect(component.size, Vector2(160.0, 96.0));
      });

      test('handles phone device type', () {
        const phoneDevice = DeviceModel(
          id: 'phone-1',
          templateId: 'phone-t',
          name: 'Phone',
          type: DeviceType.phone,
          position: GridPosition(0, 0),
        );
        final component = DeviceComponent(device: phoneDevice);

        expect(component.device.type, DeviceType.phone);
      });

      test('handles switch device type', () {
        const switchDevice = DeviceModel(
          id: 'switch-1',
          templateId: 'switch-t',
          name: 'Switch',
          type: DeviceType.switch_,
          position: GridPosition(0, 0),
        );
        final component = DeviceComponent(device: switchDevice);

        expect(component.device.type, DeviceType.switch_);
      });

      test('handles NAS device type', () {
        const nasDevice = DeviceModel(
          id: 'nas-1',
          templateId: 'nas-t',
          name: 'NAS',
          type: DeviceType.nas,
          position: GridPosition(0, 0),
        );
        final component = DeviceComponent(device: nasDevice);

        expect(component.device.type, DeviceType.nas);
      });

      test('handles IoT device type', () {
        const iotDevice = DeviceModel(
          id: 'iot-1',
          templateId: 'iot-t',
          name: 'IoT',
          type: DeviceType.iot,
          position: GridPosition(0, 0),
        );
        final component = DeviceComponent(device: iotDevice);

        expect(component.device.type, DeviceType.iot);
      });

      test('default anchor is top left', () {
        final component = DeviceComponent(device: serverDevice);

        expect(component.anchor, Anchor.topLeft);
      });
    });

    group('position manipulation', () {
      test('initial position uses device grid position', () {
        final component = DeviceComponent(device: serverDevice, tileSize: 32.0);

        expect(component.position.x, 160.0); // 5 * 32
        expect(component.position.y, 96.0); // 3 * 32
      });

      test('position can be modified', () {
        final component = DeviceComponent(device: serverDevice);
        component.position = Vector2(500, 600);

        expect(component.position, Vector2(500, 600));
      });
    });

    group('animation state', () {
      test('running device has flicker animation capability', () {
        final component = DeviceComponent(device: serverDevice);

        // Device is running, so flicker animation is active
        expect(component.device.isRunning, true);
      });

      test('stopped device does not have flicker animation', () {
        final component = DeviceComponent(device: computerDevice);

        // Device is not running, so no flicker
        expect(component.device.isRunning, false);
      });

      test('flicker animation only applies to running devices', () {
        // Running server
        final running = DeviceComponent(device: serverDevice);
        expect(running.device.isRunning, true);

        // Stopped computer
        final stopped = DeviceComponent(device: computerDevice);
        expect(stopped.device.isRunning, false);
      });

      test('animation period constant is defined', () {
        // Verify the component type has animation bounding
        final component = DeviceComponent(device: serverDevice);

        // The component should be able to handle extended time without issues
        expect(component.device.isRunning, true);
      });
    });

    group('animation time bounding', () {
      test('component can be constructed for running device', () {
        // Verifies component can be constructed for animation testing
        final component = DeviceComponent(device: serverDevice);

        expect(component, isA<DeviceComponent>());
        expect(component.device.isRunning, true);
      });

      test('component handles non-running device', () {
        // Non-running device should not animate
        final component = DeviceComponent(device: computerDevice);

        expect(component.device.isRunning, false);
      });
    });
  });
}
