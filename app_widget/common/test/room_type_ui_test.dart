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
      test('serverRoom returns roomServer color', () {
        expect(RoomType.serverRoom.color, AppColors.roomServer);
      });

      test('aws returns providerAws color', () {
        expect(RoomType.aws.color, AppColors.providerAws);
      });

      test('gcp returns providerGcp color', () {
        expect(RoomType.gcp.color, AppColors.providerGcp);
      });

      test('cloudflare returns providerCloudflare color', () {
        expect(RoomType.cloudflare.color, AppColors.providerCloudflare);
      });

      test('vultr returns providerVultr color', () {
        expect(RoomType.vultr.color, AppColors.providerVultr);
      });

      test('azure returns providerAzure color', () {
        expect(RoomType.azure.color, AppColors.providerAzure);
      });

      test('digitalOcean returns providerDigitalOcean color', () {
        expect(RoomType.digitalOcean.color, AppColors.providerDigitalOcean);
      });

      test('custom returns roomCustom color', () {
        expect(RoomType.custom.color, AppColors.roomCustom);
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
