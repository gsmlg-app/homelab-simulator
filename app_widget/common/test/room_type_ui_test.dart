import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('RoomTypeUI extension', () {
    group('icon', () {
      test('serverRoom returns dns icon', () {
        expect(RoomType.serverRoom.icon, Icons.dns);
      });

      test('aws returns cloud icon', () {
        expect(RoomType.aws.icon, Icons.cloud);
      });

      test('gcp returns cloud_circle icon', () {
        expect(RoomType.gcp.icon, Icons.cloud_circle);
      });

      test('cloudflare returns security icon', () {
        expect(RoomType.cloudflare.icon, Icons.security);
      });

      test('vultr returns dns icon', () {
        expect(RoomType.vultr.icon, Icons.dns);
      });

      test('azure returns cloud_queue icon', () {
        expect(RoomType.azure.icon, Icons.cloud_queue);
      });

      test('digitalOcean returns water_drop icon', () {
        expect(RoomType.digitalOcean.icon, Icons.water_drop);
      });

      test('custom returns folder_special icon', () {
        expect(RoomType.custom.icon, Icons.folder_special);
      });
    });

    group('color', () {
      test('serverRoom returns grey', () {
        expect(RoomType.serverRoom.color, Colors.grey);
      });

      test('aws returns orange', () {
        expect(RoomType.aws.color, const Color(0xFFFF9900));
      });

      test('gcp returns blue', () {
        expect(RoomType.gcp.color, const Color(0xFF4285F4));
      });

      test('cloudflare returns orange', () {
        expect(RoomType.cloudflare.color, const Color(0xFFF38020));
      });

      test('vultr returns blue', () {
        expect(RoomType.vultr.color, const Color(0xFF007BFC));
      });

      test('azure returns blue', () {
        expect(RoomType.azure.color, const Color(0xFF0078D4));
      });

      test('digitalOcean returns blue', () {
        expect(RoomType.digitalOcean.color, const Color(0xFF0080FF));
      });

      test('custom returns purple', () {
        expect(RoomType.custom.color, Colors.purple);
      });
    });

    group('displayName', () {
      test('serverRoom returns Server Room', () {
        expect(RoomType.serverRoom.displayName, 'Server Room');
      });

      test('aws returns AWS', () {
        expect(RoomType.aws.displayName, 'AWS');
      });

      test('gcp returns GCP', () {
        expect(RoomType.gcp.displayName, 'GCP');
      });

      test('cloudflare returns Cloudflare', () {
        expect(RoomType.cloudflare.displayName, 'Cloudflare');
      });

      test('vultr returns Vultr', () {
        expect(RoomType.vultr.displayName, 'Vultr');
      });

      test('azure returns Azure', () {
        expect(RoomType.azure.displayName, 'Azure');
      });

      test('digitalOcean returns Digital Ocean', () {
        expect(RoomType.digitalOcean.displayName, 'Digital Ocean');
      });

      test('custom returns Custom', () {
        expect(RoomType.custom.displayName, 'Custom');
      });
    });

    test('all RoomType values have icon, color, and displayName', () {
      for (final type in RoomType.values) {
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
