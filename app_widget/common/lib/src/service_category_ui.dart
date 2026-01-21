import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';

/// UI utilities for ServiceCategory
extension ServiceCategoryUI on ServiceCategory {
  /// Get the icon for this service category
  IconData get icon {
    return switch (this) {
      ServiceCategory.compute => Icons.computer,
      ServiceCategory.storage => Icons.storage,
      ServiceCategory.database => Icons.table_chart,
      ServiceCategory.networking => Icons.hub,
      ServiceCategory.serverless => Icons.flash_on,
      ServiceCategory.container => Icons.view_in_ar,
      ServiceCategory.other => Icons.more_horiz,
    };
  }

  /// Get the color for this service category
  Color get color {
    return switch (this) {
      ServiceCategory.compute => AppColors.categoryCompute,
      ServiceCategory.storage => AppColors.categoryStorage,
      ServiceCategory.database => AppColors.categoryDatabase,
      ServiceCategory.networking => AppColors.categoryNetworking,
      ServiceCategory.serverless => AppColors.categoryServerless,
      ServiceCategory.container => AppColors.categoryContainer,
      ServiceCategory.other => AppColors.categoryOther,
    };
  }

  /// Get the display name for this service category
  String get displayName {
    return switch (this) {
      ServiceCategory.compute => 'Compute',
      ServiceCategory.storage => 'Storage',
      ServiceCategory.database => 'Database',
      ServiceCategory.networking => 'Networking',
      ServiceCategory.serverless => 'Serverless',
      ServiceCategory.container => 'Container',
      ServiceCategory.other => 'Other',
    };
  }
}
