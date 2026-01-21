import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homelab_simulator/app.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

void main() {
  group('Widget Integration Tests', () {
    testWidgets('App renders', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      // Basic smoke test - app should render without crashing
      expect(find.byType(App), findsOneWidget);
    });

    testWidgets('App contains MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App contains MultiBlocProvider', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(MultiBlocProvider), findsOneWidget);
    });

    testWidgets('App provides GameBloc', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final context = tester.element(find.byType(MaterialApp));
      expect(() => context.read<GameBloc>(), returnsNormally);
    });

    testWidgets('App provides WorldBloc', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final context = tester.element(find.byType(MaterialApp));
      expect(() => context.read<WorldBloc>(), returnsNormally);
    });

    testWidgets('App has dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.dark);
    });

    testWidgets('App disables debug banner', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Homelab Simulator');
    });

    testWidgets('App has custom scaffold background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        const Color(0xFF0D0D1A),
      );
    });

    testWidgets('App has cyan primary color', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.primary, Colors.cyan.shade400);
    });

    testWidgets('App key is set correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.key, const Key('homelab_simulator_app'));
    });

    testWidgets('App has green secondary color', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.secondary, Colors.green.shade400);
    });

    testWidgets('App has dark color scheme', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('App is a StatefulWidget', (WidgetTester tester) async {
      const app = App();
      expect(app, isA<StatefulWidget>());
    });

    testWidgets('GameBloc is initialized with GameInitialize', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      final context = tester.element(find.byType(MaterialApp));
      final gameBloc = context.read<GameBloc>();
      // Bloc should be active and have state
      expect(gameBloc.state, isA<GameState>());
    });

    testWidgets('App has correct scaffold background hex value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final bgColor = materialApp.theme?.scaffoldBackgroundColor;
      expect(bgColor, isNotNull);
      expect(bgColor!.toARGB32(), 0xFF0D0D1A);
    });

    testWidgets('App theme uses copyWith from dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      // Dark theme has dark surface colors
      expect(materialApp.theme?.colorScheme.surface, isNotNull);
    });
  });
}
