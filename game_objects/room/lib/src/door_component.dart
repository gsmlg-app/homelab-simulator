import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Door component that allows player to transition between rooms
class DoorComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final DoorModel door;
  final int roomWidth;
  final int roomHeight;
  final double tileSize;
  bool _isHighlighted = false;

  DoorComponent({
    required this.door,
    this.roomWidth = GameConstants.roomWidth,
    this.roomHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
  }) : super(
          size: Vector2.all(tileSize),
        );

  GridPosition get gridPosition => door.getPosition(roomWidth, roomHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final pos = gridPosition;
    position = Vector2(pos.x * tileSize, pos.y * tileSize);
  }

  @override
  void render(Canvas canvas) {
    // Door frame
    final framePaint = Paint()
      ..color = const Color(0xFF4A4A5A)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        const Radius.circular(4),
      ),
      framePaint,
    );

    // Door surface
    final doorColor = _isHighlighted
        ? const Color(0xFF5588FF)
        : const Color(0xFF3366CC);
    final doorPaint = Paint()
      ..color = doorColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(6, 6, size.x - 12, size.y - 12),
      doorPaint,
    );

    // Door handle
    final handlePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final handleX = door.wallSide == WallSide.left ? size.x - 12 : 8.0;
    canvas.drawCircle(
      Offset(handleX, size.y / 2),
      3,
      handlePaint,
    );

    // Arrow indicator showing direction
    _drawArrow(canvas);

    // Highlight border when interactable
    if (_isHighlighted) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF5588FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
          const Radius.circular(4),
        ),
        highlightPaint,
      );
    }
  }

  void _drawArrow(Canvas canvas) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    final path = Path();
    switch (door.wallSide) {
      case WallSide.top:
        path.moveTo(centerX - 6, centerY + 3);
        path.lineTo(centerX, centerY - 5);
        path.lineTo(centerX + 6, centerY + 3);
        break;
      case WallSide.bottom:
        path.moveTo(centerX - 6, centerY - 3);
        path.lineTo(centerX, centerY + 5);
        path.lineTo(centerX + 6, centerY - 3);
        break;
      case WallSide.left:
        path.moveTo(centerX + 3, centerY - 6);
        path.lineTo(centerX - 5, centerY);
        path.lineTo(centerX + 3, centerY + 6);
        break;
      case WallSide.right:
        path.moveTo(centerX - 3, centerY - 6);
        path.lineTo(centerX + 5, centerY);
        path.lineTo(centerX - 3, centerY + 6);
        break;
    }
    canvas.drawPath(path, arrowPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    final newHighlight = worldState.interactableEntityId == door.id;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
  }
}
