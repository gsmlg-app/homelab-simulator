import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('DeviceTypeUI extension', () {
    group('icon', () {
      test('server returns dns icon', () {
        expect(DeviceType.server.icon, Icons.dns);
      });

      test('computer returns computer icon', () {
        expect(DeviceType.computer.icon, Icons.computer);
      });

      test('phone returns phone_android icon', () {
        expect(DeviceType.phone.icon, Icons.phone_android);
      });

      test('router returns router icon', () {
        expect(DeviceType.router.icon, Icons.router);
      });

      test('switch_ returns hub icon', () {
        expect(DeviceType.switch_.icon, Icons.hub);
      });

      test('nas returns storage icon', () {
        expect(DeviceType.nas.icon, Icons.storage);
      });

      test('iot returns sensors icon', () {
        expect(DeviceType.iot.icon, Icons.sensors);
      });
    });

    group('color', () {
      test('server returns blue', () {
        expect(DeviceType.server.color, const Color(0xFF3498DB));
      });

      test('computer returns purple', () {
        expect(DeviceType.computer.color, const Color(0xFF9B59B6));
      });

      test('phone returns red', () {
        expect(DeviceType.phone.color, const Color(0xFFE74C3C));
      });

      test('router returns orange', () {
        expect(DeviceType.router.color, const Color(0xFFF39C12));
      });

      test('switch_ returns teal', () {
        expect(DeviceType.switch_.color, const Color(0xFF1ABC9C));
      });

      test('nas returns dark grey', () {
        expect(DeviceType.nas.color, const Color(0xFF34495E));
      });

      test('iot returns green', () {
        expect(DeviceType.iot.color, const Color(0xFF27AE60));
      });
    });

    group('displayName', () {
      test('server returns Server', () {
        expect(DeviceType.server.displayName, 'Server');
      });

      test('computer returns Computer', () {
        expect(DeviceType.computer.displayName, 'Computer');
      });

      test('phone returns Phone', () {
        expect(DeviceType.phone.displayName, 'Phone');
      });

      test('router returns Router', () {
        expect(DeviceType.router.displayName, 'Router');
      });

      test('switch_ returns Switch', () {
        expect(DeviceType.switch_.displayName, 'Switch');
      });

      test('nas returns NAS', () {
        expect(DeviceType.nas.displayName, 'NAS');
      });

      test('iot returns IoT Device', () {
        expect(DeviceType.iot.displayName, 'IoT Device');
      });
    });

    test('all DeviceType values have icon, color, and displayName', () {
      for (final type in DeviceType.values) {
        expect(type.icon, isA<IconData>(), reason: '$type should have icon');
        expect(type.color, isA<Color>(), reason: '$type should have color');
        expect(
          type.displayName,
          isNotEmpty,
          reason: '$type should have displayName',
        );
      }
    });
  });
}
