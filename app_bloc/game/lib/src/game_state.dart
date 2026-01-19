import 'package:equatable/equatable.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// State wrapper for GameBloc
sealed class GameState extends Equatable {
  const GameState();
}

/// Initial loading state
class GameLoading extends GameState {
  const GameLoading();

  @override
  List<Object?> get props => [];
}

/// Game loaded and ready
class GameReady extends GameState {
  final GameModel model;

  const GameReady(this.model);

  @override
  List<Object?> get props => [model];
}

/// Error state
class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
