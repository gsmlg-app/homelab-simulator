import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_hud/game_widgets_hud.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  group('InteractionHint', () {
    late MockGameBloc mockGameBloc;

    setUp(() {
      mockGameBloc = MockGameBloc();
    });

    testWidgets('shows nothing when interaction type is none', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.none,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E'), findsNothing);
    });

    testWidgets('shows terminal hint message', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to open shop'), findsOneWidget);
    });

    testWidgets('shows door hint message', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.door,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to enter'), findsOneWidget);
    });

    testWidgets('shows device hint message', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.device,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to interact'), findsOneWidget);
    });

    testWidgets('shows E key indicator', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('hides when shop is open', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to open shop'), findsNothing);
    });

    testWidgets('shows nothing when state is not GameReady', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to open shop'), findsNothing);
    });

    testWidgets('has cyan styling', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InteractionHint),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.black87);
      expect(decoration.border?.top.color, Colors.cyan.shade700);
    });

    testWidgets('shows nothing when GameError state', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameError('error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press E to open shop'), findsNothing);
    });

    testWidgets('E key has correct styling', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.door,
              ),
            ),
          ),
        ),
      );

      final eText = tester.widget<Text>(find.text('E'));
      final style = eText.style!;
      expect(style.color, Colors.white);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontFamily, 'monospace');
    });

    testWidgets('message text has correct styling', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.device,
              ),
            ),
          ),
        ),
      );

      final messageText = tester.widget<Text>(find.text('Press E to interact'));
      final style = messageText.style!;
      expect(style.color, Colors.white);
      expect(style.fontSize, 14);
    });

    testWidgets('container has border radius', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InteractionHint),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('E key container has cyan background', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      // Find the inner Container that wraps the E key
      final innerContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(InteractionHint),
          matching: find.byType(Container),
        ),
      );

      // Second container is the E key background
      final eKeyContainer = innerContainers.elementAt(1);
      final decoration = eKeyContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.cyan.shade800);
      expect(decoration.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('row layout with E key and message', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('Press E to open shop'), findsOneWidget);
    });

    testWidgets('uses SizedBox.shrink for none type', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.none,
              ),
            ),
          ),
        ),
      );

      // The widget returns SizedBox.shrink() which renders nothing
      expect(find.byType(Row), findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('wraps content in AnimatedOpacity', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.door,
              ),
            ),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);
      expect(animatedOpacity.duration, const Duration(milliseconds: 200));
    });

    testWidgets('outer container has correct padding', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const InteractionHint(
                interactionType: InteractionType.terminal,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InteractionHint),
          matching: find.byType(Container).first,
        ),
      );

      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    });
  });
}
