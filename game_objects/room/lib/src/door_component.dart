import 'dart:math' as math;
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

  // Animation state for glow effect
  double _glowTime = 0;

  // Cached arrow path (built once in onLoad)
  late final Path _arrowPath;

  // Cached paint objects for performance
  static final _framePaint = Paint()
    ..color = AppColors.doorFrame
    ..style = PaintingStyle.fill;
  static final _doorNormalPaint = Paint()
    ..color = AppColors.doorNormal
    ..style = PaintingStyle.fill;
  static final _doorHighlightPaint = Paint()
    ..color = AppColors.doorHighlight
    ..style = PaintingStyle.fill;
  static final _handlePaint = Paint()
    ..color = AppColors.doorHandle
    ..style = PaintingStyle.fill;
  static final _arrowPaint = Paint()
    ..color = AppColors.doorArrow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Reusable paint for glow animation (color/strokeWidth updated per frame)
  final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;

  DoorComponent({
    required this.door,
    this.roomWidth = GameConstants.roomWidth,
    this.roomHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
  }) : super(size: Vector2.all(tileSize));

  GridPosition get gridPosition => door.getPosition(roomWidth, roomHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final pos = gridPosition;
    position = Vector2(pos.x * tileSize, pos.y * tileSize);
    _arrowPath = _buildArrowPath();
  }

  Path _buildArrowPath() {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final path = Path();

    switch (door.wallSide) {
      case WallSide.top:
        path.moveTo(centerX - 6, centerY + 3);
        path.lineTo(centerX, centerY - 5);
        path.lineTo(centerX + 6, centerY + 3);
      case WallSide.bottom:
        path.moveTo(centerX - 6, centerY - 3);
        path.lineTo(centerX, centerY + 5);
        path.lineTo(centerX + 6, centerY - 3);
      case WallSide.left:
        path.moveTo(centerX + 3, centerY - 6);
        path.lineTo(centerX - 5, centerY);
        path.lineTo(centerX + 3, centerY + 6);
      case WallSide.right:
        path.moveTo(centerX - 3, centerY - 6);
        path.lineTo(centerX + 5, centerY);
        path.lineTo(centerX - 3, centerY + 6);
    }
    return path;
  }

  @override
  void render(Canvas canvas) {
    // Door frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        const Radius.circular(4),
      ),
      _framePaint,
    );

    // Door surface
    final doorPaint = _isHighlighted ? _doorHighlightPaint : _doorNormalPaint;
    canvas.drawRect(Rect.fromLTWH(6, 6, size.x - 12, size.y - 12), doorPaint);

    // Door handle
    final handleX = door.wallSide == WallSide.left ? size.x - 12 : 8.0;
    canvas.drawCircle(Offset(handleX, size.y / 2), 3, _handlePaint);

    // Arrow indicator showing direction
    _drawArrow(canvas);

    // Animated glow border when interactable
    if (_isHighlighted) {
      // Pulsing glow: stroke width oscillates 2-4px
      final glowIntensity = 0.5 + 0.5 * math.sin(_glowTime * 4.0);
      _glowPaint
        ..color = AppColors.doorHighlight.withValues(
          alpha: 0.6 + 0.4 * glowIntensity,
        )
        ..strokeWidth = 2 + 2 * glowIntensity;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
          const Radius.circular(4),
        ),
        _glowPaint,
      );
    }
  }

  void _drawArrow(Canvas canvas) {
    canvas.drawPath(_arrowPath, _arrowPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    final newHighlight = worldState.interactableEntityId == door.id;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
    // Update glow animation when highlighted
    if (_isHighlighted) {
      _glowTime += dt;
    } else {
      _glowTime = 0;
    }
  }
}
