import 'position.dart';

/// Constants for the game grid
class GameConstants {
  static const double tileSize = 32.0;
  static const int roomWidth = 20;
  static const int roomHeight = 12;
  static const GridPosition terminalPosition = GridPosition(2, 2);
  static const GridPosition playerStartPosition = GridPosition(10, 6);
  static const int startingCredits = 1000;
}

/// Convert grid position to pixel position
(double, double) gridToPixel(GridPosition pos) {
  return (
    pos.x * GameConstants.tileSize.toDouble(),
    pos.y * GameConstants.tileSize.toDouble(),
  );
}

/// Convert pixel position to grid position
GridPosition pixelToGrid(double x, double y) {
  return GridPosition(
    (x / GameConstants.tileSize).floor(),
    (y / GameConstants.tileSize).floor(),
  );
}

/// Check if position is within room bounds
bool isWithinBounds(GridPosition pos) {
  return pos.x >= 0 &&
      pos.x < GameConstants.roomWidth &&
      pos.y >= 0 &&
      pos.y < GameConstants.roomHeight;
}
