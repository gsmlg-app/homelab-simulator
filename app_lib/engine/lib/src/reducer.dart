import 'package:app_lib_core/app_lib_core.dart';
import 'models/game_model.dart';
import 'models/device_model.dart';
import 'models/device_template.dart';
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
