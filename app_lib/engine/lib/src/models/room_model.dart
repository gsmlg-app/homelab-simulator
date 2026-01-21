import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'device_model.dart';
import 'door_model.dart';
import 'cloud_service_model.dart';

/// A room in the game world containing devices and cloud services
class RoomModel extends Equatable {
  final String id;
  final String name;
  final RoomType type;
  final String? parentId; // null for root rooms
  final int width;
  final int height;
  final GridPosition terminalPosition;
  final List<DeviceModel> devices;
  final List<DoorModel> doors;
  final List<CloudServiceModel> cloudServices;
  final String? regionCode; // e.g., "us-east-1" for provider region rooms

  const RoomModel({
    required this.id,
    required this.name,
    this.type = RoomType.serverRoom,
    this.parentId,
    this.width = GameConstants.roomWidth,
    this.height = GameConstants.roomHeight,
    this.terminalPosition = GameConstants.terminalPosition,
    this.devices = const [],
    this.doors = const [],
    this.cloudServices = const [],
    this.regionCode,
  });

  RoomModel copyWith({
    String? id,
    String? name,
    RoomType? type,
    String? parentId,
    bool clearParentId = false,
    int? width,
    int? height,
    GridPosition? terminalPosition,
    List<DeviceModel>? devices,
    List<DoorModel>? doors,
    List<CloudServiceModel>? cloudServices,
    String? regionCode,
    bool clearRegionCode = false,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      width: width ?? this.width,
      height: height ?? this.height,
      terminalPosition: terminalPosition ?? this.terminalPosition,
      devices: devices ?? this.devices,
      doors: doors ?? this.doors,
      cloudServices: cloudServices ?? this.cloudServices,
      regionCode: clearRegionCode ? null : (regionCode ?? this.regionCode),
    );
  }

  /// Check if a cell is occupied by any device or cloud service
  bool isCellOccupied(GridPosition cell) {
    return devices.any((device) => device.occupiesCell(cell)) ||
        cloudServices.any((service) => service.occupiesCell(cell));
  }

  /// Check if a cell has a door
  bool hasDoorAt(GridPosition cell) {
    return doors.any((door) => door.getPosition(width, height) == cell);
  }

  /// Get door at a specific cell.
  ///
  /// Returns the [DoorModel] at the given [cell] position, or `null` if
  /// no door exists at that position.
  DoorModel? getDoorAt(GridPosition cell) {
    for (final door in doors) {
      if (door.getPosition(width, height) == cell) return door;
    }
    return null;
  }

  /// Check if a position is valid for placing a device
  bool canPlaceDevice(
    GridPosition position,
    int deviceWidth,
    int deviceHeight,
  ) {
    for (var dx = 0; dx < deviceWidth; dx++) {
      for (var dy = 0; dy < deviceHeight; dy++) {
        final cell = GridPosition(position.x + dx, position.y + dy);
        if (!isWithinBounds(cell)) return false;
        if (isCellOccupied(cell)) return false;
        if (cell == terminalPosition) return false;
        if (hasDoorAt(cell)) return false;
      }
    }
    return true;
  }

  /// Get device at a specific cell.
  ///
  /// Returns the [DeviceModel] that occupies the given [cell] position,
  /// or `null` if no device is at that position. A device may occupy
  /// multiple cells based on its width and height.
  DeviceModel? getDeviceAt(GridPosition cell) {
    for (final device in devices) {
      if (device.occupiesCell(cell)) return device;
    }
    return null;
  }

  /// Get cloud service at a specific cell.
  ///
  /// Returns the [CloudServiceModel] that occupies the given [cell] position,
  /// or `null` if no cloud service is at that position. A cloud service
  /// occupies a single 1x1 cell.
  CloudServiceModel? getCloudServiceAt(GridPosition cell) {
    for (final service in cloudServices) {
      if (service.occupiesCell(cell)) return service;
    }
    return null;
  }

  /// Add a device to the room
  RoomModel addDevice(DeviceModel device) {
    return copyWith(devices: [...devices, device]);
  }

  /// Remove a device from the room
  RoomModel removeDevice(String deviceId) {
    return copyWith(devices: devices.where((d) => d.id != deviceId).toList());
  }

  /// Add a cloud service to the room
  RoomModel addCloudService(CloudServiceModel service) {
    return copyWith(cloudServices: [...cloudServices, service]);
  }

  /// Remove a cloud service from the room
  RoomModel removeCloudService(String serviceId) {
    return copyWith(
      cloudServices: cloudServices.where((s) => s.id != serviceId).toList(),
    );
  }

  /// Add a door to the room
  RoomModel addDoor(DoorModel door) {
    return copyWith(doors: [...doors, door]);
  }

  /// Remove a door from the room
  RoomModel removeDoor(String doorId) {
    return copyWith(doors: doors.where((d) => d.id != doorId).toList());
  }

  /// Get count of objects by category
  Map<String, int> getObjectCounts() {
    final counts = <String, int>{};

    // Count devices by type
    for (final device in devices) {
      final key = 'device:${device.type.name}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // Count cloud services by provider
    for (final service in cloudServices) {
      final key = '${service.provider.name}:${service.serviceType}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return counts;
  }

  /// Get total object count
  int get totalObjectCount => devices.length + cloudServices.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'parentId': parentId,
    'width': width,
    'height': height,
    'terminalPosition': terminalPosition.toJson(),
    'devices': devices.map((d) => d.toJson()).toList(),
    'doors': doors.map((d) => d.toJson()).toList(),
    'cloudServices': cloudServices.map((s) => s.toJson()).toList(),
    'regionCode': regionCode,
  };

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] != null
          ? RoomType.values.byName(json['type'] as String)
          : RoomType.serverRoom,
      parentId: json['parentId'] as String?,
      width: json['width'] as int? ?? GameConstants.roomWidth,
      height: json['height'] as int? ?? GameConstants.roomHeight,
      terminalPosition: json['terminalPosition'] != null
          ? GridPosition.fromJson(
              json['terminalPosition'] as Map<String, dynamic>,
            )
          : GameConstants.terminalPosition,
      devices:
          (json['devices'] as List<dynamic>?)
              ?.map((d) => DeviceModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      doors:
          (json['doors'] as List<dynamic>?)
              ?.map((d) => DoorModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      cloudServices:
          (json['cloudServices'] as List<dynamic>?)
              ?.map(
                (s) => CloudServiceModel.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
      regionCode: json['regionCode'] as String?,
    );
  }

  /// Create a default server room
  factory RoomModel.serverRoom({
    required String id,
    String name = 'Server Room',
  }) {
    return RoomModel(id: id, name: name, type: RoomType.serverRoom);
  }

  /// Create a provider room (AWS, GCP, etc.)
  factory RoomModel.provider({
    required String id,
    required RoomType type,
    required String name,
    String? parentId,
  }) {
    return RoomModel(id: id, name: name, type: type, parentId: parentId);
  }

  /// Create a region room (us-east-1, europe-west1, etc.)
  factory RoomModel.region({
    required String id,
    required String name,
    required String parentId,
    required String regionCode,
    required RoomType type,
  }) {
    return RoomModel(
      id: id,
      name: name,
      type: type,
      parentId: parentId,
      regionCode: regionCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    parentId,
    width,
    height,
    terminalPosition,
    devices,
    doors,
    cloudServices,
    regionCode,
  ];

  @override
  String toString() =>
      'RoomModel(id: $id, name: $name, type: $type, '
      'devices: ${devices.length}, doors: ${doors.length})';
}
