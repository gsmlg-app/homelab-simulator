import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Player character component
class PlayerComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState>, HasGameReference<FlameGame> {
  // Normalized character frames leave this transparent padding below the feet.
  static const double _frameBottomPadding = 16;
  final double tileSize;
  final CharacterSpriteSheet spriteSheet;
  GridPosition _gridPosition;
  Vector2 _targetPosition;
  final Queue<Vector2> _waypoints = Queue<Vector2>();
  final double moveSpeed;

  SpriteAnimationComponent? _visual;
  final Map<CharacterDirection, SpriteAnimation> _idleAnimations = {};
  final Map<CharacterDirection, SpriteAnimation> _walkAnimations = {};
  CharacterDirection _facing = CharacterDirection.down;
  bool _walking = false;

  PlayerComponent({
    GridPosition initialPosition = GameConstants.playerStartPosition,
    this.tileSize = GameConstants.tileSize,
    this.moveSpeed = GameConstants.playerMoveSpeed,
    this.spriteSheet = GameCharacters.mainMale,
  }) : _gridPosition = initialPosition,
       _targetPosition = Vector2(
         initialPosition.x * tileSize,
         initialPosition.y * tileSize,
       ),
       super(
         position: Vector2(
           initialPosition.x * tileSize,
           initialPosition.y * tileSize,
         ),
         size: Vector2.all(tileSize),
       );

  GridPosition get gridPosition => _gridPosition;
  bool get isMoving =>
      _waypoints.isNotEmpty ||
      (_targetPosition - position).length >
          GameConstants.playerMovementThreshold;
  Vector2 get groundAnchor => position + Vector2(tileSize / 2, tileSize);

  /// A room change replaces the visual location without crossing the old room.
  void snapTo(GridPosition cell) {
    _waypoints.clear();
    _gridPosition = cell;
    _targetPosition = Vector2(cell.x * tileSize, cell.y * tileSize);
    position = _targetPosition.clone();
    _walking = false;
    _visual?.animation = _idleAnimations[_facing];
    priority = (groundAnchor.y * 100).round();
  }

  @override
  Future<void> onLoad() async {
    final owner = game;
    await super.onLoad();
    final image = await spriteSheet.loadImage(owner.images);
    if (owner.isRemoved || isRemoved) return;

    for (final direction in CharacterDirection.values) {
      _idleAnimations[direction] = SpriteAnimation.spriteList([
        spriteSheet.idleSprite(image, direction),
      ], stepTime: 1);
    }
    _walkAnimations.addAll(spriteSheet.walkAnimations(image));
    final height = tileSize * 1.5;
    _visual = SpriteAnimationComponent(
      animation: _idleAnimations[_facing],
      size: Vector2(
        height * spriteSheet.frameWidth / spriteSheet.frameHeight,
        height,
      ),
      position: Vector2(
        tileSize / 2,
        tileSize + height * _frameBottomPadding / spriteSheet.frameHeight,
      ),
      anchor: Anchor.bottomCenter,
    );
    await add(_visual!);
  }

  /// Move player to a new grid position
  void moveTo(GridPosition newPosition) {
    if (newPosition.x < 0 ||
        newPosition.y < 0 ||
        newPosition == _gridPosition) {
      return;
    }

    _gridPosition = newPosition;
    final target = Vector2(newPosition.x * tileSize, newPosition.y * tileSize);
    if (isMoving) {
      _waypoints.add(target);
    } else {
      _targetPosition = target;
    }

    // Notify world bloc
    bloc.add(PlayerPositionUpdated(newPosition));
  }

  /// Move in a direction
  void moveInDirection(Direction direction) {
    final delta = switch (direction) {
      Direction.up => const GridPosition(0, -1),
      Direction.down => const GridPosition(0, 1),
      Direction.left => const GridPosition(-1, 0),
      Direction.right => const GridPosition(1, 0),
      Direction.none => const GridPosition(0, 0),
    };

    final newPos = _gridPosition + delta;
    moveTo(newPos);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth movement towards target
    final diff = _targetPosition - position;
    final oldFacing = _facing;
    var walking = false;
    if (diff.length > GameConstants.playerMovementThreshold) {
      final movement = diff.normalized() * moveSpeed * dt;
      if (movement.length > 0) _facing = _directionFor(diff);
      if (movement.length > diff.length) {
        position = _targetPosition.clone();
      } else {
        position += movement;
      }
      walking =
          movement.length > 0 &&
          (_targetPosition - position).length >
              GameConstants.playerMovementThreshold;
    } else {
      position = _targetPosition.clone();
    }
    if ((_targetPosition - position).length <=
            GameConstants.playerMovementThreshold &&
        _waypoints.isNotEmpty) {
      position = _targetPosition.clone();
      _targetPosition = _waypoints.removeFirst();
    }
    priority = (groundAnchor.y * 100).round();
    if (walking != _walking || oldFacing != _facing) {
      _walking = walking;
      _visual?.animation = (_walking
          ? _walkAnimations
          : _idleAnimations)[_facing];
    }
  }

  CharacterDirection _directionFor(Vector2 delta) {
    if (delta.x == 0) {
      return delta.y < 0 ? CharacterDirection.up : CharacterDirection.down;
    }
    if (delta.y == 0) {
      return delta.x < 0 ? CharacterDirection.left : CharacterDirection.right;
    }
    if (delta.x < 0) {
      return delta.y < 0
          ? CharacterDirection.upLeft
          : CharacterDirection.downLeft;
    }
    return delta.y < 0
        ? CharacterDirection.upRight
        : CharacterDirection.downRight;
  }
}
