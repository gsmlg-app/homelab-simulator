import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Wall position for door placement
enum WallSide {
  top,
  bottom,
  left,
  right,
}

/// A door connecting two rooms
class DoorModel extends Equatable {
  final String id;
  final String targetRoomId;
  final WallSide wallSide;
  final int wallPosition; // Position along the wall (in tiles from left/top)

  const DoorModel({
    required this.id,
    required this.targetRoomId,
    required this.wallSide,
    required this.wallPosition,
  });

  /// Get the grid position of the door (for interaction detection)
  GridPosition getPosition(int roomWidth, int roomHeight) {
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
  }) {
    return DoorModel(
      id: id ?? this.id,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      wallSide: wallSide ?? this.wallSide,
      wallPosition: wallPosition ?? this.wallPosition,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetRoomId': targetRoomId,
        'wallSide': wallSide.name,
        'wallPosition': wallPosition,
      };

  factory DoorModel.fromJson(Map<String, dynamic> json) {
    return DoorModel(
      id: json['id'] as String,
      targetRoomId: json['targetRoomId'] as String,
      wallSide: WallSide.values.byName(json['wallSide'] as String),
      wallPosition: json['wallPosition'] as int,
    );
  }

  @override
  List<Object?> get props => [id, targetRoomId, wallSide, wallPosition];
}
