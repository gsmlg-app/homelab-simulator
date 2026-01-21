import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Displays current credits
class CreditsDisplay extends StatelessWidget {
  const CreditsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final credits = state is GameReady ? state.model.credits : 0;

        return Container(
          padding: AppSpacing.paddingHudPill,
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.green700, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: AppColors.green400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '\$$credits',
                style: const TextStyle(
                  color: AppColors.green400,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
