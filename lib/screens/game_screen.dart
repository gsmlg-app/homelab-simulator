import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import '../cloud_center/cloud_center_session.dart';
import '../cloud_center/cloud_center_overlay.dart';

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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  HomelabGame? _game;
  bool _loggingOut = false;
  final _gameFocus = FocusNode(debugLabel: 'CloudCenterGame');
  late final CloudCenterSession _cloud;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cloud = CloudCenterSession(
      onClose: () {
        _game?.setCloudPanelOpen(false);
        if (mounted && !_loggingOut) _gameFocus.requestFocus();
      },
      onSummaries: (summaries) => _game?.updateCloudSummaries(summaries),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _cloud.setForeground(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloud.dispose();
    _gameFocus.dispose();
    super.dispose();
  }

  Future<void> _logOut() async {
    if (_loggingOut) return;
    _loggingOut = true;
    _game?.cancelRoute();
    await _cloud.signOut();
    if (!mounted) return;

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
            onCloudConsoleOpened: (console) => unawaited(_cloud.open(console)),
            onCloudPanelCloseRequested: _cloud.closePanel,
          );
          return BlocBuilder<WorldBloc, WorldState>(
            builder: (context, worldState) {
              return Stack(
                children: [
                  // Flame game
                  Positioned.fill(
                    child: GameWidget(
                      key: ObjectKey(game),
                      game: game,
                      focusNode: _gameFocus,
                    ),
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

                  if (gameState is GameReady &&
                      gameState.model.cloudCenterEntryStatus !=
                          CloudCenterEntryStatus.available)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Text(
                        'Cloud Center entry: ${gameState.model.cloudCenterEntryStatus.name}',
                      ),
                    ),

                  // Shop modal
                  const Positioned.fill(child: ShopModal()),
                  Positioned.fill(child: CloudCenterOverlay(session: _cloud)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
