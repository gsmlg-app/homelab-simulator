import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';

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
      RoomType.serverRoom => Colors.grey,
      RoomType.aws => const Color(0xFFFF9900),
      RoomType.gcp => const Color(0xFF4285F4),
      RoomType.cloudflare => const Color(0xFFF38020),
      RoomType.vultr => const Color(0xFF007BFC),
      RoomType.azure => const Color(0xFF0078D4),
      RoomType.digitalOcean => const Color(0xFF0080FF),
      RoomType.custom => Colors.purple,
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
      RoomType.digitalOcean => 'Digital Ocean',
      RoomType.custom => 'Custom',
    };
  }
}
