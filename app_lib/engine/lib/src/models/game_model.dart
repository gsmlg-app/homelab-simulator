import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'door_model.dart';
import 'room_model.dart';
import 'device_template.dart';
import 'cloud_service_model.dart';

/// Main game state model
class GameModel extends Equatable {
  final String currentRoomId;
  final List<RoomModel> rooms;
  final int credits;
  final GridPosition playerPosition;
  final GameMode gameMode;
  final PlacementMode placementMode;
  final DeviceTemplate? selectedTemplate;
  final CloudServiceTemplate? selectedCloudService;
  final bool shopOpen;

  const GameModel({
    required this.currentRoomId,
    required this.rooms,
    this.credits = GameConstants.startingCredits,
    this.playerPosition = GameConstants.playerStartPosition,
    this.gameMode = GameMode.sim,
    this.placementMode = PlacementMode.none,
    this.selectedTemplate,
    this.selectedCloudService,
    this.shopOpen = false,
  });

  /// Get the current room.
  ///
  /// Returns the room with the matching [currentRoomId], or falls back to
  /// the first room in the list if not found. Throws [StateError] if there
  /// are no rooms (this should never happen in normal usage).
  RoomModel get currentRoom {
    final room = getRoomById(currentRoomId);
    if (room != null) return room;
    if (rooms.isNotEmpty) return rooms.first;
    throw StateError('GameModel has no rooms');
  }

  GameModel copyWith({
    String? currentRoomId,
    List<RoomModel>? rooms,
    int? credits,
    GridPosition? playerPosition,
    GameMode? gameMode,
    PlacementMode? placementMode,
    DeviceTemplate? selectedTemplate,
    CloudServiceTemplate? selectedCloudService,
    bool clearSelectedTemplate = false,
    bool clearSelectedCloudService = false,
    bool? shopOpen,
  }) {
    return GameModel(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      rooms: rooms ?? this.rooms,
      credits: credits ?? this.credits,
      playerPosition: playerPosition ?? this.playerPosition,
      gameMode: gameMode ?? this.gameMode,
      placementMode: placementMode ?? this.placementMode,
      selectedTemplate: clearSelectedTemplate
          ? null
          : (selectedTemplate ?? this.selectedTemplate),
      selectedCloudService: clearSelectedCloudService
          ? null
          : (selectedCloudService ?? this.selectedCloudService),
      shopOpen: shopOpen ?? this.shopOpen,
    );
  }

  /// Update a room in the game
  GameModel updateRoom(RoomModel room) {
    return copyWith(
      rooms: rooms.map((r) => r.id == room.id ? room : r).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentRoomId': currentRoomId,
    'rooms': rooms.map((r) => r.toJson()).toList(),
    'credits': credits,
    'playerPosition': playerPosition.toJson(),
    'gameMode': gameMode.name,
  };

  factory GameModel.fromJson(Map<String, dynamic> json) {
    final roomsJson = json['rooms'];
    final List<RoomModel> parsedRooms;

    if (roomsJson is List) {
      parsedRooms = roomsJson
          .whereType<Map<String, dynamic>>()
          .map(RoomModel.fromJson)
          .toList();
    } else {
      parsedRooms = [];
    }

    return GameModel(
      currentRoomId: json['currentRoomId'] as String? ?? '',
      rooms: parsedRooms,
      credits: json['credits'] as int? ?? GameConstants.startingCredits,
      playerPosition: json['playerPosition'] != null
          ? GridPosition.fromJson(
              json['playerPosition'] as Map<String, dynamic>,
            )
          : GameConstants.playerStartPosition,
      gameMode: json['gameMode'] != null
          ? GameMode.values.byName(json['gameMode'] as String)
          : GameMode.sim,
    );
  }

  /// Create initial game state with default server room
  factory GameModel.initial() {
    final roomId = generateRoomId();
    return GameModel(
      currentRoomId: roomId,
      rooms: [RoomModel.serverRoom(id: roomId, name: 'Server Room')],
    );
  }

  /// Get room by ID.
  ///
  /// Returns the [RoomModel] with the matching [id], or `null` if no room
  /// with that ID exists in the game.
  RoomModel? getRoomById(String id) {
    for (final room in rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  /// Get child rooms of a given parent
  List<RoomModel> getChildRooms(String parentId) {
    return rooms.where((r) => r.parentId == parentId).toList();
  }

  /// Get root rooms (no parent)
  List<RoomModel> get rootRooms {
    return rooms.where((r) => r.parentId == null).toList();
  }

  /// Add a new room to the game
  GameModel addRoom(RoomModel room) {
    return copyWith(rooms: [...rooms, room]);
  }

  /// Remove a room and all its children
  GameModel removeRoom(String roomId) {
    // Get all room IDs to remove (the room and all descendants)
    final idsToRemove = <String>{roomId};
    bool foundNew = true;
    while (foundNew) {
      foundNew = false;
      for (final room in rooms) {
        if (room.parentId != null &&
            idsToRemove.contains(room.parentId) &&
            !idsToRemove.contains(room.id)) {
          idsToRemove.add(room.id);
          foundNew = true;
        }
      }
    }

    // Also remove doors pointing to removed rooms
    final updatedRooms = rooms
        .where((r) => !idsToRemove.contains(r.id))
        .map(
          (r) => r.copyWith(
            doors: r.doors
                .where((d) => !idsToRemove.contains(d.targetRoomId))
                .toList(),
          ),
        )
        .toList();

    // If current room was removed, switch to first available
    String newCurrentRoomId = currentRoomId;
    if (idsToRemove.contains(currentRoomId) && updatedRooms.isNotEmpty) {
      newCurrentRoomId = updatedRooms.first.id;
    }

    return copyWith(rooms: updatedRooms, currentRoomId: newCurrentRoomId);
  }

  /// Navigate to a different room
  GameModel enterRoom(String roomId, GridPosition spawnPosition) {
    return copyWith(currentRoomId: roomId, playerPosition: spawnPosition);
  }

  /// Find a door in the current room by ID.
  ///
  /// Returns null if the door is not found.
  DoorModel? findDoorById(String doorId) {
    for (final door in currentRoom.doors) {
      if (door.id == doorId) return door;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    currentRoomId,
    rooms,
    credits,
    playerPosition,
    gameMode,
    placementMode,
    selectedTemplate,
    selectedCloudService,
    shopOpen,
  ];

  @override
  String toString() =>
      'GameModel(room: $currentRoomId, credits: $credits, position: $playerPosition, '
      'rooms: ${rooms.length})';
}
