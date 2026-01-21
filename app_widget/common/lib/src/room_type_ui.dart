import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';

/// UI utilities for RoomType
extension RoomTypeUI on RoomType {
  /// Get the icon for this room type
  IconData get icon {
    return switch (this) {
      RoomType.serverRoom => Icons.dns,
      RoomType.aws => Icons.cloud,
      RoomType.gcp => Icons.cloud_circle,
      RoomType.cloudflare => Icons.security,
      RoomType.vultr => Icons.dns,
      RoomType.azure => Icons.cloud_queue,
      RoomType.digitalOcean => Icons.water_drop,
      RoomType.custom => Icons.folder_special,
    };
  }

  /// Get the color for this room type
  Color get color {
    return switch (this) {
      RoomType.serverRoom => AppColors.roomServer,
      RoomType.aws => AppColors.providerAws,
      RoomType.gcp => AppColors.providerGcp,
      RoomType.cloudflare => AppColors.providerCloudflare,
      RoomType.vultr => AppColors.providerVultr,
      RoomType.azure => AppColors.providerAzure,
      RoomType.digitalOcean => AppColors.providerDigitalOcean,
      RoomType.custom => AppColors.roomCustom,
    };
  }

  /// Get the display name for this room type
  String get displayName {
    return switch (this) {
      RoomType.serverRoom => 'Server Room',
      RoomType.aws => 'AWS',
      RoomType.gcp => 'GCP',
      RoomType.cloudflare => 'Cloudflare',
      RoomType.vultr => 'Vultr',
      RoomType.azure => 'Azure',
      RoomType.digitalOcean => 'DigitalOcean',
      RoomType.custom => 'Custom',
    };
  }
}
