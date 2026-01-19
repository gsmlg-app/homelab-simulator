import 'dart:ui';
import 'package:flame/components.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Renders the room grid
class GridComponent extends PositionComponent {
  final int gridWidth;
  final int gridHeight;
  final double tileSize;
  final Color gridColor;

  GridComponent({
    this.gridWidth = GameConstants.roomWidth,
    this.gridHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
    this.gridColor = const Color(0x33FFFFFF),
  }) : super(
          size: Vector2(
            gridWidth * tileSize,
            gridHeight * tileSize,
          ),
        );

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw vertical lines
    for (var x = 0; x <= gridWidth; x++) {
      canvas.drawLine(
        Offset(x * tileSize, 0),
        Offset(x * tileSize, gridHeight * tileSize),
        paint,
      );
    }

    // Draw horizontal lines
    for (var y = 0; y <= gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * tileSize),
        Offset(gridWidth * tileSize, y * tileSize),
        paint,
      );
    }
  }
}
