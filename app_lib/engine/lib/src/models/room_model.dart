import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'device_model.dart';

/// A room in the game world containing devices
class RoomModel extends Equatable {
  final String id;
  final String name;
  final int width;
  final int height;
  final GridPosition terminalPosition;
  final List<DeviceModel> devices;

  const RoomModel({
    required this.id,
    required this.name,
    this.width = GameConstants.roomWidth,
    this.height = GameConstants.roomHeight,
    this.terminalPosition = GameConstants.terminalPosition,
    this.devices = const [],
  });

  RoomModel copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    GridPosition? terminalPosition,
    List<DeviceModel>? devices,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      terminalPosition: terminalPosition ?? this.terminalPosition,
      devices: devices ?? this.devices,
    );
  }

  /// Check if a cell is occupied by any device
  bool isCellOccupied(GridPosition cell) {
    return devices.any((device) => device.occupiesCell(cell));
  }

  /// Check if a position is valid for placing a device
  bool canPlaceDevice(GridPosition position, int width, int height) {
    for (var dx = 0; dx < width; dx++) {
      for (var dy = 0; dy < height; dy++) {
        final cell = GridPosition(position.x + dx, position.y + dy);
        if (!isWithinBounds(cell)) return false;
        if (isCellOccupied(cell)) return false;
        if (cell == terminalPosition) return false;
      }
    }
    return true;
  }

  /// Get device at a specific cell
  DeviceModel? getDeviceAt(GridPosition cell) {
    for (final device in devices) {
      if (device.occupiesCell(cell)) return device;
    }
    return null;
  }

  /// Add a device to the room
  RoomModel addDevice(DeviceModel device) {
    return copyWith(devices: [...devices, device]);
  }

  /// Remove a device from the room
  RoomModel removeDevice(String deviceId) {
    return copyWith(
      devices: devices.where((d) => d.id != deviceId).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'terminalPosition': terminalPosition.toJson(),
        'devices': devices.map((d) => d.toJson()).toList(),
      };

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int? ?? GameConstants.roomWidth,
      height: json['height'] as int? ?? GameConstants.roomHeight,
      terminalPosition: json['terminalPosition'] != null
          ? GridPosition.fromJson(json['terminalPosition'] as Map<String, dynamic>)
          : GameConstants.terminalPosition,
      devices: (json['devices'] as List<dynamic>?)
              ?.map((d) => DeviceModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props =>
      [id, name, width, height, terminalPosition, devices];
}
