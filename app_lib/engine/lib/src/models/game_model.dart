import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'room_model.dart';
import 'device_template.dart';

/// Main game state model
class GameModel extends Equatable {
  final String currentRoomId;
  final List<RoomModel> rooms;
  final int credits;
  final GridPosition playerPosition;
  final GameMode gameMode;
  final PlacementMode placementMode;
  final DeviceTemplate? selectedTemplate;
  final bool shopOpen;

  const GameModel({
    required this.currentRoomId,
    required this.rooms,
    this.credits = GameConstants.startingCredits,
    this.playerPosition = GameConstants.playerStartPosition,
    this.gameMode = GameMode.sim,
    this.placementMode = PlacementMode.none,
    this.selectedTemplate,
    this.shopOpen = false,
  });

  /// Get the current room
  RoomModel get currentRoom {
    return rooms.firstWhere(
      (r) => r.id == currentRoomId,
      orElse: () => rooms.first,
    );
  }

  GameModel copyWith({
    String? currentRoomId,
    List<RoomModel>? rooms,
    int? credits,
    GridPosition? playerPosition,
    GameMode? gameMode,
    PlacementMode? placementMode,
    DeviceTemplate? selectedTemplate,
    bool clearSelectedTemplate = false,
    bool? shopOpen,
  }) {
    return GameModel(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      rooms: rooms ?? this.rooms,
      credits: credits ?? this.credits,
      playerPosition: playerPosition ?? this.playerPosition,
      gameMode: gameMode ?? this.gameMode,
      placementMode: placementMode ?? this.placementMode,
      selectedTemplate:
          clearSelectedTemplate ? null : (selectedTemplate ?? this.selectedTemplate),
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
    return GameModel(
      currentRoomId: json['currentRoomId'] as String,
      rooms: (json['rooms'] as List<dynamic>)
          .map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      credits: json['credits'] as int? ?? GameConstants.startingCredits,
      playerPosition: json['playerPosition'] != null
          ? GridPosition.fromJson(json['playerPosition'] as Map<String, dynamic>)
          : GameConstants.playerStartPosition,
      gameMode: json['gameMode'] != null
          ? GameMode.values.byName(json['gameMode'] as String)
          : GameMode.sim,
    );
  }

  /// Create initial game state
  factory GameModel.initial() {
    final roomId = generateRoomId();
    return GameModel(
      currentRoomId: roomId,
      rooms: [
        RoomModel(
          id: roomId,
          name: 'Main Room',
        ),
      ],
    );
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
        shopOpen,
      ];
}
