import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';

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
      DeviceType.server => AppColors.deviceServer,
      DeviceType.computer => AppColors.deviceComputer,
      DeviceType.phone => AppColors.devicePhone,
      DeviceType.router => AppColors.deviceRouter,
      DeviceType.switch_ => AppColors.deviceSwitch,
      DeviceType.nas => AppColors.deviceNas,
      DeviceType.iot => AppColors.deviceIot,
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
