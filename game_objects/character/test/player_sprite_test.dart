import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_objects_character/game_objects_character.dart';

void main() {
  testWidgets(
    'player renders an idle sprite above its one-tile ground footprint',
    (tester) async {
      final worldBloc = WorldBloc();
      final player = PlayerComponent();
      final game = FlameGame()..images = Images(prefix: '');
      await game.add(
        FlameBlocProvider<WorldBloc, WorldState>.value(
          value: worldBloc,
          children: [player],
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 20));
        if (player.isLoaded) break;
      }
      final visuals = player.children.whereType<SpriteAnimationComponent>();
      expect(visuals, hasLength(1));
      final visual = visuals.single;
      expect(player.anchor, Anchor.topLeft);
      expect(player.size, Vector2.all(player.tileSize));
      expect(visual.anchor, Anchor.bottomCenter);
      expect(visual.position.x, player.tileSize / 2);
      // The normalized frames have16 transparent pixels below the feet.
      expect(visual.position.y - visual.height * 16 / 256, player.tileSize);
      expect(visual.height, player.tileSize * 1.5);
      expect(visual.width / visual.height, 192 / 256);
      expect(
        visual.animation!.frames.single.sprite.srcPosition,
        Vector2.zero(),
      );
      expect(visual.animation!.frames.single.sprite.srcSize, Vector2(192, 256));
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
      await tester.runAsync(worldBloc.close);
    },
  );

  for (final sheet in [GameCharacters.mainMale, GameCharacters.mainFemale]) {
    testWidgets(
      '${sheet.path} walk crops follow travel direction and return to idle',
      (tester) async {
        final worldBloc = WorldBloc();
        final player = PlayerComponent(
          initialPosition: const GridPosition(5, 5),
          spriteSheet: sheet,
        );
        final game = FlameGame()..images = Images(prefix: '');
        await game.add(
          FlameBlocProvider<WorldBloc, WorldState>.value(
            value: worldBloc,
            children: [player],
          ),
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        for (var i = 0; i < 20; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (player.isLoaded) break;
        }
        game.pauseEngine();
        final visual = player.children
            .whereType<SpriteAnimationComponent>()
            .single;
        const directions = [
          (0, 1),
          (-1, 1),
          (-1, 0),
          (-1, -1),
          (0, -1),
          (1, -1),
          (1, 0),
          (1, 1),
        ];
        for (var column = 0; column < directions.length; column++) {
          final (dx, dy) = directions[column];
          player.snapTo(const GridPosition(5, 5));
          final target = GridPosition(5 + dx, 5 + dy);
          player.moveTo(target);
          player.updateTree(0.01);
          expect(visual.animation!.frames, hasLength(3));
          for (var row = 1; row <= 3; row++) {
            final frame = visual.animation!.frames[row - 1];
            expect(
              frame.sprite.srcPosition,
              Vector2(column * 192.0, row * 256.0),
            );
            expect(frame.sprite.srcSize, Vector2(192, 256));
          }
          player.updateTree(0.13);
          expect(visual.animationTicker!.currentIndex, 1);
          player.updateTree(10);
          expect(
            player.position,
            Vector2(target.x * player.tileSize, target.y * player.tileSize),
          );
          expect(player.gridPosition, target);
          expect(visual.animation!.frames, hasLength(1));
          expect(
            visual.animation!.frames.single.sprite.srcPosition,
            Vector2(column * 192.0, 0),
          );
          player.moveTo(target);
          player.updateTree(0.1);
          expect(visual.animation!.frames, hasLength(1));
        }
        final position = player.position.clone();
        player.moveTo(const GridPosition(-1, -1));
        player.updateTree(1);
        expect(player.position, position);
        player.moveTo(const GridPosition(24, 13));
        player.updateTree(10);
        expect(player.gridPosition, const GridPosition(24, 13));
        expect(
          player.position,
          Vector2(24 * player.tileSize, 13 * player.tileSize),
        );
        await tester.pump();
        expect(worldBloc.state.playerPosition, player.gridPosition);
        await tester.pumpWidget(const SizedBox.shrink());
        game.dispose();
        await tester.runAsync(worldBloc.close);
      },
    );
  }
}
