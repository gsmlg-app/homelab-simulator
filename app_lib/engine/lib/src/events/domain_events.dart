import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import '../models/device_template.dart';
import '../models/door_model.dart';
import '../models/cloud_service_model.dart';

/// Base class for domain events
sealed class DomainEvent extends Equatable {
  const DomainEvent();
}

/// Player moved to a new position
class PlayerMoved extends DomainEvent {
  final GridPosition newPosition;
  const PlayerMoved(this.newPosition);

  @override
  List<Object?> get props => [newPosition];
}

/// Shop opened/closed
class ShopToggled extends DomainEvent {
  final bool isOpen;
  const ShopToggled(this.isOpen);

  @override
  List<Object?> get props => [isOpen];
}

/// Device template selected for placement
class TemplateSelected extends DomainEvent {
  final DeviceTemplate template;
  const TemplateSelected(this.template);

  @override
  List<Object?> get props => [template];
}

/// Placement mode changed
class PlacementModeChanged extends DomainEvent {
  final PlacementMode mode;
  const PlacementModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Device placed in room
class DevicePlaced extends DomainEvent {
  final String templateId;
  final GridPosition position;
  const DevicePlaced({required this.templateId, required this.position});

  @override
  List<Object?> get props => [templateId, position];
}

/// Device removed from room
class DeviceRemoved extends DomainEvent {
  final String deviceId;
  const DeviceRemoved(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

/// Credits changed
class CreditsChanged extends DomainEvent {
  final int amount;
  const CreditsChanged(this.amount);

  @override
  List<Object?> get props => [amount];
}

/// Game mode changed
class GameModeChanged extends DomainEvent {
  final GameMode mode;
  const GameModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Game loaded from save
class GameLoaded extends DomainEvent {
  const GameLoaded();

  @override
  List<Object?> get props => [];
}

/// Player entered a different room via door
class RoomEntered extends DomainEvent {
  final String roomId;
  final GridPosition spawnPosition;
  const RoomEntered({required this.roomId, required this.spawnPosition});

  @override
  List<Object?> get props => [roomId, spawnPosition];
}

/// Room added as a child of current room
class RoomAdded extends DomainEvent {
  final String name;
  final RoomType type;
  final String? regionCode;
  final WallSide doorSide;
  final int doorPosition;

  const RoomAdded({
    required this.name,
    required this.type,
    this.regionCode,
    required this.doorSide,
    required this.doorPosition,
  });

  @override
  List<Object?> get props => [name, type, regionCode, doorSide, doorPosition];
}

/// Room removed
class RoomRemoved extends DomainEvent {
  final String roomId;
  const RoomRemoved(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

/// Cloud service template selected for placement
class CloudServiceSelected extends DomainEvent {
  final CloudServiceTemplate template;
  const CloudServiceSelected(this.template);

  @override
  List<Object?> get props => [template];
}

/// Cloud service placed in room
class CloudServicePlaced extends DomainEvent {
  final CloudProvider provider;
  final ServiceCategory category;
  final String serviceType;
  final String name;
  final GridPosition position;

  const CloudServicePlaced({
    required this.provider,
    required this.category,
    required this.serviceType,
    required this.name,
    required this.position,
  });

  @override
  List<Object?> get props => [provider, category, serviceType, name, position];
}

/// Cloud service removed from room
class CloudServiceRemoved extends DomainEvent {
  final String serviceId;
  const CloudServiceRemoved(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}
