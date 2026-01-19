import 'package:bloc/bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';

import 'world_event.dart';
import 'world_state.dart';

/// Flame-level BLoC for world state
///
/// Manages:
/// - Selection state
/// - Hover cell
/// - Interaction focus (terminal/device)
/// - Transient in-world signals
class WorldBloc extends Bloc<WorldEvent, WorldState> {
  final GridPosition terminalPosition;

  WorldBloc({
    this.terminalPosition = GameConstants.terminalPosition,
  }) : super(const WorldState()) {
    on<CellHovered>(_onCellHovered);
    on<CellHoverEnded>(_onCellHoverEnded);
    on<EntitySelected>(_onEntitySelected);
    on<ClearSelection>(_onClearSelection);
    on<InteractionRequested>(_onInteractionRequested);
    on<InteractionAvailable>(_onInteractionAvailable);
    on<InteractionUnavailable>(_onInteractionUnavailable);
    on<PlayerPositionUpdated>(_onPlayerPositionUpdated);
  }

  void _onCellHovered(CellHovered event, Emitter<WorldState> emit) {
    emit(state.copyWith(hoveredCell: event.position));
  }

  void _onCellHoverEnded(CellHoverEnded event, Emitter<WorldState> emit) {
    emit(state.copyWith(clearHoveredCell: true));
  }

  void _onEntitySelected(EntitySelected event, Emitter<WorldState> emit) {
    emit(state.copyWith(selectedEntityId: event.entityId));
  }

  void _onClearSelection(ClearSelection event, Emitter<WorldState> emit) {
    emit(state.copyWith(clearSelectedEntityId: true));
  }

  void _onInteractionRequested(
    InteractionRequested event,
    Emitter<WorldState> emit,
  ) {
    // This event is typically handled by listeners (e.g., to open shop)
    // State change is minimal here
  }

  void _onInteractionAvailable(
    InteractionAvailable event,
    Emitter<WorldState> emit,
  ) {
    emit(state.copyWith(
      interactableEntityId: event.entityId,
      availableInteraction: event.type,
    ));
  }

  void _onInteractionUnavailable(
    InteractionUnavailable event,
    Emitter<WorldState> emit,
  ) {
    emit(state.copyWith(
      clearInteractableEntityId: true,
      availableInteraction: InteractionType.none,
    ));
  }

  void _onPlayerPositionUpdated(
    PlayerPositionUpdated event,
    Emitter<WorldState> emit,
  ) {
    final newState = state.copyWith(playerPosition: event.position);

    // Check proximity to terminal
    if (event.position.isAdjacentTo(terminalPosition) ||
        event.position == terminalPosition) {
      emit(newState.copyWith(
        interactableEntityId: 'terminal',
        availableInteraction: InteractionType.terminal,
      ));
    } else if (state.interactableEntityId == 'terminal') {
      emit(newState.copyWith(
        clearInteractableEntityId: true,
        availableInteraction: InteractionType.none,
      ));
    } else {
      emit(newState);
    }
  }
}
