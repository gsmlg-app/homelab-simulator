import 'dart:convert';
import 'dart:ui' as ui;

import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_character/game_objects_character.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:homelab_simulator/screens/game_screen.dart';
import 'package:homelab_simulator/screens/start_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CharacterModel _character(String name, Gender gender) => CharacterModel.create(
  name: name,
  gender: gender,
  skinTone: SkinTone.medium,
  hairStyle: HairStyle.short,
  hairColor: HairColor.brown,
  outfitVariant: OutfitVariant.casual,
);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

HomelabGame _game(WidgetTester tester) =>
    tester
            .widget<GameWidget>(
              find.byWidgetPredicate((widget) => widget is GameWidget),
            )
            .game!
        as HomelabGame;

Future<PlayerComponent> _loadedPlayer(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    final players = _game(tester).descendants().whereType<PlayerComponent>();
    if (players.isNotEmpty && players.single.isLoaded) return players.single;
  }
  fail('Player did not load');
}

Future<void> _expectSheet(
  WidgetTester tester,
  PlayerComponent player,
  CharacterSpriteSheet sheet,
) async {
  final visuals = player.children.whereType<SpriteAnimationComponent>();
  expect(visuals, hasLength(1));
  final visual = visuals.single;
  final sprite = visual.animation!.frames.single.sprite;
  expect(sprite.srcPosition, Vector2.zero());
  expect(sprite.srcSize, Vector2(192, 256));
  final expected = await tester.runAsync(
    () => sheet.loadImage(_game(tester).images),
  );
  expect(sprite.image, same(expected));
  final rendered = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    visual.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      visual.width.ceil(),
      visual.height.ceil(),
    );
    final pixels = await image.toByteData();
    picture.dispose();
    image.dispose();
    return pixels!.buffer.asUint8List();
  });
  expect(rendered!.where((value) => value != 0), isNotEmpty);
  var firstOpaqueRow = visual.height.ceil();
  var lastOpaqueRow = -1;
  final width = visual.width.ceil();
  for (var y = 0; y < visual.height.ceil(); y++) {
    for (var x = 0; x < width; x++) {
      if (rendered[(y * width + x) * 4 + 3] == 0) continue;
      if (y < firstOpaqueRow) firstOpaqueRow = y;
      lastOpaqueRow = y;
    }
  }
  final visualTop = visual.position.y - visual.height;
  expect(visualTop + lastOpaqueRow + 1, closeTo(player.tileSize, 1));
  expect(visualTop + firstOpaqueRow, lessThan(0));
}

void main() {
  late GameBloc gameBloc;
  late WorldBloc worldBloc;

  Future<void> open(
    WidgetTester tester, {
    List<CharacterModel> characters = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      'homelab_characters': jsonEncode(
        characters.map((c) => c.toJson()).toList(),
      ),
    });
    gameBloc = GameBloc()..add(const GameInitialize());
    await gameBloc.stream.firstWhere((state) => state is GameReady);
    worldBloc = WorldBloc();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>.value(value: gameBloc),
          BlocProvider<WorldBloc>.value(value: worldBloc),
        ],
        child: const MaterialApp(home: StartMenuScreen()),
      ),
    );
    await _frames(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(worldBloc.close);
    await tester.runAsync(gameBloc.close);
  }

  testWidgets(
    'selected character sheet reaches the scene after logout and reentry',
    (tester) async {
      final sharedImages = Flame.images;
      final sharedPrefix = sharedImages.prefix;
      await open(
        tester,
        characters: [
          _character('BoyPlayer', Gender.male),
          _character('GirlPlayer', Gender.female),
        ],
      );
      await tester.tap(find.text('BoyPlayer'));
      await _frames(tester);
      final firstGame = _game(tester);
      expect(firstGame.images, isNot(same(sharedImages)));
      final first = await _loadedPlayer(tester);
      await _expectSheet(tester, first, GameCharacters.mainMale);

      await tester.tap(find.text('Log out'));
      await _frames(tester);
      await tester.tap(find.text('GirlPlayer'));
      await _frames(tester);
      final secondGame = _game(tester);
      expect(secondGame.images, isNot(same(firstGame.images)));
      expect(secondGame.images, isNot(same(sharedImages)));
      expect(sharedImages.prefix, sharedPrefix);
      final second = await _loadedPlayer(tester);
      expect(second, isNot(same(first)));
      await _expectSheet(tester, second, GameCharacters.mainFemale);
      await close(tester);
    },
  );

  for (final gender in Gender.values) {
    testWidgets(
      'menu ${gender.name} avatar shows one proportionate idle frame',
      (tester) async {
        final character = _character('MenuPlayer', gender);
        final sheet = character.spriteSheet;
        await open(tester, characters: [character]);
        addTearDown(() => close(tester));
        final image = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == sheet.path,
        );
        final rawImage = find.descendant(
          of: image,
          matching: find.byType(RawImage),
        );
        for (var i = 0; i < 20; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (tester.renderObject<RenderImage>(rawImage).image != null) break;
        }
        expect(tester.renderObject<RenderImage>(rawImage).image, isNotNull);
        final viewport = tester.getRect(
          find.ancestor(of: image, matching: find.byType(ClipRect)).first,
        );
        final atlas = tester.getRect(rawImage);
        expect(atlas.width / viewport.width, sheet.columns);
        expect(atlas.height / viewport.height, sheet.rows);
        expect(viewport.height, AppSpacing.avatarSize);
        expect(
          viewport.width / viewport.height,
          sheet.frameWidth / sheet.frameHeight,
        );
        expect(atlas.topLeft, viewport.topLeft);
      },
    );

    testWidgets(
      'new ${gender.name} character enters with its rendered sprite',
      (tester) async {
        await open(tester);
        await tester.tap(find.text('CREATE NEW CHARACTER'));
        await _frames(tester);
        await tester.enterText(find.byType(TextField), 'NewPlayer');
        await tester.tap(find.text('Next'));
        await _frames(tester);
        await tester.tap(
          find.text(gender == Gender.female ? 'Female' : 'Male'),
        );
        await tester.tap(find.text('Next'));
        await _frames(tester);
        await tester.tap(find.text('Create'));
        await _frames(tester);
        expect(find.byType(GameScreen), findsOneWidget);
        final player = await _loadedPlayer(tester);
        await _expectSheet(
          tester,
          player,
          gender == Gender.female
              ? GameCharacters.mainFemale
              : GameCharacters.mainMale,
        );
        await close(tester);
      },
    );
  }
}
