import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// UI utilities for DeviceType
extension DeviceTypeUI on DeviceType {
  /// Get the icon for this device type
  IconData get icon {
    return switch (this) {
      DeviceType.server => Icons.dns,
      DeviceType.computer => Icons.computer,
      DeviceType.phone => Icons.phone_android,
      DeviceType.router => Icons.router,
      DeviceType.switch_ => Icons.hub,
      DeviceType.nas => Icons.storage,
      DeviceType.iot => Icons.sensors,
    };
  }

  /// Get the color for this device type
  Color get color {
    return switch (this) {
      DeviceType.server => const Color(0xFF3498DB),
      DeviceType.computer => const Color(0xFF9B59B6),
      DeviceType.phone => const Color(0xFFE74C3C),
      DeviceType.router => const Color(0xFFF39C12),
      DeviceType.switch_ => const Color(0xFF1ABC9C),
      DeviceType.nas => const Color(0xFF34495E),
      DeviceType.iot => const Color(0xFF27AE60),
    };
  }

  /// Get the display name for this device type
  String get displayName {
    return switch (this) {
      DeviceType.server => 'Server',
      DeviceType.computer => 'Computer',
      DeviceType.phone => 'Phone',
      DeviceType.router => 'Router',
      DeviceType.switch_ => 'Switch',
      DeviceType.nas => 'NAS',
      DeviceType.iot => 'IoT Device',
    };
  }
}
