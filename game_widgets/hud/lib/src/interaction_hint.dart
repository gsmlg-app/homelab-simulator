import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Shows interaction hints when near interactable objects
class InteractionHint extends StatelessWidget {
  final InteractionType interactionType;

  const InteractionHint({
    super.key,
    required this.interactionType,
  });

  @override
  Widget build(BuildContext context) {
    if (interactionType == InteractionType.none) {
      return const SizedBox.shrink();
    }

    final message = switch (interactionType) {
      InteractionType.terminal => 'Press E to open shop',
      InteractionType.device => 'Press E to interact',
      InteractionType.door => 'Press E to enter',
      InteractionType.none => '',
    };

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) return const SizedBox.shrink();
        if (state.model.shopOpen) return const SizedBox.shrink();

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.shade700, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'E',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
