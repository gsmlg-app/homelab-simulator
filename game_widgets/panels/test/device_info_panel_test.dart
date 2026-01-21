import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_panels/game_widgets_panels.dart';

void main() {
  group('DeviceInfoPanel', () {
    const testDevice = DeviceModel(
      id: 'device-1',
      templateId: 'template-1',
      name: 'Test Server',
      type: DeviceType.server,
      position: GridPosition(5, 10),
      isRunning: true,
    );

    testWidgets('renders device name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('Test Server'), findsOneWidget);
    });

    testWidgets('renders device type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('server'), findsOneWidget);
    });

    testWidgets('renders device position', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('(5, 10)'), findsOneWidget);
    });

    testWidgets('shows Running status when device is running', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('shows Stopped status when device is not running', (
      tester,
    ) async {
      final stoppedDevice = testDevice.copyWith(isRunning: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: stoppedDevice)),
        ),
      );

      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('renders Device Info title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('DEVICE INFO'), findsOneWidget);
    });

    group('device type icons', () {
      testWidgets('shows dns icon for server', (tester) async {
        final serverDevice = testDevice.copyWith(type: DeviceType.server);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: serverDevice)),
          ),
        );

        expect(find.byIcon(Icons.dns), findsOneWidget);
      });

      testWidgets('shows computer icon for computer', (tester) async {
        final computerDevice = testDevice.copyWith(type: DeviceType.computer);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: computerDevice)),
          ),
        );

        expect(find.byIcon(Icons.computer), findsOneWidget);
      });

      testWidgets('shows phone_android icon for phone', (tester) async {
        final phoneDevice = testDevice.copyWith(type: DeviceType.phone);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: phoneDevice)),
          ),
        );

        expect(find.byIcon(Icons.phone_android), findsOneWidget);
      });

      testWidgets('shows router icon for router', (tester) async {
        final routerDevice = testDevice.copyWith(type: DeviceType.router);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: routerDevice)),
          ),
        );

        expect(find.byIcon(Icons.router), findsOneWidget);
      });

      testWidgets('shows hub icon for switch', (tester) async {
        final switchDevice = testDevice.copyWith(type: DeviceType.switch_);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: switchDevice)),
          ),
        );

        expect(find.byIcon(Icons.hub), findsOneWidget);
      });

      testWidgets('shows storage icon for nas', (tester) async {
        final nasDevice = testDevice.copyWith(type: DeviceType.nas);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: nasDevice)),
          ),
        );

        expect(find.byIcon(Icons.storage), findsOneWidget);
      });

      testWidgets('shows sensors icon for iot', (tester) async {
        final iotDevice = testDevice.copyWith(type: DeviceType.iot);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: iotDevice)),
          ),
        );

        expect(find.byIcon(Icons.sensors), findsOneWidget);
      });
    });

    group('remove button', () {
      testWidgets('is not rendered when onRemove is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
          ),
        );

        expect(find.text('Remove Device'), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      });

      testWidgets('is rendered when onRemove is provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeviceInfoPanel(device: testDevice, onRemove: () {}),
            ),
          ),
        );

        expect(find.text('Remove Device'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('calls onRemove when tapped', (tester) async {
        bool removeCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeviceInfoPanel(
                device: testDevice,
                onRemove: () => removeCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Remove Device'));
        await tester.pump();

        expect(removeCalled, isTrue);
      });
    });

    testWidgets('renders all info labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    group('widget properties', () {
      test('is a StatelessWidget', () {
        const panel = DeviceInfoPanel(device: testDevice);

        expect(panel, isA<StatelessWidget>());
      });

      test('key can be provided', () {
        const key = Key('test-device-panel');
        const panel = DeviceInfoPanel(key: key, device: testDevice);

        expect(panel.key, key);
      });

      test('device property is accessible', () {
        const panel = DeviceInfoPanel(device: testDevice);

        expect(panel.device, testDevice);
      });

      test('onRemove property is accessible', () {
        final callback = () {};
        final panel = DeviceInfoPanel(device: testDevice, onRemove: callback);

        expect(panel.onRemove, callback);
      });
    });

    group('position display variations', () {
      testWidgets('renders position at origin', (tester) async {
        final originDevice = testDevice.copyWith(
          position: const GridPosition(0, 0),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: originDevice)),
          ),
        );

        expect(find.text('(0, 0)'), findsOneWidget);
      });

      testWidgets('renders position at high coordinates', (tester) async {
        final farDevice = testDevice.copyWith(
          position: const GridPosition(100, 200),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: farDevice)),
          ),
        );

        expect(find.text('(100, 200)'), findsOneWidget);
      });
    });

    group('device name variations', () {
      testWidgets('renders long device name', (tester) async {
        final longNameDevice = testDevice.copyWith(
          name: 'Very Long Device Name That Might Overflow',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: longNameDevice)),
          ),
        );

        expect(find.text('Very Long Device Name That Might Overflow'), findsOneWidget);
      });

      testWidgets('renders short device name', (tester) async {
        final shortNameDevice = testDevice.copyWith(name: 'A');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: shortNameDevice)),
          ),
        );

        expect(find.text('A'), findsOneWidget);
      });
    });

    group('all device types coverage', () {
      testWidgets('all device types can be rendered', (tester) async {
        // server, computer, phone, router, switch_, nas, iot
        for (final type in DeviceType.values) {
          final device = testDevice.copyWith(type: type);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: DeviceInfoPanel(device: device)),
            ),
          );

          expect(find.text(type.name), findsOneWidget);
        }
      });

      testWidgets('device type count is expected', (tester) async {
        // server, computer, phone, router, switch_, nas, iot
        expect(DeviceType.values.length, 7);
      });
    });

    group('remove button edge cases', () {
      testWidgets('remove button can be tapped multiple times', (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeviceInfoPanel(
                device: testDevice,
                onRemove: () => callCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Remove Device'));
        await tester.pump();
        await tester.tap(find.text('Remove Device'));
        await tester.pump();

        expect(callCount, 2);
      });
    });

    group('layout structure', () {
      testWidgets('renders within Container', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
          ),
        );

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('renders Column layout', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
          ),
        );

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('renders Row layout', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: DeviceInfoPanel(device: testDevice)),
          ),
        );

        expect(find.byType(Row), findsWidgets);
      });
    });
  });
}
