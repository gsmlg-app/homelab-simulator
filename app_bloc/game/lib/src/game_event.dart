import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Events for GameBloc
sealed class GameEvent extends Equatable {
  const GameEvent();
}

/// Initialize game (load from save or create new)
class GameInitialize extends GameEvent {
  const GameInitialize();

  @override
  List<Object?> get props => [];
}

/// Move player in a direction
class GameMovePlayer extends GameEvent {
  final Direction direction;
  const GameMovePlayer(this.direction);

  @override
  List<Object?> get props => [direction];
}

/// Move player to a specific position (tap-to-move)
class GameMovePlayerTo extends GameEvent {
  final GridPosition position;
  const GameMovePlayerTo(this.position);

  @override
  List<Object?> get props => [position];
}

/// Toggle shop visibility
class GameToggleShop extends GameEvent {
  final bool? isOpen;
  const GameToggleShop({this.isOpen});

  @override
  List<Object?> get props => [isOpen];
}

/// Select a device template for placement
class GameSelectTemplate extends GameEvent {
  final DeviceTemplate template;
  const GameSelectTemplate(this.template);

  @override
  List<Object?> get props => [template];
}

/// Cancel placement mode
class GameCancelPlacement extends GameEvent {
  const GameCancelPlacement();

  @override
  List<Object?> get props => [];
}

/// Place a device at position
class GamePlaceDevice extends GameEvent {
  final GridPosition position;
  const GamePlaceDevice(this.position);

  @override
  List<Object?> get props => [position];
}

/// Remove a device
class GameRemoveDevice extends GameEvent {
  final String deviceId;
  const GameRemoveDevice(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

/// Change game mode
class GameChangeMode extends GameEvent {
  final GameMode mode;
  const GameChangeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Save game
class GameSave extends GameEvent {
  const GameSave();

  @override
  List<Object?> get props => [];
}

/// Enter a room via door
class GameEnterRoom extends GameEvent {
  final String roomId;
  final GridPosition spawnPosition;
  const GameEnterRoom({required this.roomId, required this.spawnPosition});

  @override
  List<Object?> get props => [roomId, spawnPosition];
}
