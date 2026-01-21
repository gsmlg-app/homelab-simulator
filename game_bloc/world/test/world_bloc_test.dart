import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

void main() {
  group('WorldBloc', () {
    late WorldBloc bloc;

    setUp(() {
      bloc = WorldBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state.hoveredCell, isNull);
      expect(bloc.state.selectedEntityId, isNull);
      expect(bloc.state.interactableEntityId, isNull);
      expect(bloc.state.availableInteraction, InteractionType.none);
      expect(bloc.state.playerPosition, GameConstants.playerStartPosition);
    });

    test('uses custom terminal position', () {
      final customBloc = WorldBloc(terminalPosition: const GridPosition(5, 5));
      expect(customBloc.terminalPosition, const GridPosition(5, 5));
      customBloc.close();
    });

    group('CellHovered', () {
      blocTest<WorldBloc, WorldState>(
        'emits state with hovered cell',
        build: () => WorldBloc(),
        act: (bloc) => bloc.add(const CellHovered(GridPosition(3, 4))),
        expect: () => [const WorldState(hoveredCell: GridPosition(3, 4))],
      );

      blocTest<WorldBloc, WorldState>(
        'updates hovered cell when changed',
        build: () => WorldBloc(),
        act: (bloc) {
          bloc.add(const CellHovered(GridPosition(3, 4)));
          bloc.add(const CellHovered(GridPosition(5, 6)));
        },
        expect: () => [
          const WorldState(hoveredCell: GridPosition(3, 4)),
          const WorldState(hoveredCell: GridPosition(5, 6)),
        ],
      );
    });

    group('CellHoverEnded', () {
      blocTest<WorldBloc, WorldState>(
        'clears hovered cell',
        build: () => WorldBloc(),
        seed: () => const WorldState(hoveredCell: GridPosition(3, 4)),
        act: (bloc) => bloc.add(const CellHoverEnded()),
        expect: () => [const WorldState(hoveredCell: null)],
      );
    });

    group('EntitySelected', () {
      blocTest<WorldBloc, WorldState>(
        'emits state with selected entity',
        build: () => WorldBloc(),
        act: (bloc) => bloc.add(const EntitySelected('device-1')),
        expect: () => [const WorldState(selectedEntityId: 'device-1')],
      );

      blocTest<WorldBloc, WorldState>(
        'updates selected entity when changed',
        build: () => WorldBloc(),
        act: (bloc) {
          bloc.add(const EntitySelected('device-1'));
          bloc.add(const EntitySelected('device-2'));
        },
        expect: () => [
          const WorldState(selectedEntityId: 'device-1'),
          const WorldState(selectedEntityId: 'device-2'),
        ],
      );
    });

    group('ClearSelection', () {
      blocTest<WorldBloc, WorldState>(
        'clears selected entity',
        build: () => WorldBloc(),
        seed: () => const WorldState(selectedEntityId: 'device-1'),
        act: (bloc) => bloc.add(const ClearSelection()),
        expect: () => [const WorldState(selectedEntityId: null)],
      );
    });

    group('InteractionRequested', () {
      blocTest<WorldBloc, WorldState>(
        'does not change state (handled by listeners)',
        build: () => WorldBloc(),
        act: (bloc) => bloc.add(
          const InteractionRequested(
            GameConstants.terminalEntityId,
            InteractionType.terminal,
          ),
        ),
        expect: () => <WorldState>[],
      );
    });

    group('InteractionAvailable', () {
      blocTest<WorldBloc, WorldState>(
        'emits state with interactable entity',
        build: () => WorldBloc(),
        act: (bloc) => bloc.add(
          const InteractionAvailable('device-1', InteractionType.device),
        ),
        expect: () => [
          const WorldState(
            interactableEntityId: 'device-1',
            availableInteraction: InteractionType.device,
          ),
        ],
      );
    });

    group('InteractionUnavailable', () {
      blocTest<WorldBloc, WorldState>(
        'clears interactable entity and interaction type',
        build: () => WorldBloc(),
        seed: () => const WorldState(
          interactableEntityId: 'device-1',
          availableInteraction: InteractionType.device,
        ),
        act: (bloc) => bloc.add(const InteractionUnavailable()),
        expect: () => [
          const WorldState(
            interactableEntityId: null,
            availableInteraction: InteractionType.none,
          ),
        ],
      );
    });

    group('PlayerPositionUpdated', () {
      blocTest<WorldBloc, WorldState>(
        'updates player position',
        build: () => WorldBloc(),
        act: (bloc) =>
            bloc.add(const PlayerPositionUpdated(GridPosition(5, 5))),
        expect: () => [const WorldState(playerPosition: GridPosition(5, 5))],
      );

      blocTest<WorldBloc, WorldState>(
        'sets terminal interaction when adjacent to terminal',
        build: () => WorldBloc(terminalPosition: GameConstants.terminalPosition),
        act: (bloc) =>
            bloc.add(const PlayerPositionUpdated(GridPosition(2, 3))),
        expect: () => [
          const WorldState(
            playerPosition: GridPosition(2, 3),
            interactableEntityId: GameConstants.terminalEntityId,
            availableInteraction: InteractionType.terminal,
          ),
        ],
      );

      blocTest<WorldBloc, WorldState>(
        'sets terminal interaction when at terminal position',
        build: () => WorldBloc(terminalPosition: GameConstants.terminalPosition),
        act: (bloc) =>
            bloc.add(const PlayerPositionUpdated(GridPosition(2, 2))),
        expect: () => [
          const WorldState(
            playerPosition: GridPosition(2, 2),
            interactableEntityId: GameConstants.terminalEntityId,
            availableInteraction: InteractionType.terminal,
          ),
        ],
      );

      blocTest<WorldBloc, WorldState>(
        'clears terminal interaction when moving away from terminal',
        build: () => WorldBloc(terminalPosition: GameConstants.terminalPosition),
        seed: () => const WorldState(
          playerPosition: GridPosition(2, 3),
          interactableEntityId: GameConstants.terminalEntityId,
          availableInteraction: InteractionType.terminal,
        ),
        act: (bloc) =>
            bloc.add(const PlayerPositionUpdated(GridPosition(10, 10))),
        expect: () => [
          const WorldState(
            playerPosition: GridPosition(10, 10),
            interactableEntityId: null,
            availableInteraction: InteractionType.none,
          ),
        ],
      );

      blocTest<WorldBloc, WorldState>(
        'does not clear device interaction when moving away from terminal',
        build: () => WorldBloc(terminalPosition: GameConstants.terminalPosition),
        seed: () => const WorldState(
          playerPosition: GridPosition(5, 5),
          interactableEntityId: 'device-1',
          availableInteraction: InteractionType.device,
        ),
        act: (bloc) =>
            bloc.add(const PlayerPositionUpdated(GridPosition(6, 6))),
        expect: () => [
          const WorldState(
            playerPosition: GridPosition(6, 6),
            interactableEntityId: 'device-1',
            availableInteraction: InteractionType.device,
          ),
        ],
      );
    });
  });

  group('WorldState', () {
    test('initial state has correct defaults', () {
      const state = WorldState();
      expect(state.hoveredCell, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.interactableEntityId, isNull);
      expect(state.availableInteraction, InteractionType.none);
      expect(state.playerPosition, GameConstants.playerStartPosition);
    });

    test('hasSelection returns true when entity selected', () {
      const state = WorldState(selectedEntityId: 'device-1');
      expect(state.hasSelection, isTrue);
    });

    test('hasSelection returns false when no entity selected', () {
      const state = WorldState();
      expect(state.hasSelection, isFalse);
    });

    test('hasHover returns true when cell hovered', () {
      const state = WorldState(hoveredCell: GridPosition(3, 4));
      expect(state.hasHover, isTrue);
    });

    test('hasHover returns false when no cell hovered', () {
      const state = WorldState();
      expect(state.hasHover, isFalse);
    });

    test('canInteract returns true when interaction available', () {
      const state = WorldState(availableInteraction: InteractionType.terminal);
      expect(state.canInteract, isTrue);
    });

    test('canInteract returns false when no interaction available', () {
      const state = WorldState();
      expect(state.canInteract, isFalse);
    });

    group('copyWith', () {
      test('updates hoveredCell', () {
        const original = WorldState();
        final updated = original.copyWith(
          hoveredCell: const GridPosition(3, 4),
        );
        expect(updated.hoveredCell, const GridPosition(3, 4));
      });

      test('clears hoveredCell with clearHoveredCell flag', () {
        const original = WorldState(hoveredCell: GridPosition(3, 4));
        final updated = original.copyWith(clearHoveredCell: true);
        expect(updated.hoveredCell, isNull);
      });

      test('updates selectedEntityId', () {
        const original = WorldState();
        final updated = original.copyWith(selectedEntityId: 'device-1');
        expect(updated.selectedEntityId, 'device-1');
      });

      test('clears selectedEntityId with clearSelectedEntityId flag', () {
        const original = WorldState(selectedEntityId: 'device-1');
        final updated = original.copyWith(clearSelectedEntityId: true);
        expect(updated.selectedEntityId, isNull);
      });

      test('updates interactableEntityId', () {
        const original = WorldState();
        final updated = original.copyWith(
          interactableEntityId: GameConstants.terminalEntityId,
        );
        expect(updated.interactableEntityId, GameConstants.terminalEntityId);
      });

      test(
        'clears interactableEntityId with clearInteractableEntityId flag',
        () {
          const original = WorldState(
            interactableEntityId: GameConstants.terminalEntityId,
          );
          final updated = original.copyWith(clearInteractableEntityId: true);
          expect(updated.interactableEntityId, isNull);
        },
      );

      test('updates availableInteraction', () {
        const original = WorldState();
        final updated = original.copyWith(
          availableInteraction: InteractionType.terminal,
        );
        expect(updated.availableInteraction, InteractionType.terminal);
      });

      test('updates playerPosition', () {
        const original = WorldState();
        final updated = original.copyWith(
          playerPosition: const GridPosition(5, 5),
        );
        expect(updated.playerPosition, const GridPosition(5, 5));
      });

      test('preserves unmodified fields', () {
        const original = WorldState(
          hoveredCell: GridPosition(3, 4),
          selectedEntityId: 'device-1',
          interactableEntityId: GameConstants.terminalEntityId,
          availableInteraction: InteractionType.terminal,
          playerPosition: GridPosition(5, 5),
        );
        final updated = original.copyWith();
        expect(updated, original);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const state1 = WorldState(
          hoveredCell: GridPosition(3, 4),
          selectedEntityId: 'device-1',
        );
        const state2 = WorldState(
          hoveredCell: GridPosition(3, 4),
          selectedEntityId: 'device-1',
        );
        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('different states are not equal', () {
        const state1 = WorldState(selectedEntityId: 'device-1');
        const state2 = WorldState(selectedEntityId: 'device-2');
        expect(state1, isNot(state2));
      });

      test('states can be used in Set collections', () {
        const state1 = WorldState(selectedEntityId: 'device-1');
        const state2 = WorldState(selectedEntityId: 'device-1');
        const state3 = WorldState(selectedEntityId: 'device-2');

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final stateSet = {state1, state2, state3};
        expect(stateSet.length, 2);
        expect(stateSet.contains(state1), isTrue);
        expect(stateSet.contains(state3), isTrue);
      });

      test('states can be used as Map keys', () {
        const state1 = WorldState(selectedEntityId: 'device-1');
        const state2 = WorldState(selectedEntityId: 'device-1');

        final stateMap = <WorldState, String>{state1: 'first'};
        stateMap[state2] = 'second';

        expect(stateMap.length, 1);
        expect(stateMap[state1], 'second');
      });
    });

    group('edge cases', () {
      test('copyWith clears multiple fields simultaneously', () {
        const original = WorldState(
          hoveredCell: GridPosition(3, 4),
          selectedEntityId: 'device-1',
          interactableEntityId: GameConstants.terminalEntityId,
          availableInteraction: InteractionType.terminal,
        );

        final cleared = original.copyWith(
          clearHoveredCell: true,
          clearSelectedEntityId: true,
          clearInteractableEntityId: true,
          availableInteraction: InteractionType.none,
        );

        expect(cleared.hoveredCell, isNull);
        expect(cleared.selectedEntityId, isNull);
        expect(cleared.interactableEntityId, isNull);
        expect(cleared.availableInteraction, InteractionType.none);
        expect(cleared.playerPosition, original.playerPosition);
      });

      test('copyWith clear flags take precedence over new values', () {
        const original = WorldState(hoveredCell: GridPosition(3, 4));

        final result = original.copyWith(
          hoveredCell: const GridPosition(5, 5),
          clearHoveredCell: true,
        );

        // clearHoveredCell should take precedence
        expect(result.hoveredCell, isNull);
      });

      test('props includes all fields', () {
        const state = WorldState(
          hoveredCell: GridPosition(3, 4),
          selectedEntityId: 'device-1',
          interactableEntityId: GameConstants.terminalEntityId,
          availableInteraction: InteractionType.terminal,
          playerPosition: GridPosition(5, 5),
        );

        expect(state.props.length, 5);
        expect(state.props, contains(const GridPosition(3, 4)));
        expect(state.props, contains('device-1'));
        expect(state.props, contains(GameConstants.terminalEntityId));
        expect(state.props, contains(InteractionType.terminal));
        expect(state.props, contains(const GridPosition(5, 5)));
      });

      test('all InteractionTypes affect canInteract correctly', () {
        for (final type in InteractionType.values) {
          final state = WorldState(availableInteraction: type);
          if (type == InteractionType.none) {
            expect(state.canInteract, isFalse);
          } else {
            expect(state.canInteract, isTrue);
          }
        }
      });
    });
  });

  group('WorldEvent', () {
    group('CellHovered', () {
      test('equal events are equal', () {
        const event1 = CellHovered(GridPosition(3, 4));
        const event2 = CellHovered(GridPosition(3, 4));
        expect(event1, event2);
      });

      test('different events are not equal', () {
        const event1 = CellHovered(GridPosition(3, 4));
        const event2 = CellHovered(GridPosition(5, 6));
        expect(event1, isNot(event2));
      });
    });

    group('CellHoverEnded', () {
      test('all instances are equal', () {
        const event1 = CellHoverEnded();
        const event2 = CellHoverEnded();
        expect(event1, event2);
      });
    });

    group('EntitySelected', () {
      test('equal events are equal', () {
        const event1 = EntitySelected('device-1');
        const event2 = EntitySelected('device-1');
        expect(event1, event2);
      });

      test('different events are not equal', () {
        const event1 = EntitySelected('device-1');
        const event2 = EntitySelected('device-2');
        expect(event1, isNot(event2));
      });
    });

    group('ClearSelection', () {
      test('all instances are equal', () {
        const event1 = ClearSelection();
        const event2 = ClearSelection();
        expect(event1, event2);
      });
    });

    group('InteractionRequested', () {
      test('equal events are equal', () {
        const event1 = InteractionRequested(
          GameConstants.terminalEntityId,
          InteractionType.terminal,
        );
        const event2 = InteractionRequested(
          GameConstants.terminalEntityId,
          InteractionType.terminal,
        );
        expect(event1, event2);
      });

      test('different events are not equal', () {
        const event1 = InteractionRequested(
          GameConstants.terminalEntityId,
          InteractionType.terminal,
        );
        const event2 = InteractionRequested('device-1', InteractionType.device);
        expect(event1, isNot(event2));
      });
    });

    group('InteractionAvailable', () {
      test('equal events are equal', () {
        const event1 = InteractionAvailable('device-1', InteractionType.device);
        const event2 = InteractionAvailable('device-1', InteractionType.device);
        expect(event1, event2);
      });

      test('different events are not equal', () {
        const event1 = InteractionAvailable('device-1', InteractionType.device);
        const event2 = InteractionAvailable('device-2', InteractionType.device);
        expect(event1, isNot(event2));
      });
    });

    group('InteractionUnavailable', () {
      test('all instances are equal', () {
        const event1 = InteractionUnavailable();
        const event2 = InteractionUnavailable();
        expect(event1, event2);
      });
    });

    group('PlayerPositionUpdated', () {
      test('equal events are equal', () {
        const event1 = PlayerPositionUpdated(GridPosition(5, 5));
        const event2 = PlayerPositionUpdated(GridPosition(5, 5));
        expect(event1, event2);
      });

      test('different events are not equal', () {
        const event1 = PlayerPositionUpdated(GridPosition(5, 5));
        const event2 = PlayerPositionUpdated(GridPosition(6, 6));
        expect(event1, isNot(event2));
      });
    });

    group('edge cases', () {
      test('CellHovered events can be used in Set collections', () {
        const event1 = CellHovered(GridPosition(3, 4));
        const event2 = CellHovered(GridPosition(3, 4));
        const event3 = CellHovered(GridPosition(5, 5));

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final eventSet = {event1, event2, event3};
        expect(eventSet.length, 2);
      });

      test('EntitySelected events can be used as Map keys', () {
        const event1 = EntitySelected('device-1');
        const event2 = EntitySelected('device-1');

        final eventMap = <EntitySelected, String>{event1: 'first'};
        eventMap[event2] = 'second';

        expect(eventMap.length, 1);
        expect(eventMap[event1], 'second');
      });

      test('InteractionAvailable covers all interaction types', () {
        for (final type in InteractionType.values) {
          const entityId = 'test-entity';
          final event = InteractionAvailable(entityId, type);
          expect(event.entityId, entityId);
          expect(event.type, type);
        }
      });

      test('InteractionRequested covers all interaction types', () {
        for (final type in InteractionType.values) {
          const entityId = 'test-entity';
          final event = InteractionRequested(entityId, type);
          expect(event.entityId, entityId);
          expect(event.type, type);
        }
      });

      test('CellHovered props contains position', () {
        const event = CellHovered(GridPosition(3, 4));
        expect(event.props.length, 1);
        expect(event.props, contains(const GridPosition(3, 4)));
      });

      test('EntitySelected props contains entityId', () {
        const event = EntitySelected('device-1');
        expect(event.props.length, 1);
        expect(event.props, contains('device-1'));
      });

      test('InteractionAvailable props contains entityId and type', () {
        const event = InteractionAvailable('device-1', InteractionType.device);
        expect(event.props.length, 2);
        expect(event.props, contains('device-1'));
        expect(event.props, contains(InteractionType.device));
      });

      test('InteractionRequested props contains entityId and type', () {
        const event = InteractionRequested(
          GameConstants.terminalEntityId,
          InteractionType.terminal,
        );
        expect(event.props.length, 2);
        expect(event.props, contains(GameConstants.terminalEntityId));
        expect(event.props, contains(InteractionType.terminal));
      });

      test('PlayerPositionUpdated props contains position', () {
        const event = PlayerPositionUpdated(GridPosition(5, 5));
        expect(event.props.length, 1);
        expect(event.props, contains(const GridPosition(5, 5)));
      });

      test('singleton events have empty props', () {
        const cellHoverEnded = CellHoverEnded();
        const clearSelection = ClearSelection();
        const interactionUnavailable = InteractionUnavailable();

        expect(cellHoverEnded.props, isEmpty);
        expect(clearSelection.props, isEmpty);
        expect(interactionUnavailable.props, isEmpty);
      });
    });
  });
}
