import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// UI utilities for CloudProvider
extension CloudProviderUI on CloudProvider {
  /// Get the icon for this cloud provider
  IconData get icon {
    return switch (this) {
      CloudProvider.aws => Icons.cloud,
      CloudProvider.gcp => Icons.cloud_circle,
      CloudProvider.cloudflare => Icons.security,
      CloudProvider.vultr => Icons.dns,
      CloudProvider.azure => Icons.cloud_queue,
      CloudProvider.digitalOcean => Icons.water_drop,
      CloudProvider.none => Icons.cloud_off,
    };
  }

  /// Get the color for this cloud provider
  Color get color {
    return switch (this) {
      CloudProvider.aws => const Color(0xFFFF9900),
      CloudProvider.gcp => const Color(0xFF4285F4),
      CloudProvider.cloudflare => const Color(0xFFF38020),
      CloudProvider.vultr => const Color(0xFF007BFC),
      CloudProvider.azure => const Color(0xFF0078D4),
      CloudProvider.digitalOcean => const Color(0xFF0080FF),
      CloudProvider.none => Colors.grey,
    };
  }

  /// Get the display name for this cloud provider
  String get displayName {
    return switch (this) {
      CloudProvider.aws => 'AWS',
      CloudProvider.gcp => 'GCP',
      CloudProvider.cloudflare => 'Cloudflare',
      CloudProvider.vultr => 'Vultr',
      CloudProvider.azure => 'Azure',
      CloudProvider.digitalOcean => 'DigitalOcean',
      CloudProvider.none => 'None',
    };
  }
}
