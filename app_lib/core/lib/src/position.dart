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

  double distanceTo(GridPosition other) {
    final dx = (x - other.x).toDouble();
    final dy = (y - other.y).toDouble();
    return (dx * dx + dy * dy);
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
