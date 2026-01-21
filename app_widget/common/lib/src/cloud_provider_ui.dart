import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';

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
      CloudProvider.aws => AppColors.providerAws,
      CloudProvider.gcp => AppColors.providerGcp,
      CloudProvider.cloudflare => AppColors.providerCloudflare,
      CloudProvider.vultr => AppColors.providerVultr,
      CloudProvider.azure => AppColors.providerAzure,
      CloudProvider.digitalOcean => AppColors.providerDigitalOcean,
      CloudProvider.none => AppColors.providerNone,
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
