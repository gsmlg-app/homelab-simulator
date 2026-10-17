import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_character/game_objects_character.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:homelab_simulator/map_assets.dart';
import 'package:homelab_simulator/screens/game_screen.dart';
import 'package:homelab_simulator/screens/start_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  Future<(GameBloc, WorldBloc, HomelabGame)> open(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'homelab_characters': '[]'});
    late GameBloc gameBloc;
    await tester.runAsync(() async {
      gameBloc = GameBloc(mapCatalogLoader: loadMapCatalog);
      final ready = gameBloc.stream
          .firstWhere((state) => state is GameReady || state is GameError)
          .timeout(const Duration(seconds: 5));
      gameBloc.add(const GameInitialize());
      expect(await ready, isA<GameReady>());
    });
    final worldBloc = WorldBloc();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(worldBloc.close);
      await tester.runAsync(gameBloc.close);
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>.value(value: gameBloc),
          BlocProvider<WorldBloc>.value(value: worldBloc),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const GameScreen(spriteSheet: GameCharacters.mainFemale),
        ),
      ),
    );
    await _frames(tester);
    final game =
        tester
                .widget<GameWidget>(
                  find.byWidgetPredicate((widget) => widget is GameWidget),
                )
                .game!
            as HomelabGame;
    expect(game.isLoaded, isTrue);
    expect(gameBloc.mapCatalog, isNotNull);
    return (gameBloc, worldBloc, game);
  }

  Offset point(WidgetTester tester, HomelabGame game, GridPosition cell) {
    final local = game.camera.localToGlobal(
      Vector2((cell.x + .5) * 32, (cell.y + .5) * 32),
    );
    return tester.getTopLeft(
          find.byWidgetPredicate((widget) => widget is GameWidget),
        ) +
        Offset(local.x, local.y);
  }

  for (final size in [
    const Size(1280, 800),
    const Size(800, 600),
    const Size(390, 640),
    const Size(480, 400),
  ]) {
    testWidgets(
      'real map screen controls, picking and room navigation at $size',
      (tester) async {
        final (bloc, _, game) = await open(tester, size);
        expect(tester.getSize(find.byType(GameScreen)), size);
        final fittedZoom = game.camera.viewfinder.zoom;
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pump();
        expect(game.camera.viewfinder.zoom, greaterThan(fittedZoom));
        await tester.tap(find.byTooltip('Fit room'));
        await tester.pump();
        expect(game.camera.viewfinder.zoom, closeTo(fittedZoom, .0001));
        const target = GridPosition(10, 7);
        await tester.tapAt(point(tester, game, target));
        await _frames(tester, 4);
        expect(
          bloc.currentModel!.playerPosition,
          isNot(const GridPosition(18, 8)),
        );
        await tester.tap(find.byTooltip('Room details'));
        await _frames(tester, 2);
        final stopped = bloc.currentModel!.playerPosition;
        expect(find.text('Room details'), findsOneWidget);
        await _frames(tester);
        expect(bloc.currentModel!.playerPosition, stopped);
        await tester.tap(find.byTooltip('Close details'));
        await _frames(tester, 6);
        await tester.tap(find.byTooltip('Connected rooms'));
        await _frames(tester, 6);
        expect(find.text('Operations'), findsOneWidget);
        await tester.tap(find.text('Operations'));
        await _frames(tester, 40);
        expect(bloc.currentModel!.currentRoomId, 'operations');
        expect(bloc.currentModel!.currentRoom.width, 16);
        expect(find.text('Operations'), findsOneWidget);
        expect(
          game.descendants().whereType<PlayerComponent>().single.spriteSheet,
          GameCharacters.mainFemale,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'logout cancels pending map movement and clears transient scene state',
    (tester) async {
      final (bloc, world, game) = await open(tester, const Size(800, 600));
      const target = GridPosition(10, 7);
      await tester.tapAt(point(tester, game, target));
      await _frames(tester, 2);
      expect(bloc.currentModel!.playerPosition, isNot(target));
      await tester.tap(find.text('Log out'));
      await _frames(tester);
      expect(find.byType(StartMenuScreen), findsOneWidget);
      expect(game.children, isEmpty);
      expect(world.state, const WorldState());
      expect(bloc.currentModel!.shopOpen, isFalse);
      expect(bloc.currentModel!.placementMode, PlacementMode.none);
      final stopped = bloc.currentModel!.playerPosition;
      await _frames(tester);
      expect(bloc.currentModel!.playerPosition, stopped);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('homelab_characters'), '[]');
      expect(tester.takeException(), isNull);
    },
  );
}
