import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Shows hover highlight on grid cells
class HoverCellComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final double tileSize;
  GridPosition? _currentHover;
  bool _isValidPlacement = true;

  // Cached paint objects for performance
  // Alpha 0x44 / 255 ≈ 0.27 (27% opacity)
  static const double _hoverAlpha = 0x44 / 255;
  static final _validFillPaint = Paint()
    ..color = AppColors.validPlacementFill.withValues(alpha: _hoverAlpha)
    ..style = PaintingStyle.fill;
  static final _invalidFillPaint = Paint()
    ..color = AppColors.invalidPlacementFill.withValues(alpha: _hoverAlpha)
    ..style = PaintingStyle.fill;
  static final _validBorderPaint = Paint()
    ..color = AppColors.validPlacementBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _invalidBorderPaint = Paint()
    ..color = AppColors.invalidPlacementBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  HoverCellComponent({this.tileSize = GameConstants.tileSize})
    : super(size: Vector2.all(tileSize));

  void setValidPlacement(bool valid) {
    _isValidPlacement = valid;
  }

  @override
  void render(Canvas canvas) {
    if (_currentHover == null) return;

    final fillPaint = _isValidPlacement ? _validFillPaint : _invalidFillPaint;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), fillPaint);

    final borderPaint = _isValidPlacement
        ? _validBorderPaint
        : _invalidBorderPaint;
    canvas.drawRect(Rect.fromLTWH(1, 1, size.x - 2, size.y - 2), borderPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    final newHover = worldState.hoveredCell;

    if (newHover != _currentHover) {
      _currentHover = newHover;
      if (newHover != null) {
        position = Vector2(newHover.x * tileSize, newHover.y * tileSize);
      }
    }
  }
}
