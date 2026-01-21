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

  // Cached paint objects for performance
  static final _basePaint = Paint()
    ..color = AppColors.terminalBase
    ..style = PaintingStyle.fill;
  static final _screenNormalPaint = Paint()
    ..color = AppColors.terminalScreen
    ..style = PaintingStyle.fill;
  static final _screenHighlightPaint = Paint()
    ..color = AppColors.terminalHighlight
    ..style = PaintingStyle.fill;
  static final _highlightBorderPaint = Paint()
    ..color = AppColors.terminalHighlight
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

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

    // Screen
    final screenPaint = _isHighlighted
        ? _screenHighlightPaint
        : _screenNormalPaint;
    canvas.drawRect(Rect.fromLTWH(6, 6, size.x - 12, size.y - 16), screenPaint);

    // Highlight border when interactable
    if (_isHighlighted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
          const Radius.circular(4),
        ),
        _highlightBorderPaint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    final newHighlight =
        worldState.interactableEntityId == GameConstants.terminalEntityId;
    if (newHighlight != _isHighlighted) {
      _isHighlighted = newHighlight;
    }
  }
}
