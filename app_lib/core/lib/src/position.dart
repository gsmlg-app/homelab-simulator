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
