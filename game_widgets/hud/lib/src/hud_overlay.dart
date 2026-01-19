import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';

import 'credits_display.dart';
import 'interaction_hint.dart';

/// Main HUD overlay for the game
class HudOverlay extends StatelessWidget {
  final InteractionType currentInteraction;

  const HudOverlay({
    super.key,
    this.currentInteraction = InteractionType.none,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          children: [
            // Top bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CreditsDisplay(),
                  _buildModeIndicator(state.model.gameMode),
                ],
              ),
            ),

            // Bottom center - interaction hint
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: InteractionHint(
                  interactionType: currentInteraction,
                ),
              ),
            ),

            // Placement mode indicator
            if (state.model.placementMode == PlacementMode.placing)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildPlacementHint(state.model),
              ),
          ],
        );
      },
    );
  }

  Widget _buildModeIndicator(GameMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: mode == GameMode.sim
            ? Colors.blue.shade800
            : Colors.orange.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode == GameMode.sim ? 'SIM MODE' : 'LIVE MODE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPlacementHint(dynamic model) {
    final templateName = model.selectedTemplate?.name ?? 'Device';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place, color: Colors.amber.shade400),
          const SizedBox(width: 8),
          Text(
            'Placing: $templateName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Click to place • ESC to cancel',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
