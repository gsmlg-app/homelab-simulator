import 'dart:ui';
import 'package:flame/components.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Renders the room grid with cached path for performance
class GridComponent extends PositionComponent {
  final int gridWidth;
  final int gridHeight;
  final double tileSize;
  final Color gridColor;

  // Cached paint object for performance
  late final Paint _gridPaint;

  // Cached path containing all grid lines - built once, drawn every frame
  late final Path _gridPath;

  GridComponent({
    this.gridWidth = GameConstants.roomWidth,
    this.gridHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
    this.gridColor = AppColors.gridOverlay,
  }) : super(size: Vector2(gridWidth * tileSize, gridHeight * tileSize)) {
    _gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    _gridPath = _buildGridPath();
  }

  /// Builds and caches the grid path once during construction
  Path _buildGridPath() {
    final path = Path();
    final pixelHeight = gridHeight * tileSize;
    final pixelWidth = gridWidth * tileSize;

    // Add vertical lines
    for (int x = 0; x <= gridWidth; x++) {
      final xPos = x * tileSize;
      path.moveTo(xPos, 0);
      path.lineTo(xPos, pixelHeight);
    }

    // Add horizontal lines
    for (int y = 0; y <= gridHeight; y++) {
      final yPos = y * tileSize;
      path.moveTo(0, yPos);
      path.lineTo(pixelWidth, yPos);
    }

    return path;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_gridPath, _gridPaint);
  }
}
