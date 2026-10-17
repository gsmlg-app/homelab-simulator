import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

/// Shows interaction hints when near interactable objects
class InteractionHint extends StatelessWidget {
  final InteractionType interactionType;
  final VoidCallback? onInteract;

  const InteractionHint({
    super.key,
    required this.interactionType,
    this.onInteract,
  });

  @override
  Widget build(BuildContext context) {
    if (interactionType == InteractionType.none) {
      return const SizedBox.shrink();
    }

    final message = switch (interactionType) {
      InteractionType.terminal =>
        onInteract == null ? 'Press E to open shop' : 'Open shop',
      InteractionType.device =>
        onInteract == null ? 'Press E to interact' : 'Interact',
      InteractionType.door =>
        onInteract == null ? 'Press E to enter' : 'Enter room',
      InteractionType.cloudConsole =>
        onInteract == null
            ? 'Press E to open cloud console'
            : 'Open cloud console',
      InteractionType.none => '',
    };

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) return const SizedBox.shrink();
        if (state.model.shopOpen || state.model.cloudPanelOpen) {
          return const SizedBox.shrink();
        }

        final hint = AnimatedOpacity(
          opacity: 1.0,
          duration: AppSpacing.animationFast,
          child: Container(
            padding: AppSpacing.paddingHudPill,
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: AppSpacing.borderRadiusMedium,
              border: Border.all(
                color: AppColors.cyan700,
                width: AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.cyan800,
                    borderRadius: AppSpacing.borderRadiusSmall,
                  ),
                  child: const Text(
                    'E',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.monospaceFontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSpacing.fontSizeDefault,
                  ),
                ),
              ],
            ),
          ),
        );
        return onInteract == null
            ? hint
            : GestureDetector(onTap: onInteract, child: hint);
      },
    );
  }
}
