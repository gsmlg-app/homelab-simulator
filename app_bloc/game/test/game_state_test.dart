import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';

void main() {
  group('GameState', () {
    group('GameLoading', () {
      test('creates instance', () {
        const state = GameLoading();
        expect(state, isA<GameState>());
        expect(state, isA<GameLoading>());
      });

      test('has empty props', () {
        const state = GameLoading();
        expect(state.props, isEmpty);
      });

      test('two instances are equal', () {
        const state1 = GameLoading();
        const state2 = GameLoading();
        expect(state1, equals(state2));
      });

      test('hashCode is consistent', () {
        const state1 = GameLoading();
        const state2 = GameLoading();
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });

    group('GameReady', () {
      late GameModel model;
      late GameModel otherModel;

      setUp(() {
        model = GameModel.initial();
        otherModel = GameModel.initial().copyWith(credits: 500);
      });

      test('creates instance with model', () {
        final state = GameReady(model);
        expect(state, isA<GameState>());
        expect(state, isA<GameReady>());
        expect(state.model, model);
      });

      test('has model in props', () {
        final state = GameReady(model);
        expect(state.props, [model]);
      });

      test('two instances with same model are equal', () {
        final state1 = GameReady(model);
        final state2 = GameReady(model);
        expect(state1, equals(state2));
      });

      test('two instances with different models are not equal', () {
        final state1 = GameReady(model);
        final state2 = GameReady(otherModel);
        expect(state1, isNot(equals(state2)));
      });

      test('hashCode differs with different models', () {
        final state1 = GameReady(model);
        final state2 = GameReady(otherModel);
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });

      test('model is accessible', () {
        final state = GameReady(model);
        expect(state.model.credits, GameConstants.startingCredits);
      });
    });

    group('GameError', () {
      test('creates instance with message', () {
        const state = GameError('Test error');
        expect(state, isA<GameState>());
        expect(state, isA<GameError>());
        expect(state.message, 'Test error');
      });

      test('has message in props', () {
        const state = GameError('Test error');
        expect(state.props, ['Test error']);
      });

      test('two instances with same message are equal', () {
        const state1 = GameError('Test error');
        const state2 = GameError('Test error');
        expect(state1, equals(state2));
      });

      test('two instances with different messages are not equal', () {
        const state1 = GameError('Error 1');
        const state2 = GameError('Error 2');
        expect(state1, isNot(equals(state2)));
      });

      test('hashCode differs with different messages', () {
        const state1 = GameError('Error 1');
        const state2 = GameError('Error 2');
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });

      test('handles empty message', () {
        const state = GameError('');
        expect(state.message, '');
        expect(state.props, ['']);
      });

      test('handles long message', () {
        const longMessage =
            'This is a very long error message that spans '
            'multiple lines and contains lots of detail about what went wrong';
        const state = GameError(longMessage);
        expect(state.message, longMessage);
      });
    });

    group('type checking', () {
      test('GameLoading is not GameReady', () {
        const state = GameLoading();
        expect(state is GameReady, isFalse);
        expect(state is GameError, isFalse);
      });

      test('GameReady is not GameLoading', () {
        final state = GameReady(GameModel.initial());
        expect(state is GameLoading, isFalse);
        expect(state is GameError, isFalse);
      });

      test('GameError is not GameLoading or GameReady', () {
        const state = GameError('error');
        expect(state is GameLoading, isFalse);
        expect(state is GameReady, isFalse);
      });

      test('all states are GameState', () {
        const loading = GameLoading();
        final ready = GameReady(GameModel.initial());
        const error = GameError('error');

        expect(loading, isA<GameState>());
        expect(ready, isA<GameState>());
        expect(error, isA<GameState>());
      });
    });
  });
}
