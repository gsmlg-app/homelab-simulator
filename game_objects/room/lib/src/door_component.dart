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
    ..strokeWidth = GameConstants.glowStrokeBase
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

    // Use centralized arrow drawing constants
    const bo = GameConstants.arrowBaseOffset;
    const to = GameConstants.arrowTipOffset;
    const po = GameConstants.arrowPerpOffset;

    switch (door.wallSide) {
      case WallSide.top:
        path.moveTo(centerX - bo, centerY + po);
        path.lineTo(centerX, centerY - to);
        path.lineTo(centerX + bo, centerY + po);
      case WallSide.bottom:
        path.moveTo(centerX - bo, centerY - po);
        path.lineTo(centerX, centerY + to);
        path.lineTo(centerX + bo, centerY - po);
      case WallSide.left:
        path.moveTo(centerX + po, centerY - bo);
        path.lineTo(centerX - to, centerY);
        path.lineTo(centerX + po, centerY + bo);
      case WallSide.right:
        path.moveTo(centerX - po, centerY - bo);
        path.lineTo(centerX + to, centerY);
        path.lineTo(centerX - po, centerY + bo);
    }
    return path;
  }

  @override
  void render(Canvas canvas) {
    // Door frame - use centralized drawing constants
    const fp = GameConstants.componentFramePadding;
    const fw = GameConstants.componentFrameWidth;
    const ip = GameConstants.componentInnerPadding;
    const cr = GameConstants.componentCornerRadius;
    const ho = GameConstants.doorHandleOffset;
    const hr = GameConstants.doorHandleRadius;
    const hi = GameConstants.highlightBorderInset;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fp, fp, size.x - fw, size.y - fw),
        const Radius.circular(cr),
      ),
      _framePaint,
    );

    // Door surface
    final doorPaint = _isHighlighted ? _doorHighlightPaint : _doorNormalPaint;
    canvas.drawRect(
      Rect.fromLTWH(ip, ip, size.x - ip * 2, size.y - ip * 2),
      doorPaint,
    );

    // Door handle
    final handleX = door.wallSide == WallSide.left ? size.x - ip - fp : ho;
    canvas.drawCircle(Offset(handleX, size.y / 2), hr, _handlePaint);

    // Arrow indicator showing direction
    _drawArrow(canvas);

    // Animated glow border when interactable
    if (_isHighlighted) {
      // Pulsing glow: stroke width oscillates using centralized constants
      final glowIntensity =
          GameConstants.glowIntensityCenter +
          GameConstants.glowIntensityCenter *
              math.sin(_glowTime * GameConstants.doorGlowFrequency);
      _glowPaint
        ..color = AppColors.doorHighlight.withValues(
          alpha:
              GameConstants.glowOpacityBase +
              GameConstants.glowOpacityAmplitude * glowIntensity,
        )
        ..strokeWidth =
            GameConstants.glowStrokeBase +
            GameConstants.glowStrokeAmplitude * glowIntensity;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(hi, hi, size.x - hi * 2, size.y - hi * 2),
          const Radius.circular(cr),
        ),
        _glowPaint,
      );
    }
  }

  void _drawArrow(Canvas canvas) {
    canvas.drawPath(_arrowPath, _arrowPaint);
  }

  // Use centralized animation period constant

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    final newHighlight = worldState.interactableEntityId == door.id;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
    // Update glow animation when highlighted (bounded to prevent overflow)
    if (_isHighlighted) {
      _glowTime = (_glowTime + dt) % GameConstants.animationPeriod;
    } else {
      _glowTime = 0;
    }
  }
}
