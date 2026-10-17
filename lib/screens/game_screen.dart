import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_asset_characters/game_asset_characters.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:game_widgets_hud/game_widgets_hud.dart';
import 'package:game_widgets_shop/game_widgets_shop.dart';

import 'start_menu_screen.dart';

/// Main game screen composing Flame game with Flutter overlays
class GameScreen extends StatefulWidget {
  final CharacterSpriteSheet spriteSheet;

  const GameScreen({super.key, this.spriteSheet = GameCharacters.mainMale});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  HomelabGame? _game;
  bool _loggingOut = false;

  void _logOut() {
    if (_loggingOut) return;
    _loggingOut = true;
    _game?.cancelRoute();

    final gameBloc = context.read<GameBloc>();
    gameBloc.add(const GameSave());
    gameBloc.add(const GameToggleShop(isOpen: false));
    gameBloc.add(const GameCancelPlacement());
    context.read<WorldBloc>().add(const WorldReset());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const StartMenuScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'HOMELAB',
          style: TextStyle(fontSize: 14, letterSpacing: 2),
        ),
        actions: [
          TextButton.icon(
            onPressed: _logOut,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, gameState) {
          if (gameState is GameLoading) {
            _game?.cancelRoute();
            _game = null;
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.m),
                  Text(
                    'Loading Homelab...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (gameState is GameError) {
            _game?.cancelRoute();
            _game = null;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: AppColors.redAccent,
                    size: AppSpacing.errorIconSize,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Error: ${gameState.message}',
                    style: const TextStyle(color: AppColors.redAccent),
                  ),
                  const SizedBox(height: AppSpacing.m),
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

          // Catalog initialization completes before GameReady. A retry after
          // loading/error creates a fresh scene rather than remounting a removed
          // Flame instance; ordinary model/map updates retain this instance.
          final game = _game ??= HomelabGame(
            gameBloc: context.read<GameBloc>(),
            worldBloc: context.read<WorldBloc>(),
            spriteSheet: widget.spriteSheet,
          );
          return BlocBuilder<WorldBloc, WorldState>(
            builder: (context, worldState) {
              return Stack(
                children: [
                  // Flame game
                  Positioned.fill(
                    child: GameWidget(key: ObjectKey(game), game: game),
                  ),

                  // HUD overlay
                  Positioned.fill(
                    child: HudOverlay(
                      currentInteraction: worldState.availableInteraction,
                      onZoomIn: game.zoomIn,
                      onZoomOut: game.zoomOut,
                      onResetCamera: game.resetCamera,
                      onInteract: game.interact,
                      onNavigate: game.navigateToRoom,
                      onPanelOpened: game.cancelRoute,
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
