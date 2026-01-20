import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import 'game_characters.dart';

/// Flame helpers for loading and animating character sprites.
extension CharacterSpriteSheetFlame on CharacterSpriteSheet {
  Future<Image> loadImage(Images images) => images.load(path);

  SpriteSheet spriteSheet(Image image) =>
      SpriteSheet(image: image, srcSize: Vector2(frameWidth, frameHeight));

  Sprite idleSprite(Image image, CharacterDirection direction) {
    final column = columnForDirection(direction);
    return spriteSheet(image).getSprite(idleRow, column);
  }

  SpriteAnimation walkAnimation(
    Image image,
    CharacterDirection direction, {
    double stepTime = 0.12,
  }) {
    final column = columnForDirection(direction);
    final frames = [
      for (final row in walkRows)
        SpriteAnimationFrameData(
          srcPosition: Vector2(column * frameWidth, row * frameHeight),
          srcSize: Vector2(frameWidth, frameHeight),
          stepTime: stepTime,
        ),
    ];

    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData(frames),
    );
  }

  Map<CharacterDirection, SpriteAnimation> walkAnimations(
    Image image, {
    double stepTime = 0.12,
  }) {
    return {
      for (final direction in CharacterDirection.values)
        direction: walkAnimation(image, direction, stepTime: stepTime),
    };
  }
}
