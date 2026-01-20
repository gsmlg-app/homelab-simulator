import 'package:app_lib_core/app_lib_core.dart';
import 'models/game_model.dart';
import 'models/room_model.dart';
import 'models/door_model.dart';
import 'models/device_model.dart';
import 'models/device_template.dart';
import 'models/cloud_service_model.dart';
import 'events/domain_events.dart';

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
    DevicePlaced(:final templateId, :final position) =>
      _handleDevicePlaced(model, templateId, position),
    DeviceRemoved(:final deviceId) => _handleDeviceRemoved(model, deviceId),
    CreditsChanged(:final amount) =>
      model.copyWith(credits: model.credits + amount),
    GameModeChanged(:final mode) => model.copyWith(gameMode: mode),
    GameLoaded() => model,
    RoomEntered(:final roomId, :final spawnPosition) =>
      model.enterRoom(roomId, spawnPosition),
    RoomAdded(
      :final name,
      :final type,
      :final regionCode,
      :final doorSide,
      :final doorPosition
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
      :final position
    ) =>
      _handleCloudServicePlaced(
          model, provider, category, serviceType, name, position),
    CloudServiceRemoved(:final serviceId) =>
      _handleCloudServiceRemoved(model, serviceId),
  };
}

GameModel _handlePlayerMoved(GameModel model, GridPosition newPosition) {
  if (!isWithinBounds(newPosition)) return model;
  if (model.currentRoom.isCellOccupied(newPosition)) return model;
  return model.copyWith(playerPosition: newPosition);
}

GameModel _handleDevicePlaced(
  GameModel model,
  String templateId,
  GridPosition position,
) {
  final template = defaultDeviceTemplates.firstWhere(
    (t) => t.id == templateId,
    orElse: () => defaultDeviceTemplates.first,
  );

  if (!model.currentRoom.canPlaceDevice(
    position,
    template.width,
    template.height,
  )) {
    return model;
  }

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

  return model.copyWith(
    credits: model.credits - template.cost,
    placementMode: PlacementMode.none,
    clearSelectedTemplate: true,
  ).updateRoom(updatedRoom);
}

GameModel _handleDeviceRemoved(GameModel model, String deviceId) {
  final device = model.currentRoom.devices.firstWhere(
    (d) => d.id == deviceId,
    orElse: () => throw StateError('Device not found'),
  );

  final template = defaultDeviceTemplates.firstWhere(
    (t) => t.id == device.templateId,
    orElse: () => defaultDeviceTemplates.first,
  );

  final updatedRoom = model.currentRoom.removeDevice(deviceId);

  return model.copyWith(
    credits: model.credits + (template.cost ~/ 2),
  ).updateRoom(updatedRoom);
}

GameModel _handleRoomAdded(
  GameModel model,
  String name,
  RoomType type,
  String? regionCode,
  WallSide doorSide,
  int doorPosition,
) {
  // Generate IDs for new room and doors
  final newRoomId = generateRoomId();
  final doorInCurrentRoom = generateDoorId();
  final doorInNewRoom = generateDoorId();

  // Create the new room with a door back to current room
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

  // Add door to current room pointing to new room
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
  return model.updateRoom(updatedRoom).copyWith(
        placementMode: PlacementMode.none,
        clearSelectedTemplate: true,
        clearSelectedCloudService: true,
      );
}

GameModel _handleCloudServiceRemoved(GameModel model, String serviceId) {
  final updatedRoom = model.currentRoom.removeCloudService(serviceId);
  return model.updateRoom(updatedRoom);
}
