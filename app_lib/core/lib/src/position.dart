import 'dart:math' show sqrt;

import 'package:equatable/equatable.dart';

/// Grid position in the game world
class GridPosition extends Equatable {
  final int x;
  final int y;

  const GridPosition(this.x, this.y);

  const GridPosition.zero() : x = 0, y = 0;

  GridPosition copyWith({int? x, int? y}) {
    return GridPosition(x ?? this.x, y ?? this.y);
  }

  GridPosition operator +(GridPosition other) {
    return GridPosition(x + other.x, y + other.y);
  }

  GridPosition operator -(GridPosition other) {
    return GridPosition(x - other.x, y - other.y);
  }

  /// Returns the squared Euclidean distance to another position.
  ///
  /// Use this for distance comparisons to avoid the cost of sqrt().
  /// For actual distance, use [distanceTo].
  double squaredDistanceTo(GridPosition other) {
    final dx = (x - other.x).toDouble();
    final dy = (y - other.y).toDouble();
    return dx * dx + dy * dy;
  }

  /// Returns the Euclidean distance to another position.
  ///
  /// For performance-critical comparisons where only relative ordering
  /// matters, prefer [squaredDistanceTo] to avoid the sqrt() cost.
  double distanceTo(GridPosition other) {
    return sqrt(squaredDistanceTo(other));
  }

  bool isAdjacentTo(GridPosition other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    return dx <= 1 && dy <= 1 && (dx + dy) > 0;
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory GridPosition.fromJson(Map<String, dynamic> json) {
    return GridPosition(json['x'] as int, json['y'] as int);
  }

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'GridPosition($x, $y)';
}

/// Mixin providing grid cell occupancy calculations.
///
/// Use this mixin for any object that occupies rectangular grid space.
/// Implementing classes must provide [position], [width], and [height].
///
/// Example:
/// ```dart
/// class DeviceModel with GridOccupancy {
///   @override
///   final GridPosition position;
///   @override
///   final int width;
///   @override
///   final int height;
/// }
/// ```
mixin GridOccupancy {
  /// The top-left position of this object on the grid.
  GridPosition get position;

  /// The width of this object in grid cells.
  int get width;

  /// The height of this object in grid cells.
  int get height;

  /// Returns all grid cells occupied by this object.
  ///
  /// The cells are returned in row-major order, starting from [position].
  List<GridPosition> get occupiedCells {
    final cells = <GridPosition>[];
    for (var dx = 0; dx < width; dx++) {
      for (var dy = 0; dy < height; dy++) {
        cells.add(GridPosition(position.x + dx, position.y + dy));
      }
    }
    return cells;
  }

  /// Returns true if this object occupies the given [cell].
  ///
  /// A cell is occupied if it falls within the rectangle defined by
  /// [position], [width], and [height].
  bool occupiesCell(GridPosition cell) {
    return cell.x >= position.x &&
        cell.x < position.x + width &&
        cell.y >= position.y &&
        cell.y < position.y + height;
  }
}
