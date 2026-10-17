import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

void main() {
  test(
    'room context resets focus and checks the active terminal at its spawn',
    () async {
      final bloc = WorldBloc();
      addTearDown(bloc.close);
      bloc.add(const CellHovered(GridPosition(3, 3)));
      bloc.add(const EntitySelected('old-device'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const WorldRoomChanged(
          terminalPosition: GridPosition(20, 12),
          playerPosition: GridPosition(20, 11),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.hoveredCell, isNull);
      expect(bloc.state.selectedEntityId, isNull);
      expect(bloc.state.playerPosition, const GridPosition(20, 11));
      expect(bloc.state.availableInteraction, InteractionType.terminal);
      expect(bloc.terminalPosition, const GridPosition(20, 12));
      bloc.add(const PlayerPositionUpdated(GridPosition(2, 1)));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.canInteract, isFalse);
    },
  );
}
