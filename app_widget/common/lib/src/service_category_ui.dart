import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';

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
      ServiceCategory.compute => const Color(0xFF3498DB),
      ServiceCategory.storage => const Color(0xFF27AE60),
      ServiceCategory.database => const Color(0xFFF39C12),
      ServiceCategory.networking => const Color(0xFF9B59B6),
      ServiceCategory.serverless => const Color(0xFFE74C3C),
      ServiceCategory.container => const Color(0xFF1ABC9C),
      ServiceCategory.other => const Color(0xFF607D8B),
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
