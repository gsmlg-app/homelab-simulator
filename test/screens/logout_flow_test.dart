import 'dart:async';
import 'dart:convert';

import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_objects_devices/game_objects_devices.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:homelab_simulator/screens/game_screen.dart';
import 'package:homelab_simulator/screens/start_menu_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {
  @override
  GameModel? get currentModel =>
      state is GameReady ? (state as GameReady).model : null;
}

// Hold one real child-load boundary so route removal can interrupt onLoad.
class _PausedLoadGame extends HomelabGame {
  _PausedLoadGame({
    required super.gameBloc,
    required super.worldBloc,
    required this.pauseGamepad,
  }) {
    if (!pauseGamepad) {
      images.bundle = _PausedSpriteBundle(loadPaused, resume);
    }
  }

  final bool pauseGamepad;
  final loadPaused = Completer<void>();
  final resume = Completer<void>();

  @override
  FutureOr<void> add(Component component) {
    final result = super.add(component);
    final shouldPause = pauseGamepad && component is GamepadHandler;
    if (!shouldPause) return result;
    return Future<void>(() async {
      await result;
      loadPaused.complete();
      await resume.future;
    });
  }
}

class _PausedSpriteBundle extends CachingAssetBundle {
  _PausedSpriteBundle(this.started, this.resume);

  final Completer<void> started;
  final Completer<void> resume;

  @override
  Future<ByteData> load(String key) async {
    if (key == GameCharacters.mainMale.path) {
      started.complete();
      await resume.future;
    }
    return rootBundle.load(key);
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _app(
  GameBloc gameBloc,
  WorldBloc worldBloc,
  GlobalKey<NavigatorState> key,
) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<GameBloc>.value(value: gameBloc),
      BlocProvider<WorldBloc>.value(value: worldBloc),
    ],
    child: MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('Earlier route')),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final pauseGamepad in [false, true]) {
    testWidgets(
      'removal during ${pauseGamepad ? 'input' : 'world'} loading stops subscriptions',
      (tester) async {
        final gameBloc = _MockGameBloc();
        when(() => gameBloc.isClosed).thenReturn(false);
        final states = StreamController<GameState>.broadcast();
        when(() => gameBloc.state).thenReturn(GameReady(GameModel.initial()));
        when(() => gameBloc.stream).thenAnswer((_) => states.stream);
        final worldBloc = WorldBloc();
        final game = _PausedLoadGame(
          gameBloc: gameBloc,
          worldBloc: worldBloc,
          pauseGamepad: pauseGamepad,
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        for (var i = 0; i < 20 && !game.loadPaused.isCompleted; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(game.loadPaused.isCompleted, isTrue);
        final player = game.player;
        if (!pauseGamepad) expect(player.isLoaded, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        game.resume.complete();
        await _pumpFrames(tester);
        if (!pauseGamepad) {
          expect(player.isLoaded, isTrue);
          expect(player.children, isEmpty);
        }

        if (pauseGamepad) {
          // Deliver a native Start-button event after the unmounted child loaded.
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            'xyz.luan/gamepads',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onGamepadEvent', {
                'gamepadId': 'test',
                'time': 1,
                'type': 'button',
                'key': 'start',
                'value': 1.0,
              }),
            ),
            (_) {},
          );
          await tester.pump();
          verifyNever(() => gameBloc.add(const GameToggleShop(isOpen: true)));
        }
        expect(states.hasListener, isFalse);
        expect(game.children, isEmpty);
        await tester.runAsync(worldBloc.close);
        await tester.runAsync(gameBloc.close);
        await states.close();
      },
    );
  }

  for (final state in <GameState>[
    const GameLoading(),
    const GameError('Failed to load'),
    GameReady(GameModel.initial()),
  ]) {
    testWidgets('logout clears routes from ${state.runtimeType}', (
      tester,
    ) async {
      final gameBloc = _MockGameBloc();
      when(() => gameBloc.isClosed).thenReturn(false);
      final states = StreamController<GameState>.broadcast();
      var activeSubscriptions = 0;
      final stream = Stream<GameState>.multi((controller) {
        activeSubscriptions++;
        final subscription = states.stream.listen(controller.add);
        controller.onCancel = () {
          activeSubscriptions--;
          return subscription.cancel();
        };
      }, isBroadcast: true);
      when(() => gameBloc.state).thenReturn(state);
      when(() => gameBloc.stream).thenAnswer((_) => stream);
      final worldBloc = WorldBloc();
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(gameBloc, worldBloc, navigatorKey));
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const GameScreen()),
      );
      await _pumpFrames(tester);

      expect(find.byIcon(Icons.logout), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Log out'),
      );
      button.onPressed!();
      button.onPressed!();
      await _pumpFrames(tester);

      expect(find.byType(StartMenuScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      expect(navigatorKey.currentState!.canPop(), isFalse);
      // Only the root BlocProvider remains subscribed after the route exits.
      expect(activeSubscriptions, 1);
      verify(() => gameBloc.add(const GameSave())).called(1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(worldBloc.close);
      await tester.runAsync(gameBloc.close);
      await states.close();
    });
  }

  testWidgets('logout preserves world and characters for a fresh game', (
    tester,
  ) async {
    final character = CharacterModel.create(
      name: 'TestPlayer',
      gender: Gender.male,
      skinTone: SkinTone.medium,
      hairStyle: HairStyle.short,
      hairColor: HairColor.brown,
      outfitVariant: OutfitVariant.casual,
    );
    const device = DeviceModel(
      id: 'saved-device',
      templateId: 'server',
      name: 'Saved server',
      type: DeviceType.server,
      position: GridPosition(8, 8),
    );
    final initial = GameModel.initial();
    final model = initial.copyWith(
      credits: 4321,
      rooms: [
        initial.currentRoom.copyWith(devices: [device]),
      ],
    );
    final characters = jsonEncode([character.toJson()]);
    SharedPreferences.setMockInitialValues({
      'homelab_characters': characters,
      'homelab_game_state': jsonEncode(model.toJson()),
    });
    final gameBloc = GameBloc()..add(const GameInitialize());
    await gameBloc.stream.firstWhere((state) => state is GameReady);
    final worldBloc = WorldBloc();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(gameBloc, worldBloc, navigatorKey));
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
    await _pumpFrames(tester);
    final oldGame =
        tester
                .widget<GameWidget>(
                  find.byWidgetPredicate((w) => w is GameWidget),
                )
                .game!
            as HomelabGame;
    final input = oldGame.children.whereType<GamepadHandler>().single;
    expect(input.isMounted, isTrue);
    expect(
      oldGame.descendants().whereType<DeviceComponent>().single.device,
      device,
    );

    const latestPosition = GridPosition(6, 6);
    gameBloc.add(const GameMovePlayerTo(latestPosition));
    await _pumpFrames(tester);
    expect(gameBloc.currentModel!.playerPosition, latestPosition);

    gameBloc.add(
      const GameSelectTemplate(
        DeviceTemplate(
          id: 'template',
          name: 'Server',
          description: 'Server',
          type: DeviceType.server,
          cost: 10,
        ),
      ),
    );
    gameBloc.add(const GameToggleShop(isOpen: true));
    worldBloc.add(const EntitySelected('saved-device'));
    worldBloc.add(const CellHovered(GridPosition(4, 4)));
    worldBloc.add(
      const InteractionAvailable('saved-device', InteractionType.device),
    );
    await _pumpFrames(tester);
    await tester.tap(find.text('Log out'));
    await _pumpFrames(tester);

    expect(find.text('TestPlayer'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(input.isRemoved, isTrue);
    expect(oldGame.children, isEmpty);
    expect(worldBloc.state, const WorldState());
    expect(gameBloc.isClosed, isFalse);
    expect(gameBloc.currentModel!.shopOpen, isFalse);
    expect(gameBloc.currentModel!.placementMode, PlacementMode.none);
    expect(gameBloc.currentModel!.selectedTemplate, isNull);
    expect(gameBloc.currentModel!.selectedCloudService, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('homelab_characters'), characters);
    expect(
      jsonDecode(prefs.getString('homelab_game_state')!),
      installCloudCenter(model)
          .copyWith(playerPosition: latestPosition)
          .toJson(),
    );

    final position = gameBloc.currentModel!.playerPosition;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _pumpFrames(tester);
    expect(gameBloc.currentModel!.playerPosition, position);

    await tester.tap(find.text('TestPlayer'));
    await _pumpFrames(tester);
    final newGame =
        tester
                .widget<GameWidget>(
                  find.byWidgetPredicate((w) => w is GameWidget),
                )
                .game!
            as HomelabGame;
    expect(newGame, isNot(same(oldGame)));
    expect(
      newGame.descendants().whereType<DeviceComponent>().single.device,
      device,
    );
    expect(gameBloc.currentModel!.credits, 4321);
    expect(gameBloc.currentModel!.playerPosition, latestPosition);
    expect(gameBloc.currentModel!.shopOpen, isFalse);
    expect(gameBloc.currentModel!.placementMode, PlacementMode.none);
    expect(worldBloc.state.selectedEntityId, isNull);
    expect(worldBloc.state.hoveredCell, isNull);
    expect(oldGame.children, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(worldBloc.close);
    await tester.runAsync(gameBloc.close);
  });
}
