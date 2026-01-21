import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_hud/game_widgets_hud.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  group('CreditsDisplay', () {
    late MockGameBloc mockGameBloc;

    setUp(() {
      mockGameBloc = MockGameBloc();
    });

    testWidgets('displays credits from game state', (tester) async {
      final model = GameModel.initial().copyWith(credits: 1500);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$1500'), findsOneWidget);
    });

    testWidgets('displays zero credits when not ready', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$0'), findsOneWidget);
    });

    testWidgets('displays money icon', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('has green styling', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CreditsDisplay),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.black87);
      expect(decoration.border?.top.color, Colors.green.shade700);
    });

    testWidgets('displays different credit amounts correctly', (tester) async {
      final model = GameModel.initial().copyWith(credits: 9999);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$9999'), findsOneWidget);
    });

    testWidgets('displays zero credits explicitly', (tester) async {
      final model = GameModel.initial().copyWith(credits: 0);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$0'), findsOneWidget);
    });

    testWidgets('displays large credit amounts', (tester) async {
      final model = GameModel.initial().copyWith(credits: 999999);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$999999'), findsOneWidget);
    });

    testWidgets('displays zero for GameError state', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameError('error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      expect(find.text('\$0'), findsOneWidget);
    });

    testWidgets('icon has correct color and size', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.monetization_on));
      expect(icon.color, Colors.green.shade400);
      expect(icon.size, 24);
    });

    testWidgets('text has correct style', (tester) async {
      final model = GameModel.initial().copyWith(credits: 1000);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('\$1000'));
      final style = text.style!;
      expect(style.color, Colors.green.shade400);
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontFamily, 'monospace');
    });

    testWidgets('container has border radius', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CreditsDisplay),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('row layout with icon and text', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      // Verify Row contains both icon and text
      expect(find.byType(Row), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('displays starting credits from initial model', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<GameBloc>.value(
              value: mockGameBloc,
              child: const CreditsDisplay(),
            ),
          ),
        ),
      );

      // GameModel.initial() has 1000 credits
      expect(find.text('\$1000'), findsOneWidget);
    });
  });
}
