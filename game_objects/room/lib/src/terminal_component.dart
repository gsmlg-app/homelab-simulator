import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Terminal component that player can interact with to open shop
class TerminalComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final GridPosition gridPosition;
  final double tileSize;
  bool _isHighlighted = false;

  // Animation state for screen flicker
  double _flickerTime = 0;

  // Cached paint objects for performance
  static final _basePaint = Paint()
    ..color = AppColors.terminalBase
    ..style = PaintingStyle.fill;

  // Reusable paints for animation (color/strokeWidth updated per frame)
  final Paint _screenPaint = Paint()..style = PaintingStyle.fill;
  final Paint _highlightPaint = Paint()..style = PaintingStyle.stroke;

  TerminalComponent({
    this.gridPosition = GameConstants.terminalPosition,
    this.tileSize = GameConstants.tileSize,
  }) : super(
         position: Vector2(
           gridPosition.x * tileSize,
           gridPosition.y * tileSize,
         ),
         size: Vector2.all(tileSize),
       );

  @override
  void render(Canvas canvas) {
    // Terminal base - use centralized drawing constants
    const fp = GameConstants.componentFramePadding;
    const fw = GameConstants.componentFrameWidth;
    const ip = GameConstants.componentInnerPadding;
    const cr = GameConstants.componentCornerRadius;
    const tbo = GameConstants.terminalScreenBottomOffset;
    const hi = GameConstants.highlightBorderInset;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fp, fp, size.x - fw, size.y - fw),
        const Radius.circular(cr),
      ),
      _basePaint,
    );

    // Screen with subtle flicker effect using centralized animation constants
    final flicker =
        GameConstants.terminalFlickerMin +
        GameConstants.terminalFlickerAmplitude *
            math.sin(_flickerTime * GameConstants.terminalFlickerFrequency);
    final screenColor = _isHighlighted
        ? AppColors.terminalHighlight
        : AppColors.terminalScreen;
    _screenPaint.color = screenColor.withValues(alpha: flicker);
    canvas.drawRect(
      Rect.fromLTWH(ip, ip, size.x - ip * 2, size.y - ip * 2 - tbo),
      _screenPaint,
    );

    // Animated highlight border when interactable
    if (_isHighlighted) {
      final glowIntensity =
          GameConstants.glowIntensityCenter +
          GameConstants.glowIntensityCenter *
              math.sin(_flickerTime * GameConstants.terminalFlickerFrequency);
      _highlightPaint
        ..color = AppColors.terminalHighlight.withValues(
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
        _highlightPaint,
      );
    }
  }

  // Animation cycle period (2π for sine wave)
  static const _animationPeriod = math.pi * 2;

  @override
  void update(double dt) {
    super.update(dt);
    // Update flicker animation (bounded to prevent overflow)
    _flickerTime = (_flickerTime + dt) % _animationPeriod;

    final worldState = bloc.state;
    final newHighlight =
        worldState.interactableEntityId == GameConstants.terminalEntityId;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
  }
}
