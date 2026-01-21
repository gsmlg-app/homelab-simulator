import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_panels/game_widgets_panels.dart';

import 'credits_display.dart';
import 'interaction_hint.dart';

/// Main HUD overlay for the game
class HudOverlay extends StatefulWidget {
  final InteractionType currentInteraction;

  const HudOverlay({super.key, this.currentInteraction = InteractionType.none});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  bool _summaryExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Top bar
            Positioned(
              top: AppSpacing.topBarOffset,
              left: AppSpacing.topBarOffset,
              right: AppSpacing.topBarOffset,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CreditsDisplay(),
                  _buildModeIndicator(state.model.gameMode),
                ],
              ),
            ),

            // Room summary panel - top right
            Positioned(
              top: AppSpacing.roomSummaryOffset,
              right: AppSpacing.topBarOffset,
              child: SizedBox(
                width: AppSpacing.roomSummaryWidth,
                child: RoomSummaryPanel(
                  room: state.model.currentRoom,
                  expanded: _summaryExpanded,
                  onToggleExpand: () {
                    setState(() => _summaryExpanded = !_summaryExpanded);
                  },
                ),
              ),
            ),

            // Bottom center - interaction hint
            Positioned(
              bottom: AppSpacing.bottomHintOffset,
              left: 0,
              right: 0,
              child: Center(
                child: InteractionHint(
                  interactionType: widget.currentInteraction,
                ),
              ),
            ),

            // Placement mode indicator
            if (state.model.placementMode == PlacementMode.placing)
              Positioned(
                bottom: AppSpacing.topBarOffset,
                left: AppSpacing.topBarOffset,
                right: AppSpacing.topBarOffset,
                child: _buildPlacementHint(state.model),
              ),
          ],
        );
      },
    );
  }

  Widget _buildModeIndicator(GameMode mode) {
    return Container(
      padding: AppSpacing.paddingChip,
      decoration: BoxDecoration(
        color: mode == GameMode.sim ? AppColors.blue800 : AppColors.orange800,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        mode == GameMode.sim ? 'SIM MODE' : 'LIVE MODE',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSpacing.fontSizeSmall,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPlacementHint(GameModel model) {
    final templateName = model.selectedTemplate?.name ?? 'Device';

    return Container(
      padding: AppSpacing.paddingMs,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.amber700,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place, color: AppColors.amber400),
          const SizedBox(width: AppSpacing.s),
          Text(
            'Placing: $templateName',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSpacing.fontSizeDefault,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          const Text(
            'Click to place • ESC to cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSpacing.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
