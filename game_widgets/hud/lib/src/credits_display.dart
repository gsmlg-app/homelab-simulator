import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';

/// Displays current credits
class CreditsDisplay extends StatelessWidget {
  const CreditsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final credits = state is GameReady ? state.model.credits : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade700, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.green.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '\$$credits',
                style: TextStyle(
                  color: Colors.green.shade400,
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
