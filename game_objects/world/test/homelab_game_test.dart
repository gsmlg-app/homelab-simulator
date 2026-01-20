import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_world/game_objects_world.dart';

class MockGameBloc extends Mock implements GameBloc {}

class MockWorldBloc extends Mock implements WorldBloc {}

void main() {
  group('HomelabGame', () {
    late MockGameBloc gameBloc;
    late MockWorldBloc worldBloc;

    setUp(() {
      gameBloc = MockGameBloc();
      worldBloc = MockWorldBloc();

      // Setup default stubs
      when(() => gameBloc.state).thenReturn(const GameLoading());
      when(() => gameBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => worldBloc.state).thenReturn(const WorldState());
      when(() => worldBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    group('constructor', () {
      test('creates with required blocs', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.gameBloc, gameBloc);
        expect(game.worldBloc, worldBloc);
      });

      test('extends FlameGame', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isA<FlameGame>());
      });
    });

    group('bloc access', () {
      test('gameBloc is accessible', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.gameBloc, same(gameBloc));
      });

      test('worldBloc is accessible', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game.worldBloc, same(worldBloc));
      });
    });

    group('with GameReady state', () {
      late GameModel testModel;

      setUp(() {
        testModel = GameModel.initial();
        when(() => gameBloc.state).thenReturn(GameReady(testModel));
      });

      test('game can be created with ready state', () {
        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isNotNull);
        expect((gameBloc.state as GameReady).model, testModel);
      });
    });

    group('with custom model', () {
      test('uses model from gameBloc state', () {
        const customRoom = RoomModel(
          id: 'custom-room',
          name: 'Custom Room',
          type: RoomType.aws,
          width: 30,
          height: 20,
        );
        const customModel = GameModel(
          rooms: [customRoom],
          currentRoomId: 'custom-room',
          playerPosition: GridPosition(5, 5),
          credits: 500,
        );
        when(() => gameBloc.state).thenReturn(const GameReady(customModel));

        final game = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        expect(game, isNotNull);
        final state = gameBloc.state as GameReady;
        expect(state.model.credits, 500);
        expect(state.model.currentRoom.name, 'Custom Room');
      });
    });

    group('multiple instances', () {
      test('can create multiple independent games', () {
        final game1 = HomelabGame(gameBloc: gameBloc, worldBloc: worldBloc);

        final gameBloc2 = MockGameBloc();
        final worldBloc2 = MockWorldBloc();
        when(() => gameBloc2.state).thenReturn(const GameLoading());
        when(() => gameBloc2.stream).thenAnswer((_) => const Stream.empty());
        when(() => worldBloc2.state).thenReturn(const WorldState());
        when(() => worldBloc2.stream).thenAnswer((_) => const Stream.empty());

        final game2 = HomelabGame(gameBloc: gameBloc2, worldBloc: worldBloc2);

        expect(game1.gameBloc, isNot(same(game2.gameBloc)));
        expect(game1.worldBloc, isNot(same(game2.worldBloc)));
      });
    });
  });

  group('GamepadButton integration', () {
    test('HomelabGame can use GamepadButton values', () {
      // Ensure GamepadButton enum is exported and usable
      expect(GamepadButton.south, isA<GamepadButton>());
      expect(GamepadButton.east, isA<GamepadButton>());
      expect(GamepadButton.north, isA<GamepadButton>());
      expect(GamepadButton.west, isA<GamepadButton>());
      expect(GamepadButton.start, isA<GamepadButton>());
    });
  });

  group('Direction integration', () {
    test('HomelabGame can use Direction values', () {
      expect(Direction.up, isA<Direction>());
      expect(Direction.down, isA<Direction>());
      expect(Direction.left, isA<Direction>());
      expect(Direction.right, isA<Direction>());
      expect(Direction.none, isA<Direction>());
    });
  });

  group('InteractionType integration', () {
    test('HomelabGame can use InteractionType values', () {
      expect(InteractionType.none, isA<InteractionType>());
      expect(InteractionType.door, isA<InteractionType>());
      expect(InteractionType.terminal, isA<InteractionType>());
      expect(InteractionType.device, isA<InteractionType>());
    });
  });

  group('PlacementMode integration', () {
    test('HomelabGame can use PlacementMode values', () {
      expect(PlacementMode.none, isA<PlacementMode>());
      expect(PlacementMode.placing, isA<PlacementMode>());
    });
  });

  group('GridPosition helpers', () {
    test('gridToPixel converts correctly', () {
      final (x, y) = gridToPixel(const GridPosition(5, 3));
      expect(x, 5 * GameConstants.tileSize);
      expect(y, 3 * GameConstants.tileSize);
    });

    test('pixelToGrid converts correctly', () {
      const tileSize = GameConstants.tileSize;
      final gridPos = pixelToGrid(5 * tileSize + 10, 3 * tileSize + 10);
      expect(gridPos.x, 5);
      expect(gridPos.y, 3);
    });

    test('isWithinBounds returns true for valid positions', () {
      expect(isWithinBounds(const GridPosition(0, 0)), isTrue);
      expect(
        isWithinBounds(
          const GridPosition(
            GameConstants.roomWidth - 1,
            GameConstants.roomHeight - 1,
          ),
        ),
        isTrue,
      );
    });

    test('isWithinBounds returns false for out of bounds positions', () {
      expect(isWithinBounds(const GridPosition(-1, 0)), isFalse);
      expect(isWithinBounds(const GridPosition(0, -1)), isFalse);
      expect(
        isWithinBounds(const GridPosition(GameConstants.roomWidth, 0)),
        isFalse,
      );
      expect(
        isWithinBounds(const GridPosition(0, GameConstants.roomHeight)),
        isFalse,
      );
    });
  });

  group('GameConstants', () {
    test('has valid room dimensions', () {
      expect(GameConstants.roomWidth, greaterThan(0));
      expect(GameConstants.roomHeight, greaterThan(0));
      expect(GameConstants.tileSize, greaterThan(0));
    });

    test('has valid player start position', () {
      const startPos = GameConstants.playerStartPosition;
      expect(startPos.x, greaterThanOrEqualTo(0));
      expect(startPos.y, greaterThanOrEqualTo(0));
      expect(startPos.x, lessThan(GameConstants.roomWidth));
      expect(startPos.y, lessThan(GameConstants.roomHeight));
    });
  });
}
