import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Events for WorldBloc (Flame-level)
sealed class WorldEvent extends Equatable {
  const WorldEvent();
}

/// Clear transient state when leaving the game.
class WorldReset extends WorldEvent {
  const WorldReset();

  @override
  List<Object?> get props => [];
}

/// Cell hovered by mouse/pointer
class CellHovered extends WorldEvent {
  final GridPosition position;
  const CellHovered(this.position);

  @override
  List<Object?> get props => [position];
}

/// Cell hover ended
class CellHoverEnded extends WorldEvent {
  const CellHoverEnded();

  @override
  List<Object?> get props => [];
}

/// Entity selected
class EntitySelected extends WorldEvent {
  final String entityId;
  const EntitySelected(this.entityId);

  @override
  List<Object?> get props => [entityId];
}

/// Clear selection
class ClearSelection extends WorldEvent {
  const ClearSelection();

  @override
  List<Object?> get props => [];
}

/// Interaction requested with entity
class InteractionRequested extends WorldEvent {
  final String entityId;
  final InteractionType type;
  const InteractionRequested(this.entityId, this.type);

  @override
  List<Object?> get props => [entityId, type];
}

/// Interaction available (player near interactable)
class InteractionAvailable extends WorldEvent {
  final String entityId;
  final InteractionType type;
  const InteractionAvailable(this.entityId, this.type);

  @override
  List<Object?> get props => [entityId, type];
}

/// Interaction no longer available
class InteractionUnavailable extends WorldEvent {
  const InteractionUnavailable();

  @override
  List<Object?> get props => [];
}

/// Player position updated (for proximity checks)
class PlayerPositionUpdated extends WorldEvent {
  final GridPosition position;
  const PlayerPositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

/// Replace room-local interaction context and discard the previous scene focus.
class WorldRoomChanged extends WorldEvent {
  final GridPosition terminalPosition;
  final GridPosition playerPosition;
  const WorldRoomChanged({
    required this.terminalPosition,
    required this.playerPosition,
  });
  @override
  List<Object?> get props => [terminalPosition, playerPosition];
}

/// One authoritative distance/ID-ranked scene focus, including accepted position.
class WorldInteractionProjected extends WorldEvent {
  final GridPosition playerPosition;
  final String? entityId;
  final InteractionType type;
  const WorldInteractionProjected({
    required this.playerPosition,
    this.entityId,
    required this.type,
  });
  @override
  List<Object?> get props => [playerPosition, entityId, type];
}
