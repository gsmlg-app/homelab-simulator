import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

void main() {
  group('WorldState', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const state = WorldState();
        expect(state.hoveredCell, isNull);
        expect(state.selectedEntityId, isNull);
        expect(state.interactableEntityId, isNull);
        expect(state.availableInteraction, InteractionType.none);
        expect(state.playerPosition, GameConstants.playerStartPosition);
      });

      test('creates instance with custom values', () {
        const state = WorldState(
          hoveredCell: GridPosition(5, 5),
          selectedEntityId: 'entity-123',
          interactableEntityId: 'entity-456',
          availableInteraction: InteractionType.terminal,
          playerPosition: GridPosition(10, 10),
        );
        expect(state.hoveredCell, const GridPosition(5, 5));
        expect(state.selectedEntityId, 'entity-123');
        expect(state.interactableEntityId, 'entity-456');
        expect(state.availableInteraction, InteractionType.terminal);
        expect(state.playerPosition, const GridPosition(10, 10));
      });
    });

    group('props', () {
      test('includes all fields', () {
        const state = WorldState(
          hoveredCell: GridPosition(1, 1),
          selectedEntityId: 'selected',
          interactableEntityId: 'interactable',
          availableInteraction: InteractionType.door,
          playerPosition: GridPosition(2, 2),
        );
        expect(state.props, [
          const GridPosition(1, 1),
          'selected',
          'interactable',
          InteractionType.door,
          const GridPosition(2, 2),
        ]);
      });

      test('default state has correct props', () {
        const state = WorldState();
        expect(state.props, [
          null,
          null,
          null,
          InteractionType.none,
          GameConstants.playerStartPosition,
        ]);
      });
    });

    group('equality', () {
      test('two default states are equal', () {
        const state1 = WorldState();
        const state2 = WorldState();
        expect(state1, equals(state2));
      });

      test('two states with same values are equal', () {
        const state1 = WorldState(
          hoveredCell: GridPosition(5, 5),
          selectedEntityId: 'entity-1',
        );
        const state2 = WorldState(
          hoveredCell: GridPosition(5, 5),
          selectedEntityId: 'entity-1',
        );
        expect(state1, equals(state2));
      });

      test('two states with different hoveredCell are not equal', () {
        const state1 = WorldState(hoveredCell: GridPosition(1, 1));
        const state2 = WorldState(hoveredCell: GridPosition(2, 2));
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different selectedEntityId are not equal', () {
        const state1 = WorldState(selectedEntityId: 'entity-1');
        const state2 = WorldState(selectedEntityId: 'entity-2');
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different availableInteraction are not equal', () {
        const state1 = WorldState(availableInteraction: InteractionType.door);
        const state2 = WorldState(
          availableInteraction: InteractionType.terminal,
        );
        expect(state1, isNot(equals(state2)));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated hoveredCell', () {
        const original = WorldState();
        final updated = original.copyWith(
          hoveredCell: const GridPosition(3, 3),
        );
        expect(updated.hoveredCell, const GridPosition(3, 3));
        expect(original.hoveredCell, isNull);
      });

      test('clears hoveredCell when clearHoveredCell is true', () {
        const original = WorldState(hoveredCell: GridPosition(5, 5));
        final updated = original.copyWith(clearHoveredCell: true);
        expect(updated.hoveredCell, isNull);
      });

      test('returns new instance with updated selectedEntityId', () {
        const original = WorldState();
        final updated = original.copyWith(selectedEntityId: 'new-entity');
        expect(updated.selectedEntityId, 'new-entity');
      });

      test('clears selectedEntityId when clearSelectedEntityId is true', () {
        const original = WorldState(selectedEntityId: 'entity-1');
        final updated = original.copyWith(clearSelectedEntityId: true);
        expect(updated.selectedEntityId, isNull);
      });

      test('returns new instance with updated interactableEntityId', () {
        const original = WorldState();
        final updated = original.copyWith(
          interactableEntityId: 'interactable-1',
        );
        expect(updated.interactableEntityId, 'interactable-1');
      });

      test(
        'clears interactableEntityId when clearInteractableEntityId is true',
        () {
          const original = WorldState(interactableEntityId: 'entity-1');
          final updated = original.copyWith(clearInteractableEntityId: true);
          expect(updated.interactableEntityId, isNull);
        },
      );

      test('returns new instance with updated availableInteraction', () {
        const original = WorldState();
        final updated = original.copyWith(
          availableInteraction: InteractionType.device,
        );
        expect(updated.availableInteraction, InteractionType.device);
      });

      test('returns new instance with updated playerPosition', () {
        const original = WorldState();
        final updated = original.copyWith(
          playerPosition: const GridPosition(7, 7),
        );
        expect(updated.playerPosition, const GridPosition(7, 7));
      });

      test('preserves unchanged values', () {
        const original = WorldState(
          hoveredCell: GridPosition(1, 1),
          selectedEntityId: 'entity-1',
          availableInteraction: InteractionType.door,
        );
        final updated = original.copyWith(selectedEntityId: 'entity-2');
        expect(updated.hoveredCell, const GridPosition(1, 1));
        expect(updated.selectedEntityId, 'entity-2');
        expect(updated.availableInteraction, InteractionType.door);
      });
    });

    group('getters', () {
      test('hasSelection returns true when selectedEntityId is not null', () {
        const state = WorldState(selectedEntityId: 'entity-1');
        expect(state.hasSelection, isTrue);
      });

      test('hasSelection returns false when selectedEntityId is null', () {
        const state = WorldState();
        expect(state.hasSelection, isFalse);
      });

      test('hasHover returns true when hoveredCell is not null', () {
        const state = WorldState(hoveredCell: GridPosition(1, 1));
        expect(state.hasHover, isTrue);
      });

      test('hasHover returns false when hoveredCell is null', () {
        const state = WorldState();
        expect(state.hasHover, isFalse);
      });

      test(
        'canInteract returns true when availableInteraction is not none',
        () {
          const state = WorldState(
            availableInteraction: InteractionType.terminal,
          );
          expect(state.canInteract, isTrue);
        },
      );

      test('canInteract returns false when availableInteraction is none', () {
        const state = WorldState();
        expect(state.canInteract, isFalse);
      });

      test('canInteract for all interaction types', () {
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

    group('hashCode', () {
      test('equal states have equal hashCodes', () {
        const state1 = WorldState(hoveredCell: GridPosition(1, 1));
        const state2 = WorldState(hoveredCell: GridPosition(1, 1));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('different states have different hashCodes', () {
        const state1 = WorldState(hoveredCell: GridPosition(1, 1));
        const state2 = WorldState(hoveredCell: GridPosition(2, 2));
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });
    });
  });
}
