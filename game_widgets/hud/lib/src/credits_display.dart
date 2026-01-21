import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

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
            borderRadius: AppSpacing.borderRadiusMedium,
            border: Border.all(
              color: AppColors.green700,
              width: AppSpacing.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: AppColors.green400,
                size: AppSpacing.iconSizeMedium,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '\$$credits',
                style: const TextStyle(
                  color: AppColors.green400,
                  fontSize: AppSpacing.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.monospaceFontFamily,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
