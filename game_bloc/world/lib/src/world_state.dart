import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// State for WorldBloc (Flame-level)
class WorldState extends Equatable {
  final GridPosition? hoveredCell;
  final String? selectedEntityId;
  final String? interactableEntityId;
  final InteractionType availableInteraction;
  final GridPosition playerPosition;

  const WorldState({
    this.hoveredCell,
    this.selectedEntityId,
    this.interactableEntityId,
    this.availableInteraction = InteractionType.none,
    this.playerPosition = GameConstants.playerStartPosition,
  });

  WorldState copyWith({
    GridPosition? hoveredCell,
    bool clearHoveredCell = false,
    String? selectedEntityId,
    bool clearSelectedEntityId = false,
    String? interactableEntityId,
    bool clearInteractableEntityId = false,
    InteractionType? availableInteraction,
    GridPosition? playerPosition,
  }) {
    return WorldState(
      hoveredCell: clearHoveredCell ? null : (hoveredCell ?? this.hoveredCell),
      selectedEntityId: clearSelectedEntityId
          ? null
          : (selectedEntityId ?? this.selectedEntityId),
      interactableEntityId: clearInteractableEntityId
          ? null
          : (interactableEntityId ?? this.interactableEntityId),
      availableInteraction: availableInteraction ?? this.availableInteraction,
      playerPosition: playerPosition ?? this.playerPosition,
    );
  }

  bool get hasSelection => selectedEntityId != null;
  bool get hasHover => hoveredCell != null;
  bool get canInteract => availableInteraction != InteractionType.none;

  @override
  List<Object?> get props => [
    hoveredCell,
    selectedEntityId,
    interactableEntityId,
    availableInteraction,
    playerPosition,
  ];
}
