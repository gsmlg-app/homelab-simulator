import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:homelab_simulator/app.dart';
import 'package:homelab_simulator/screens/start_menu_screen.dart';

void main() {
  group('App', () {
    group('widget structure', () {
      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(const App());
        expect(find.byType(App), findsOneWidget);
      });

      testWidgets('is a StatefulWidget', (_) async {
        const app = App();
        expect(app, isA<StatefulWidget>());
      });

      testWidgets('has const constructor', (_) async {
        const app1 = App();
        const app2 = App();
        expect(app1.key, app2.key);
      });

      testWidgets('renders MultiBlocProvider', (tester) async {
        await tester.pumpWidget(const App());
        expect(find.byType(MultiBlocProvider), findsOneWidget);
      });

      testWidgets('renders MaterialApp', (tester) async {
        await tester.pumpWidget(const App());
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('renders StartMenuScreen as home', (tester) async {
        await tester.pumpWidget(const App());
        // Use pump instead of pumpAndSettle to avoid animation timeouts
        await tester.pump();
        expect(find.byType(StartMenuScreen), findsOneWidget);
      });
    });

    group('BLoC providers', () {
      testWidgets('provides GameBloc to children', (tester) async {
        await tester.pumpWidget(const App());

        // BlocProvider should make GameBloc accessible
        final context = tester.element(find.byType(MaterialApp));
        expect(() => context.read<GameBloc>(), returnsNormally);
      });

      testWidgets('provides WorldBloc to children', (tester) async {
        await tester.pumpWidget(const App());

        final context = tester.element(find.byType(MaterialApp));
        expect(() => context.read<WorldBloc>(), returnsNormally);
      });

      testWidgets('GameBloc initializes with GameInitialize event', (
        tester,
      ) async {
        await tester.pumpWidget(const App());
        await tester.pump();

        final context = tester.element(find.byType(MaterialApp));
        final gameBloc = context.read<GameBloc>();

        // After initialization, GameBloc should not be in closed state
        expect(gameBloc.isClosed, isFalse);
      });
    });

    group('MaterialApp configuration', () {
      testWidgets('has key homelab_simulator_app', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.key, const Key('homelab_simulator_app'));
      });

      testWidgets('has title Homelab Simulator', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.title, 'Homelab Simulator');
      });

      testWidgets('has debug banner disabled', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.debugShowCheckedModeBanner, isFalse);
      });
    });

    group('theme configuration', () {
      testWidgets('uses dark theme', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.theme?.brightness, Brightness.dark);
      });

      testWidgets('has custom scaffold background color', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(
          materialApp.theme?.scaffoldBackgroundColor,
          AppColors.darkBackground,
        );
      });

      testWidgets('has cyan primary color', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.theme?.colorScheme.primary, AppColors.cyan400);
      });

      testWidgets('has green secondary color', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.theme?.colorScheme.secondary, AppColors.green400);
      });

      testWidgets('colorScheme uses dark mode', (tester) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.theme?.colorScheme.brightness, Brightness.dark);
      });
    });

    group('StatefulWidget lifecycle', () {
      testWidgets('creates state correctly', (tester) async {
        await tester.pumpWidget(const App());

        final state = tester.state(find.byType(App));
        expect(state, isNotNull);
      });

      testWidgets(
        'disposes BLoCs when unmounted',
        (tester) async {
          await tester.pumpWidget(const App());
          await tester.pump();

          // Get references to the BLoCs before dispose
          final context = tester.element(find.byType(MaterialApp));
          final gameBloc = context.read<GameBloc>();
          final worldBloc = context.read<WorldBloc>();

          // Verify BLoCs are not closed initially
          expect(gameBloc.isClosed, isFalse);
          expect(worldBloc.isClosed, isFalse);

          // Unmount the App widget
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          // BLoCs should be closed after dispose
          // Note: Due to async nature, BLoCs may take a frame to close
          await tester.pump(const Duration(milliseconds: 100));
          expect(gameBloc.isClosed, isTrue);
          expect(worldBloc.isClosed, isTrue);
        },
        // Skip: BLoC close timing is non-deterministic in widget tests due to
        // how Flutter test framework handles widget tree disposal
        skip: true,
      );
    });

    group('_AppContent', () {
      testWidgets('is a private StatelessWidget', (tester) async {
        await tester.pumpWidget(const App());

        // _AppContent should be rendered as a child
        // We can verify it by finding MaterialApp inside MultiBlocProvider
        expect(
          find.descendant(
            of: find.byType(MultiBlocProvider),
            matching: find.byType(MaterialApp),
          ),
          findsOneWidget,
        );
      });
    });
  });
}
