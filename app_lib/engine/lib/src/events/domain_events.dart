import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import '../models/device_template.dart';

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
