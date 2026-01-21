import 'package:app_lib_core/app_lib_core.dart';
import 'models/game_model.dart';
import 'models/room_model.dart';
import 'models/door_model.dart';
import 'models/device_model.dart';
import 'models/device_template.dart';
import 'models/cloud_service_model.dart';
import 'events/domain_events.dart';

/// Finds a device template by ID.
///
/// Returns null if the template is not found.
DeviceTemplate? findDeviceTemplateById(String templateId) {
  for (final template in defaultDeviceTemplates) {
    if (template.id == templateId) return template;
  }
  return null;
}

/// Pure function reducer for game state
GameModel reduce(GameModel model, DomainEvent event) {
  return switch (event) {
    PlayerMoved(:final newPosition) => _handlePlayerMoved(model, newPosition),
    ShopToggled(:final isOpen) => model.copyWith(shopOpen: isOpen),
    TemplateSelected(:final template) => model.copyWith(
      selectedTemplate: template,
      placementMode: PlacementMode.placing,
    ),
    PlacementModeChanged(:final mode) => model.copyWith(
      placementMode: mode,
      clearSelectedTemplate: mode == PlacementMode.none,
      clearSelectedCloudService: mode == PlacementMode.none,
    ),
    DevicePlaced(:final templateId, :final position) => _handleDevicePlaced(
      model,
      templateId,
      position,
    ),
    DeviceRemoved(:final deviceId) => _handleDeviceRemoved(model, deviceId),
    CreditsChanged(:final amount) => model.copyWith(
      credits: model.credits + amount,
    ),
    GameModeChanged(:final mode) => model.copyWith(gameMode: mode),
    GameLoaded() => model,
    RoomEntered(:final roomId, :final spawnPosition) => model.enterRoom(
      roomId,
      spawnPosition,
    ),
    RoomAdded(
      :final name,
      :final type,
      :final regionCode,
      :final doorSide,
      :final doorPosition,
    ) =>
      _handleRoomAdded(model, name, type, regionCode, doorSide, doorPosition),
    RoomRemoved(:final roomId) => model.removeRoom(roomId),
    CloudServiceSelected(:final template) => model.copyWith(
      selectedCloudService: template,
      placementMode: PlacementMode.placing,
      clearSelectedTemplate: true,
    ),
    CloudServicePlaced(
      :final provider,
      :final category,
      :final serviceType,
      :final name,
      :final position,
    ) =>
      _handleCloudServicePlaced(
        model,
        provider,
        category,
        serviceType,
        name,
        position,
      ),
    CloudServiceRemoved(:final serviceId) => _handleCloudServiceRemoved(
      model,
      serviceId,
    ),
  };
}

GameModel _handlePlayerMoved(GameModel model, GridPosition newPosition) {
  if (!isWithinBounds(newPosition)) return model;
  if (model.currentRoom.isCellOccupied(newPosition)) return model;
  return model.copyWith(playerPosition: newPosition);
}

/// Places a device at the specified position if valid.
///
/// Validation order:
/// 1. Position must be valid (not occupied, within bounds, not on terminal/door)
/// 2. Player must have sufficient credits
///
/// Returns unchanged model if any validation fails.
GameModel _handleDevicePlaced(
  GameModel model,
  String templateId,
  GridPosition position,
) {
  final template = findDeviceTemplateById(templateId);
  if (template == null) {
    return model; // Template not found, no-op
  }

  // Validate position first (check bounds, occupancy, terminal, doors)
  if (!model.currentRoom.canPlaceDevice(
    position,
    template.width,
    template.height,
  )) {
    return model;
  }

  // Then validate credits
  if (model.credits < template.cost) {
    return model;
  }

  final device = DeviceModel(
    id: generateDeviceId(),
    templateId: templateId,
    name: template.name,
    type: template.type,
    position: position,
    width: template.width,
    height: template.height,
  );

  final updatedRoom = model.currentRoom.addDevice(device);

  return model
      .copyWith(
        credits: model.credits - template.cost,
        placementMode: PlacementMode.none,
        clearSelectedTemplate: true,
      )
      .updateRoom(updatedRoom);
}

GameModel _handleDeviceRemoved(GameModel model, String deviceId) {
  // Find device - return unchanged if not found
  final deviceIndex = model.currentRoom.devices.indexWhere(
    (d) => d.id == deviceId,
  );
  if (deviceIndex == -1) {
    return model; // Device not found, no-op
  }

  final device = model.currentRoom.devices[deviceIndex];
  final template = findDeviceTemplateById(device.templateId);

  final updatedRoom = model.currentRoom.removeDevice(deviceId);

  // Refund half the cost if template is known, otherwise just remove device
  final refund = template != null ? template.cost ~/ 2 : 0;
  return model.copyWith(credits: model.credits + refund).updateRoom(updatedRoom);
}

/// Adds a new room connected to the current room via bidirectional doors.
///
/// Creates:
/// 1. A new room with `parentId` set to current room
/// 2. A door in the current room on `doorSide` pointing to the new room
/// 3. A door in the new room on the opposite wall pointing back
///
/// For example, if `doorSide` is [WallSide.right], the current room gets
/// a door on its right wall, and the new room gets a door on its left wall.
GameModel _handleRoomAdded(
  GameModel model,
  String name,
  RoomType type,
  String? regionCode,
  WallSide doorSide,
  int doorPosition,
) {
  final newRoomId = generateRoomId();
  final doorInCurrentRoom = generateDoorId();
  final doorInNewRoom = generateDoorId();

  // Create new room with return door on the opposite wall
  final newRoom = RoomModel(
    id: newRoomId,
    name: name,
    type: type,
    parentId: model.currentRoomId,
    regionCode: regionCode,
    doors: [
      DoorModel(
        id: doorInNewRoom,
        targetRoomId: model.currentRoomId,
        wallSide: doorSide.opposite,
        wallPosition: doorPosition,
      ),
    ],
  );

  // Add door in current room to the new room
  final updatedCurrentRoom = model.currentRoom.addDoor(
    DoorModel(
      id: doorInCurrentRoom,
      targetRoomId: newRoomId,
      wallSide: doorSide,
      wallPosition: doorPosition,
    ),
  );

  return model.updateRoom(updatedCurrentRoom).addRoom(newRoom);
}

GameModel _handleCloudServicePlaced(
  GameModel model,
  CloudProvider provider,
  ServiceCategory category,
  String serviceType,
  String name,
  GridPosition position,
) {
  // Check if placement is valid
  if (!model.currentRoom.canPlaceDevice(position, 1, 1)) {
    return model;
  }

  final service = CloudServiceModel(
    id: generateEntityId(),
    name: name,
    provider: provider,
    category: category,
    serviceType: serviceType,
    position: position,
  );

  final updatedRoom = model.currentRoom.addCloudService(service);
  return model
      .updateRoom(updatedRoom)
      .copyWith(
        placementMode: PlacementMode.none,
        clearSelectedTemplate: true,
        clearSelectedCloudService: true,
      );
}

GameModel _handleCloudServiceRemoved(GameModel model, String serviceId) {
  final updatedRoom = model.currentRoom.removeCloudService(serviceId);
  return model.updateRoom(updatedRoom);
}
