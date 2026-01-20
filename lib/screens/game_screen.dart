import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:game_widgets_hud/game_widgets_hud.dart';
import 'package:game_widgets_shop/game_widgets_shop.dart';

/// Main game screen composing Flame game with Flutter overlays
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  HomelabGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only create game once; late initialization after context is available
    _game ??= HomelabGame(
      gameBloc: context.read<GameBloc>(),
      worldBloc: context.read<WorldBloc>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, gameState) {
          if (gameState is GameLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Homelab...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (gameState is GameError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${gameState.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GameBloc>().add(const GameInitialize());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return BlocBuilder<WorldBloc, WorldState>(
            builder: (context, worldState) {
              return Stack(
                children: [
                  // Flame game
                  Positioned.fill(child: GameWidget(game: _game!)),

                  // HUD overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: HudOverlay(
                        currentInteraction: worldState.availableInteraction,
                      ),
                    ),
                  ),

                  // Shop modal
                  const Positioned.fill(child: ShopModal()),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
