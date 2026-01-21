import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('CloudProviderUI extension', () {
    group('icon', () {
      test('aws returns cloud icon', () {
        expect(CloudProvider.aws.icon, Icons.cloud);
      });

      test('gcp returns cloud_circle icon', () {
        expect(CloudProvider.gcp.icon, Icons.cloud_circle);
      });

      test('cloudflare returns security icon', () {
        expect(CloudProvider.cloudflare.icon, Icons.security);
      });

      test('vultr returns dns icon', () {
        expect(CloudProvider.vultr.icon, Icons.dns);
      });

      test('azure returns cloud_queue icon', () {
        expect(CloudProvider.azure.icon, Icons.cloud_queue);
      });

      test('digitalOcean returns water_drop icon', () {
        expect(CloudProvider.digitalOcean.icon, Icons.water_drop);
      });

      test('none returns cloud_off icon', () {
        expect(CloudProvider.none.icon, Icons.cloud_off);
      });
    });

    group('color', () {
      test('aws returns providerAws color', () {
        expect(CloudProvider.aws.color, AppColors.providerAws);
      });

      test('gcp returns providerGcp color', () {
        expect(CloudProvider.gcp.color, AppColors.providerGcp);
      });

      test('cloudflare returns providerCloudflare color', () {
        expect(CloudProvider.cloudflare.color, AppColors.providerCloudflare);
      });

      test('vultr returns providerVultr color', () {
        expect(CloudProvider.vultr.color, AppColors.providerVultr);
      });

      test('azure returns providerAzure color', () {
        expect(CloudProvider.azure.color, AppColors.providerAzure);
      });

      test('digitalOcean returns providerDigitalOcean color', () {
        expect(
          CloudProvider.digitalOcean.color,
          AppColors.providerDigitalOcean,
        );
      });

      test('none returns providerNone color', () {
        expect(CloudProvider.none.color, AppColors.providerNone);
      });
    });

    group('displayName', () {
      test('aws returns AWS', () {
        expect(CloudProvider.aws.displayName, 'AWS');
      });

      test('gcp returns GCP', () {
        expect(CloudProvider.gcp.displayName, 'GCP');
      });

      test('cloudflare returns Cloudflare', () {
        expect(CloudProvider.cloudflare.displayName, 'Cloudflare');
      });

      test('vultr returns Vultr', () {
        expect(CloudProvider.vultr.displayName, 'Vultr');
      });

      test('azure returns Azure', () {
        expect(CloudProvider.azure.displayName, 'Azure');
      });

      test('digitalOcean returns DigitalOcean', () {
        expect(CloudProvider.digitalOcean.displayName, 'DigitalOcean');
      });

      test('none returns None', () {
        expect(CloudProvider.none.displayName, 'None');
      });
    });

    test('all CloudProvider values have icon, color, and displayName', () {
      for (final provider in CloudProvider.values) {
        expect(
          provider.icon,
          isA<IconData>(),
          reason: '$provider should have icon',
        );
        expect(
          provider.color,
          isA<Color>(),
          reason: '$provider should have color',
        );
        expect(
          provider.displayName,
          isNotEmpty,
          reason: '$provider should have displayName',
        );
      }
    });
  });
}
