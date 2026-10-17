import 'dart:async';

import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:mocktail/mocktail.dart';

class _MockGameBloc extends Mock implements GameBloc {}

class _ObservedGame extends HomelabGame {
  _ObservedGame({required super.gameBloc, required super.worldBloc})
    : super(spriteSheet: GameCharacters.mainFemale);
}

class _DelayedSpriteBundle extends CachingAssetBundle {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ByteData> load(String key) async {
    if (key == GameCharacters.mainFemale.path) {
      started.complete();
      await release.future;
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('removal during sprite decoding adds no late visual or input', (
    tester,
  ) async {
    final gameBloc = _MockGameBloc();
    final states = StreamController<GameState>.broadcast();
    when(() => gameBloc.isClosed).thenReturn(false);
    when(() => gameBloc.state).thenReturn(GameReady(GameModel.initial()));
    when(() => gameBloc.stream).thenAnswer((_) => states.stream);
    final worldBloc = WorldBloc();
    final bundle = _DelayedSpriteBundle();
    final game = _ObservedGame(gameBloc: gameBloc, worldBloc: worldBloc)
      ..images.bundle = bundle;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    for (var i = 0; i < 20 && !bundle.started.isCompleted; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(bundle.started.isCompleted, isTrue);
    final player = game.player;
    expect(player.isLoaded, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(game.isRemoved, isTrue);
    bundle.release.complete();
    for (var i = 0; i < 20 && !player.isLoaded; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(player.isLoaded, isTrue);

    expect(player.children, isEmpty);
    expect(game.children, isEmpty);
    expect(states.hasListener, isFalse);
    tester.binding.channelBuffers.push(
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
    await tester.runAsync(worldBloc.close);
    await states.close();
  });
}
