import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:homelab_simulator/screens/game_screen.dart';

// Mock GameBloc
class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {
  @override
  GameModel? get currentModel {
    final s = state;
    return s is GameReady ? s.model : null;
  }
}

// Mock WorldBloc
class MockWorldBloc extends MockBloc<WorldEvent, WorldState>
    implements WorldBloc {}

void main() {
  group('GameScreen', () {
    late MockGameBloc mockGameBloc;
    late MockWorldBloc mockWorldBloc;

    setUp(() {
      mockGameBloc = MockGameBloc();
      mockWorldBloc = MockWorldBloc();
    });

    Widget buildSubject({Size? screenSize}) {
      final widget = MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<GameBloc>.value(value: mockGameBloc),
            BlocProvider<WorldBloc>.value(value: mockWorldBloc),
          ],
          child: const GameScreen(),
        ),
      );

      // If screen size specified, wrap in a SizedBox to control viewport
      if (screenSize != null) {
        return MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: widget,
        );
      }
      return widget;
    }

    group('loading state', () {
      testWidgets('shows loading indicator when GameLoading', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading Homelab...'), findsOneWidget);
      });

      testWidgets('loading text is white70', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        final textWidget = tester.widget<Text>(find.text('Loading Homelab...'));
        expect(textWidget.style?.color, Colors.white70);
      });

      testWidgets('loading indicator and text are centered', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Both should be inside a Center widget
        expect(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Center),
          ),
          findsOneWidget,
        );
      });
    });

    group('error state', () {
      testWidgets('shows error message when GameError', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Test error')]),
          initialState: const GameError('Test error'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Error: Test error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('error icon is red and sized 48', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Test error')]),
          initialState: const GameError('Test error'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error));
        expect(iconWidget.color, AppColors.redAccent);
        expect(iconWidget.size, 48);
      });

      testWidgets('error text is red', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Test error')]),
          initialState: const GameError('Test error'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        final textWidget = tester.widget<Text>(find.text('Error: Test error'));
        expect(textWidget.style?.color, AppColors.redAccent);
      });

      testWidgets('retry button dispatches GameInitialize', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Test error')]),
          initialState: const GameError('Test error'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        await tester.tap(find.text('Retry'));
        await tester.pump();

        verify(() => mockGameBloc.add(const GameInitialize())).called(1);
      });

      testWidgets('displays different error messages', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([
            const GameError('Network connection failed'),
          ]),
          initialState: const GameError('Network connection failed'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.text('Error: Network connection failed'), findsOneWidget);
      });

      testWidgets('error components are centered', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Test error')]),
          initialState: const GameError('Test error'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(
          find.ancestor(
            of: find.byIcon(Icons.error),
            matching: find.byType(Center),
          ),
          findsOneWidget,
        );
      });
    });

    group('ready state', () {
      testWidgets('renders game content when GameReady', (tester) async {
        final gameModel = GameModel.initial();

        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([GameReady(gameModel)]),
          initialState: GameReady(gameModel),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Should not show loading or error
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Error:'), findsNothing);

        // Should have Scaffold as the root widget
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('does not show loading indicator when ready', (tester) async {
        final gameModel = GameModel.initial();

        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([GameReady(gameModel)]),
          initialState: GameReady(gameModel),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('state transitions', () {
      testWidgets('transitions from loading to error', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([
            const GameLoading(),
            const GameError('Something went wrong'),
          ]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());

        // Initially loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Pump to process the stream (use pump instead of pumpAndSettle to
        // avoid timeout from Flame game loop)
        await tester.pump(const Duration(milliseconds: 100));

        // Now error
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Error: Something went wrong'), findsOneWidget);
      });

      testWidgets('retry from error dispatches event', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('Failed')]),
          initialState: const GameError('Failed'),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        await tester.tap(find.text('Retry'));
        await tester.pump();

        verify(() => mockGameBloc.add(const GameInitialize())).called(1);
      });
    });

    group('widget structure', () {
      testWidgets('has Scaffold at root', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('BlocBuilder rebuilds on state change', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Verify BlocBuilder is used
        expect(
          find.byWidgetPredicate(
            (widget) => widget is BlocBuilder<GameBloc, GameState>,
          ),
          findsOneWidget,
        );
      });
    });

    group('StatefulWidget', () {
      testWidgets('creates state correctly', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Verify GameScreen is a StatefulWidget
        expect(find.byType(GameScreen), findsOneWidget);
        final state = tester.state<State<GameScreen>>(find.byType(GameScreen));
        expect(state, isNotNull);
      });

      testWidgets('GameScreen has const constructor', (_) async {
        // Verify GameScreen can be instantiated with const
        const screen1 = GameScreen();
        const screen2 = GameScreen();
        expect(screen1.key, screen2.key);
      });
    });

    group('error message variations', () {
      testWidgets('displays empty error message', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameError('')]),
          initialState: const GameError(''),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.text('Error: '), findsOneWidget);
      });

      testWidgets('displays long error message', (tester) async {
        final longError = 'Very long error message: ${'x' * 100}';
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([GameError(longError)]),
          initialState: GameError(longError),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.textContaining('Very long error message'), findsOneWidget);
      });
    });

    group('widget properties', () {
      test('GameScreen is a StatefulWidget', () {
        const screen = GameScreen();
        expect(screen, isA<StatefulWidget>());
      });

      test('key can be provided', () {
        const key = Key('test-game-screen');
        const screen = GameScreen(key: key);
        expect(screen.key, key);
      });
    });

    group('loading text styling', () {
      testWidgets('loading text has white70 color', (tester) async {
        whenListen(
          mockGameBloc,
          Stream<GameState>.fromIterable([const GameLoading()]),
          initialState: const GameLoading(),
        );
        whenListen(
          mockWorldBloc,
          Stream<WorldState>.fromIterable([const WorldState()]),
          initialState: const WorldState(),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        final textWidget = tester.widget<Text>(find.text('Loading Homelab...'));
        expect(textWidget.style?.color, Colors.white70);
      });
    });
  });
}
