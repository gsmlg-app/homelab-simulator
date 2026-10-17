import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Wall position for door placement
enum WallSide {
  top,
  bottom,
  left,
  right;

  /// Get the opposite wall side
  WallSide get opposite => switch (this) {
    WallSide.top => WallSide.bottom,
    WallSide.bottom => WallSide.top,
    WallSide.left => WallSide.right,
    WallSide.right => WallSide.left,
  };
}

/// A door connecting two rooms
class DoorModel extends Equatable {
  final String id;
  final String targetRoomId;
  final WallSide wallSide;
  final String? targetSpawnId;

  /// Optional floor gateway; old wall-edge doors retain their coordinates.
  final GridPosition? gridPosition;
  final GridPosition? targetSpawnPosition;
  final int wallPosition; // Position along the wall (in tiles from left/top)

  const DoorModel({
    required this.id,
    required this.targetRoomId,
    required this.wallSide,
    required this.wallPosition,
    this.targetSpawnId,
    this.gridPosition,
    this.targetSpawnPosition,
  });

  /// Get the grid position of the door (for interaction detection)
  GridPosition getPosition(int roomWidth, int roomHeight) {
    if (gridPosition != null) return gridPosition!;
    switch (wallSide) {
      case WallSide.top:
        return GridPosition(wallPosition, 0);
      case WallSide.bottom:
        return GridPosition(wallPosition, roomHeight - 1);
      case WallSide.left:
        return GridPosition(0, wallPosition);
      case WallSide.right:
        return GridPosition(roomWidth - 1, wallPosition);
    }
  }

  /// Get the spawn position when entering through this door
  GridPosition getSpawnPosition(int roomWidth, int roomHeight) {
    if (gridPosition != null) return gridPosition!;
    switch (wallSide) {
      case WallSide.top:
        return GridPosition(wallPosition, 1);
      case WallSide.bottom:
        return GridPosition(wallPosition, roomHeight - 2);
      case WallSide.left:
        return GridPosition(1, wallPosition);
      case WallSide.right:
        return GridPosition(roomWidth - 2, wallPosition);
    }
  }

  DoorModel copyWith({
    String? id,
    String? targetRoomId,
    WallSide? wallSide,
    int? wallPosition,
    String? targetSpawnId,
    GridPosition? gridPosition,
    GridPosition? targetSpawnPosition,
  }) {
    return DoorModel(
      id: id ?? this.id,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      wallSide: wallSide ?? this.wallSide,
      wallPosition: wallPosition ?? this.wallPosition,
      targetSpawnId: targetSpawnId ?? this.targetSpawnId,
      gridPosition: gridPosition ?? this.gridPosition,
      targetSpawnPosition: targetSpawnPosition ?? this.targetSpawnPosition,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetRoomId': targetRoomId,
    'wallSide': wallSide.name,
    'wallPosition': wallPosition,
    'targetSpawnId': targetSpawnId,
    if (gridPosition != null) 'gridPosition': gridPosition!.toJson(),
    if (targetSpawnPosition != null)
      'targetSpawnPosition': targetSpawnPosition!.toJson(),
  };

  factory DoorModel.fromJson(Map<String, dynamic> json) {
    return DoorModel(
      id: json['id'] as String,
      targetRoomId: json['targetRoomId'] as String,
      wallSide: parseEnum(
        WallSide.values,
        json['wallSide'] as String?,
        WallSide.bottom,
      ),
      wallPosition: json['wallPosition'] as int,
      targetSpawnId: json['targetSpawnId'] as String?,
      gridPosition: json['gridPosition'] == null
          ? null
          : GridPosition.fromJson(json['gridPosition'] as Map<String, dynamic>),
      targetSpawnPosition: json['targetSpawnPosition'] == null
          ? null
          : GridPosition.fromJson(
              json['targetSpawnPosition'] as Map<String, dynamic>,
            ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    targetRoomId,
    wallSide,
    wallPosition,
    targetSpawnId,
    gridPosition,
    targetSpawnPosition,
  ];

  @override
  String toString() =>
      'DoorModel(id: $id, target: $targetRoomId, $wallSide @ $wallPosition)';
}
