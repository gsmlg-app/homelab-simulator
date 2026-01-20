import 'dart:ui';
import 'package:flame/components.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Renders the room grid
class GridComponent extends PositionComponent {
  final int gridWidth;
  final int gridHeight;
  final double tileSize;
  final Color gridColor;

  // Cached paint object for performance
  late final Paint _gridPaint;

  GridComponent({
    this.gridWidth = GameConstants.roomWidth,
    this.gridHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
    this.gridColor = const Color(0x33FFFFFF),
  }) : super(size: Vector2(gridWidth * tileSize, gridHeight * tileSize)) {
    _gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
  }

  @override
  void render(Canvas canvas) {
    // Draw vertical lines
    for (var x = 0; x <= gridWidth; x++) {
      canvas.drawLine(
        Offset(x * tileSize, 0),
        Offset(x * tileSize, gridHeight * tileSize),
        _gridPaint,
      );
    }

    // Draw horizontal lines
    for (var y = 0; y <= gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * tileSize),
        Offset(gridWidth * tileSize, y * tileSize),
        _gridPaint,
      );
    }
  }
}
