import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

void main() {
  group('WorldEvent', () {
    group('CellHovered', () {
      test('creates instance with position', () {
        const event = CellHovered(GridPosition(5, 5));
        expect(event, isA<WorldEvent>());
        expect(event.position, const GridPosition(5, 5));
      });

      test('has position in props', () {
        const event = CellHovered(GridPosition(3, 7));
        expect(event.props, [const GridPosition(3, 7)]);
      });

      test('two instances with same position are equal', () {
        const event1 = CellHovered(GridPosition(5, 5));
        const event2 = CellHovered(GridPosition(5, 5));
        expect(event1, equals(event2));
      });

      test('two instances with different positions are not equal', () {
        const event1 = CellHovered(GridPosition(1, 1));
        const event2 = CellHovered(GridPosition(2, 2));
        expect(event1, isNot(equals(event2)));
      });
    });

    group('CellHoverEnded', () {
      test('creates instance', () {
        const event = CellHoverEnded();
        expect(event, isA<WorldEvent>());
      });

      test('has empty props', () {
        const event = CellHoverEnded();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = CellHoverEnded();
        const event2 = CellHoverEnded();
        expect(event1, equals(event2));
      });
    });

    group('EntitySelected', () {
      test('creates instance with entityId', () {
        const event = EntitySelected('entity-123');
        expect(event, isA<WorldEvent>());
        expect(event.entityId, 'entity-123');
      });

      test('has entityId in props', () {
        const event = EntitySelected('entity-456');
        expect(event.props, ['entity-456']);
      });

      test('two instances with same entityId are equal', () {
        const event1 = EntitySelected('entity-123');
        const event2 = EntitySelected('entity-123');
        expect(event1, equals(event2));
      });

      test('two instances with different entityIds are not equal', () {
        const event1 = EntitySelected('entity-1');
        const event2 = EntitySelected('entity-2');
        expect(event1, isNot(equals(event2)));
      });
    });

    group('ClearSelection', () {
      test('creates instance', () {
        const event = ClearSelection();
        expect(event, isA<WorldEvent>());
      });

      test('has empty props', () {
        const event = ClearSelection();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = ClearSelection();
        const event2 = ClearSelection();
        expect(event1, equals(event2));
      });
    });

    group('InteractionRequested', () {
      test('creates instance with entityId and type', () {
        const event = InteractionRequested(
          'entity-1',
          InteractionType.terminal,
        );
        expect(event, isA<WorldEvent>());
        expect(event.entityId, 'entity-1');
        expect(event.type, InteractionType.terminal);
      });

      test('has entityId and type in props', () {
        const event = InteractionRequested('entity-2', InteractionType.door);
        expect(event.props, ['entity-2', InteractionType.door]);
      });

      test('two instances with same parameters are equal', () {
        const event1 = InteractionRequested('entity-1', InteractionType.device);
        const event2 = InteractionRequested('entity-1', InteractionType.device);
        expect(event1, equals(event2));
      });

      test('two instances with different entityIds are not equal', () {
        const event1 = InteractionRequested('entity-1', InteractionType.device);
        const event2 = InteractionRequested('entity-2', InteractionType.device);
        expect(event1, isNot(equals(event2)));
      });

      test('two instances with different types are not equal', () {
        const event1 = InteractionRequested('entity-1', InteractionType.device);
        const event2 = InteractionRequested(
          'entity-1',
          InteractionType.terminal,
        );
        expect(event1, isNot(equals(event2)));
      });

      test('supports all interaction types', () {
        for (final type in InteractionType.values) {
          final event = InteractionRequested('entity', type);
          expect(event.type, type);
        }
      });
    });

    group('InteractionAvailable', () {
      test('creates instance with entityId and type', () {
        const event = InteractionAvailable('entity-1', InteractionType.door);
        expect(event, isA<WorldEvent>());
        expect(event.entityId, 'entity-1');
        expect(event.type, InteractionType.door);
      });

      test('has entityId and type in props', () {
        const event = InteractionAvailable(
          'entity-2',
          InteractionType.terminal,
        );
        expect(event.props, ['entity-2', InteractionType.terminal]);
      });

      test('two instances with same parameters are equal', () {
        const event1 = InteractionAvailable('entity-1', InteractionType.door);
        const event2 = InteractionAvailable('entity-1', InteractionType.door);
        expect(event1, equals(event2));
      });

      test('two instances with different entityIds are not equal', () {
        const event1 = InteractionAvailable('entity-1', InteractionType.door);
        const event2 = InteractionAvailable('entity-2', InteractionType.door);
        expect(event1, isNot(equals(event2)));
      });

      test('two instances with different types are not equal', () {
        const event1 = InteractionAvailable('entity-1', InteractionType.door);
        const event2 = InteractionAvailable(
          'entity-1',
          InteractionType.terminal,
        );
        expect(event1, isNot(equals(event2)));
      });
    });

    group('InteractionUnavailable', () {
      test('creates instance', () {
        const event = InteractionUnavailable();
        expect(event, isA<WorldEvent>());
      });

      test('has empty props', () {
        const event = InteractionUnavailable();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = InteractionUnavailable();
        const event2 = InteractionUnavailable();
        expect(event1, equals(event2));
      });
    });

    group('PlayerPositionUpdated', () {
      test('creates instance with position', () {
        const event = PlayerPositionUpdated(GridPosition(10, 10));
        expect(event, isA<WorldEvent>());
        expect(event.position, const GridPosition(10, 10));
      });

      test('has position in props', () {
        const event = PlayerPositionUpdated(GridPosition(5, 8));
        expect(event.props, [const GridPosition(5, 8)]);
      });

      test('two instances with same position are equal', () {
        const event1 = PlayerPositionUpdated(GridPosition(5, 5));
        const event2 = PlayerPositionUpdated(GridPosition(5, 5));
        expect(event1, equals(event2));
      });

      test('two instances with different positions are not equal', () {
        const event1 = PlayerPositionUpdated(GridPosition(1, 1));
        const event2 = PlayerPositionUpdated(GridPosition(2, 2));
        expect(event1, isNot(equals(event2)));
      });
    });

    group('type checking', () {
      test('all events are WorldEvent', () {
        const events = <WorldEvent>[
          CellHovered(GridPosition(0, 0)),
          CellHoverEnded(),
          EntitySelected('entity'),
          ClearSelection(),
          InteractionRequested('entity', InteractionType.door),
          InteractionAvailable('entity', InteractionType.terminal),
          InteractionUnavailable(),
          PlayerPositionUpdated(GridPosition(1, 1)),
        ];

        for (final event in events) {
          expect(event, isA<WorldEvent>());
        }
      });
    });
  });
}
