import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Ghost preview for device or cloud service placement
class PlacementGhostComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final double tileSize;
  DeviceTemplate? _template;
  CloudServiceTemplate? _cloudService;
  bool _isValid = true;
  GridPosition? _currentPosition;

  // Animation state for breathing effect
  double _breatheTime = 0;

  PlacementGhostComponent({this.tileSize = GameConstants.tileSize})
    : super(size: Vector2.all(tileSize));

  /// Set the device template to preview
  void setTemplate(DeviceTemplate? template) {
    _template = template;
    _cloudService = null;
    if (template != null) {
      size = Vector2(template.width * tileSize, template.height * tileSize);
    }
  }

  /// Set the cloud service template to preview
  void setCloudService(CloudServiceTemplate? template) {
    _cloudService = template;
    _template = null;
    if (template != null) {
      size = Vector2(template.width * tileSize, template.height * tileSize);
    }
  }

  /// Check if currently placing a device (vs cloud service)
  bool get isPlacingDevice => _template != null;

  /// Check if currently placing a cloud service
  bool get isPlacingCloudService => _cloudService != null;

  /// Set whether placement is valid at current position
  void setValid(bool valid) {
    _isValid = valid;
  }

  /// Get current grid position
  GridPosition? get currentPosition => _currentPosition;

  @override
  void update(double dt) {
    super.update(dt);

    if (_template == null && _cloudService == null) return;

    // Update breathing animation
    _breatheTime += dt;

    final worldState = bloc.state;
    final hoveredCell = worldState.hoveredCell;

    if (hoveredCell != null && hoveredCell != _currentPosition) {
      _currentPosition = hoveredCell;
      position = Vector2(hoveredCell.x * tileSize, hoveredCell.y * tileSize);
    }
  }

  @override
  void render(Canvas canvas) {
    if ((_template == null && _cloudService == null) ||
        _currentPosition == null) {
      return;
    }

    // Breathing animation: opacity oscillates between 0.3-0.5
    final breathe = 0.4 + 0.1 * math.sin(_breatheTime * 3.0);
    final baseColor = _isValid
        ? AppColors.validPlacementFill
        : AppColors.invalidPlacementFill;
    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: breathe)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Border with matching animation
    final borderColor = _isValid
        ? AppColors.validPlacementBorder
        : AppColors.invalidPlacementBorder;
    final borderPaint = Paint()
      ..color = borderColor.withValues(
        alpha: 0.7 + 0.3 * math.sin(_breatheTime * 3.0),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        const Radius.circular(4),
      ),
      borderPaint,
    );
  }
}
