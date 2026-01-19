import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import 'device_card.dart';

/// Modal dialog for the device shop
class ShopModal extends StatelessWidget {
  const ShopModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) return const SizedBox.shrink();
        if (!state.model.shopOpen) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            context.read<GameBloc>().add(const GameToggleShop(isOpen: false));
          },
          child: Container(
            color: Colors.black54,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping modal
                child: _buildShopContent(context, state.model),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopContent(BuildContext context, GameModel model) {
    return Container(
      width: 500,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade700, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.shade900.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, model.credits),
          Flexible(
            child: _buildDeviceList(context, model.credits),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int credits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.cyan.shade400, size: 28),
              const SizedBox(width: 12),
              const Text(
                'DEVICE SHOP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$$credits',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  context.read<GameBloc>().add(const GameToggleShop(isOpen: false));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, int credits) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: defaultDeviceTemplates.length,
      itemBuilder: (context, index) {
        final template = defaultDeviceTemplates[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DeviceCard(
            template: template,
            currentCredits: credits,
            onTap: () {
              context.read<GameBloc>().add(GameSelectTemplate(template));
            },
          ),
        );
      },
    );
  }
}
