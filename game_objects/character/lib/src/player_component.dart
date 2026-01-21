import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Player character component
class PlayerComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final double tileSize;
  GridPosition _gridPosition;
  Vector2 _targetPosition;
  final double moveSpeed;

  // Cached paint objects for performance
  static final _bodyPaint = Paint()
    ..color = AppColors.playerBody
    ..style = PaintingStyle.fill;
  static final _outlinePaint = Paint()
    ..color = AppColors.playerOutline
    ..style = PaintingStyle.stroke
    ..strokeWidth = GameConstants.playerOutlineStrokeWidth;

  PlayerComponent({
    GridPosition initialPosition = GameConstants.playerStartPosition,
    this.tileSize = GameConstants.tileSize,
    this.moveSpeed = GameConstants.playerMoveSpeed,
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

  /// Move player to a new grid position
  void moveTo(GridPosition newPosition) {
    if (!isWithinBounds(newPosition)) return;

    _gridPosition = newPosition;
    _targetPosition = Vector2(
      newPosition.x * tileSize,
      newPosition.y * tileSize,
    );

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
    if (diff.length > GameConstants.playerMovementThreshold) {
      final movement = diff.normalized() * moveSpeed * dt;
      if (movement.length > diff.length) {
        position = _targetPosition.clone();
      } else {
        position += movement;
      }
    } else {
      position = _targetPosition.clone();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw as a simple character using centralized constants
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    const hyo = GameConstants.playerHeadYOffset;
    const hr = GameConstants.playerHeadRadius;
    const byo = GameConstants.playerBodyYOffset;
    const bw = GameConstants.playerBodyWidth;
    const bh = GameConstants.playerBodyHeight;
    const br = GameConstants.playerBodyRadius;

    // Head
    canvas.drawCircle(Offset(centerX, centerY - hyo), hr, _bodyPaint);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + byo),
          width: bw,
          height: bh,
        ),
        const Radius.circular(br),
      ),
      _bodyPaint,
    );

    // Outline
    canvas.drawCircle(Offset(centerX, centerY - hyo), hr, _outlinePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + byo),
          width: bw,
          height: bh,
        ),
        const Radius.circular(br),
      ),
      _outlinePaint,
    );
  }
}
