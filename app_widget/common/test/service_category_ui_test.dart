import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('ServiceCategoryUI extension', () {
    group('icon', () {
      test('compute returns computer icon', () {
        expect(ServiceCategory.compute.icon, Icons.computer);
      });

      test('storage returns storage icon', () {
        expect(ServiceCategory.storage.icon, Icons.storage);
      });

      test('database returns table_chart icon', () {
        expect(ServiceCategory.database.icon, Icons.table_chart);
      });

      test('networking returns hub icon', () {
        expect(ServiceCategory.networking.icon, Icons.hub);
      });

      test('serverless returns flash_on icon', () {
        expect(ServiceCategory.serverless.icon, Icons.flash_on);
      });

      test('container returns view_in_ar icon', () {
        expect(ServiceCategory.container.icon, Icons.view_in_ar);
      });

      test('other returns more_horiz icon', () {
        expect(ServiceCategory.other.icon, Icons.more_horiz);
      });
    });

    group('color', () {
      test('compute returns blue', () {
        expect(ServiceCategory.compute.color, AppColors.categoryCompute);
      });

      test('storage returns green', () {
        expect(ServiceCategory.storage.color, AppColors.categoryStorage);
      });

      test('database returns orange', () {
        expect(ServiceCategory.database.color, AppColors.categoryDatabase);
      });

      test('networking returns purple', () {
        expect(ServiceCategory.networking.color, AppColors.categoryNetworking);
      });

      test('serverless returns red', () {
        expect(ServiceCategory.serverless.color, AppColors.categoryServerless);
      });

      test('container returns teal', () {
        expect(ServiceCategory.container.color, AppColors.categoryContainer);
      });

      test('other returns blue grey', () {
        expect(ServiceCategory.other.color, AppColors.categoryOther);
      });
    });

    group('displayName', () {
      test('compute returns Compute', () {
        expect(ServiceCategory.compute.displayName, 'Compute');
      });

      test('storage returns Storage', () {
        expect(ServiceCategory.storage.displayName, 'Storage');
      });

      test('database returns Database', () {
        expect(ServiceCategory.database.displayName, 'Database');
      });

      test('networking returns Networking', () {
        expect(ServiceCategory.networking.displayName, 'Networking');
      });

      test('serverless returns Serverless', () {
        expect(ServiceCategory.serverless.displayName, 'Serverless');
      });

      test('container returns Container', () {
        expect(ServiceCategory.container.displayName, 'Container');
      });

      test('other returns Other', () {
        expect(ServiceCategory.other.displayName, 'Other');
      });
    });

    test('all ServiceCategory values have icon, color, and displayName', () {
      for (final category in ServiceCategory.values) {
        expect(
          category.icon,
          isA<IconData>(),
          reason: '$category should have icon',
        );
        expect(
          category.color,
          isA<Color>(),
          reason: '$category should have color',
        );
        expect(
          category.displayName,
          isNotEmpty,
          reason: '$category should have displayName',
        );
      }
    });
  });
}
