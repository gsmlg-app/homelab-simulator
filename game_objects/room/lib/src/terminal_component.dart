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
    // Terminal base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        const Radius.circular(4),
      ),
      _basePaint,
    );

    // Screen with subtle flicker effect
    final flicker = 0.9 + 0.1 * math.sin(_flickerTime * 2.5);
    final screenColor = _isHighlighted
        ? AppColors.terminalHighlight
        : AppColors.terminalScreen;
    final screenPaint = Paint()
      ..color = screenColor.withValues(alpha: flicker)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(6, 6, size.x - 12, size.y - 16), screenPaint);

    // Animated highlight border when interactable
    if (_isHighlighted) {
      final glowIntensity = 0.5 + 0.5 * math.sin(_flickerTime * 4.0);
      final highlightPaint = Paint()
        ..color = AppColors.terminalHighlight.withValues(
          alpha: 0.6 + 0.4 * glowIntensity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 2 * glowIntensity;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
          const Radius.circular(4),
        ),
        highlightPaint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update flicker animation
    _flickerTime += dt;

    final worldState = bloc.state;
    final newHighlight =
        worldState.interactableEntityId == GameConstants.terminalEntityId;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
  }
}
