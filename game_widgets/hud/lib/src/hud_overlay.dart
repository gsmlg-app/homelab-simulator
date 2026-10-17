import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import 'credits_display.dart';
import 'interaction_hint.dart';

/// Compact scene controls. Only the visible controls participate in hit testing.
class HudOverlay extends StatefulWidget {
  final InteractionType currentInteraction;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetCamera;
  final VoidCallback? onInteract;
  final VoidCallback? onPanelOpened;
  final ValueChanged<String>? onNavigate;

  const HudOverlay({
    super.key,
    this.currentInteraction = InteractionType.none,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetCamera,
    this.onInteract,
    this.onPanelOpened,
    this.onNavigate,
  });

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  static const _panelColor = Color(0xee182b35);

  void _showDetails(RoomModel room) {
    widget.onPanelOpened?.call();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1d303b),
        insetPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            const Expanded(child: Text('Room details')),
            IconButton(
              tooltip: 'Close details',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 320,
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _detail('Floor plan', '${room.width} × ${room.height} cells'),
                _detail(
                  'Equipment',
                  '${room.definition?.objects.length ?? 0} fixtures',
                ),
                _detail('Devices', '${room.devices.length}'),
                _detail('Cloud services', '${room.cloudServices.length}'),
                _detail('Connections', '${room.doors.length}'),
                const Divider(height: 28),
                const Text(
                  'Click or tap the floor to walk. Use the access terminal to open the shop.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );

  Widget _surface(Widget child) => Material(
    color: _panelColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xff3a5662)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) {
          return const Center(child: CircularProgressIndicator());
        }
        final model = state.model;
        final room = model.currentRoom;
        final destinations = {
          for (final target
              in room.doors
                  .map((door) => model.getRoomById(door.targetRoomId))
                  .nonNulls)
            target.id: target,
        };
        return LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Flexible(
                      child: _surface(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.grid_view_rounded,
                                color: Color(0xff85c8c9),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      room.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${room.width} × ${room.height} · ${model.gameMode == GameMode.sim ? 'SIM MODE' : 'LIVE MODE'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    const CreditsDisplay(),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: _surface(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: widget.onZoomOut,
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        tooltip: 'Fit room',
                        onPressed: widget.onResetCamera,
                        icon: const Icon(Icons.fit_screen),
                      ),
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: widget.onZoomIn,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: _surface(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Room details',
                        onPressed: () => _showDetails(room),
                        icon: const Icon(Icons.info_outline),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Connected rooms',
                        enabled: destinations.isNotEmpty,
                        onOpened: widget.onPanelOpened,
                        onSelected: widget.onNavigate,
                        icon: const Icon(Icons.map_outlined),
                        itemBuilder: (_) => [
                          for (final target in destinations.values)
                            PopupMenuItem(
                              value: target.id,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.door_front_door_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(target.name),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (model.placementMode == PlacementMode.placing)
                Positioned(
                  bottom: 72,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: _surface(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            Text(
                              'Placing: ${model.selectedTemplate?.name ?? model.selectedCloudService?.name ?? 'Device'}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.read<GameBloc>().add(
                                const GameCancelPlacement(),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (!model.shopOpen)
                Positioned(
                  bottom: 72,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: InteractionHint(
                      interactionType: widget.currentInteraction,
                      onInteract: widget.onInteract,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
