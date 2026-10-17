import 'dart:ui' as ui;

import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_objects_devices/game_objects_devices.dart';

Future<ui.Color> _pixel(PositionComponent component, int x, int y) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(
    component.width.ceil(),
    component.height.ceil(),
  );
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (y * image.width + x) * 4;
  final color = ui.Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
  image.dispose();
  picture.dispose();
  return color;
}

void main() {
  testWidgets('same-ID device update repaints its type and running indicator', (
    tester,
  ) async {
    const device = DeviceModel(
      id: 'device',
      templateId: 'server',
      name: 'Server',
      type: DeviceType.server,
      position: GridPosition(1, 1),
    );
    final component = DeviceComponent(device: device);
    expect(
      await tester.runAsync(() => _pixel(component, 10, 20)),
      AppColors.deviceServer,
    );
    expect(
      await tester.runAsync(() => _pixel(component, 22, 10)),
      AppColors.offIndicator,
    );
    component.updateDevice(
      device.copyWith(type: DeviceType.computer, isRunning: true),
    );
    expect(
      await tester.runAsync(() => _pixel(component, 10, 20)),
      AppColors.deviceComputer,
    );
    expect(
      await tester.runAsync(() => _pixel(component, 22, 10)),
      isNot(AppColors.offIndicator),
    );
  });

  testWidgets(
    'same-ID cloud update repaints provider and category after resizing',
    (tester) async {
      const service = CloudServiceModel(
        id: 'service',
        name: 'Compute',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        position: GridPosition(1, 1),
      );
      final component = CloudServiceComponent(service: service);
      component.updateService(
        service.copyWith(
          provider: CloudProvider.gcp,
          category: ServiceCategory.storage,
          width: 3,
          height: 2,
        ),
      );
      expect(
        await tester.runAsync(() => _pixel(component, 84, 12)),
        CloudProvider.gcp.color,
      );
      expect(
        await tester.runAsync(() => _pixel(component, 10, 40)),
        ServiceCategory.storage.color,
      );
      expect(
        await tester.runAsync(() => _pixel(component, 48, 32)),
        AppColors.cloudServiceIcon,
      );
    },
  );
}
