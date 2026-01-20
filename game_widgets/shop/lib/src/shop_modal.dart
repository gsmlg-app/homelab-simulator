import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import 'device_card.dart';
import 'add_room_modal.dart';
import 'cloud_services_tab.dart';

/// Modal dialog for the device shop with tabs
class ShopModal extends StatefulWidget {
  const ShopModal({super.key});

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAddRoomModal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) return const SizedBox.shrink();
        if (!state.model.shopOpen) return const SizedBox.shrink();

        if (_showAddRoomModal) {
          return AddRoomModal(
            onClose: () {
              setState(() => _showAddRoomModal = false);
              context.read<GameBloc>().add(const GameToggleShop(isOpen: false));
            },
          );
        }

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
          _buildTabs(),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeviceList(context, model.credits),
                const CloudServicesTab(),
                _buildRoomList(context, model),
              ],
            ),
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
                'TERMINAL',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  context
                      .read<GameBloc>()
                      .add(const GameToggleShop(isOpen: false));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.black26,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyan.shade400,
        labelColor: Colors.cyan.shade400,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.devices), text: 'Devices'),
          Tab(icon: Icon(Icons.cloud), text: 'Services'),
          Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
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

  Widget _buildRoomList(BuildContext context, GameModel model) {
    final childRooms = model.getChildRooms(model.currentRoomId);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        // Add Room button
        InkWell(
          onTap: () => setState(() => _showAddRoomModal = true),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade700, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, color: Colors.purple.shade400, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Add New Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Current room info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getRoomTypeIcon(model.currentRoom.type),
                    color: _getRoomTypeColor(model.currentRoom.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current: ${model.currentRoom.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${model.currentRoom.totalObjectCount} objects, ${model.currentRoom.doors.length} doors',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        if (childRooms.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Child Rooms (${childRooms.length})',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...childRooms.map((room) => _buildRoomCard(context, room, model)),
        ],
        // Parent room link
        if (model.currentRoom.parentId != null) ...[
          const SizedBox(height: 16),
          _buildParentRoomCard(context, model),
        ],
      ],
    );
  }

  Widget _buildRoomCard(
      BuildContext context, RoomModel room, GameModel model) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Row(
          children: [
            Icon(
              _getRoomTypeIcon(room.type),
              color: _getRoomTypeColor(room.type),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${room.totalObjectCount} objects',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(context, room);
              },
              tooltip: 'Remove room',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentRoomCard(BuildContext context, GameModel model) {
    final parentRoom = model.getRoomById(model.currentRoom.parentId!);
    if (parentRoom == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_upward, color: Colors.blue.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Room',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  parentRoom.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Room?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${room.name}"? This will also remove all child rooms and their contents.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GameBloc>().add(GameRemoveRoom(room.id));
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getRoomTypeIcon(RoomType type) {
    return switch (type) {
      RoomType.serverRoom => Icons.dns,
      RoomType.aws => Icons.cloud,
      RoomType.gcp => Icons.cloud_circle,
      RoomType.cloudflare => Icons.security,
      RoomType.vultr => Icons.dns,
      RoomType.azure => Icons.cloud_queue,
      RoomType.digitalOcean => Icons.water_drop,
      RoomType.custom => Icons.room,
    };
  }

  Color _getRoomTypeColor(RoomType type) {
    return switch (type) {
      RoomType.serverRoom => Colors.grey,
      RoomType.aws => const Color(0xFFFF9900),
      RoomType.gcp => const Color(0xFF4285F4),
      RoomType.cloudflare => const Color(0xFFF38020),
      RoomType.vultr => const Color(0xFF007BFC),
      RoomType.azure => const Color(0xFF0078D4),
      RoomType.digitalOcean => const Color(0xFF0080FF),
      RoomType.custom => Colors.purple,
    };
  }
}
