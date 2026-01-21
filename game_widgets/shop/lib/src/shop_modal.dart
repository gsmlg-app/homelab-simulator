import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  /// Number of tabs in the shop modal (Devices, Cloud Services, Rooms)
  static const int _tabCount = 3;

  late TabController _tabController;
  bool _showAddRoomModal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
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
            color: AppColors.overlayBackground,
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
      width: AppSpacing.shopModalWidth,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height *
            AppSpacing.shopModalMaxHeightRatio,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: AppSpacing.borderRadiusXl,
        border: const Border.fromBorderSide(BorderSide(
          color: AppColors.cyan700,
          width: AppSpacing.borderWidth,
        )),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan900.withValues(alpha: 0.5),
            blurRadius: AppSpacing.modalShadowBlurRadius,
            spreadRadius: AppSpacing.modalShadowSpreadRadius,
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
      padding: AppSpacing.paddingM,
      decoration: const BoxDecoration(
        color: AppColors.overlayBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl - AppSpacing.borderWidth),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.store,
                color: AppColors.cyan400,
                size: AppSpacing.iconSizeLarge,
              ),
              SizedBox(width: AppSpacing.ms),
              Text(
                'TERMINAL',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSpacing.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  letterSpacing: AppSpacing.letterSpacingExtraWide,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: AppSpacing.paddingChip,
                decoration: const BoxDecoration(
                  color: AppColors.green800,
                  borderRadius: AppSpacing.borderRadiusSmall,
                ),
                child: Text(
                  '\$$credits',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.monospaceFontFamily,
                    fontSize: AppSpacing.fontSizeMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                tooltip: 'Close shop',
                onPressed: () {
                  context.read<GameBloc>().add(
                    const GameToggleShop(isOpen: false),
                  );
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
      color: AppColors.overlayBackground,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.cyan400,
        labelColor: AppColors.cyan400,
        unselectedLabelColor: AppColors.textSecondary,
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
      padding: AppSpacing.paddingM,
      itemCount: defaultDeviceTemplates.length,
      itemBuilder: (context, index) {
        final template = defaultDeviceTemplates[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
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
      padding: AppSpacing.paddingM,
      children: [
        // Add Room button
        InkWell(
          onTap: () => setState(() => _showAddRoomModal = true),
          borderRadius: AppSpacing.borderRadiusMedium,
          child: Container(
            padding: AppSpacing.paddingM,
            decoration: BoxDecoration(
              color: AppColors.modalAccentDark.withValues(alpha: 0.3),
              borderRadius: AppSpacing.borderRadiusMedium,
              border: const Border.fromBorderSide(BorderSide(
                color: AppColors.modalAccentDark,
                width: AppSpacing.borderWidth,
              )),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle,
                  color: AppColors.modalAccentLight,
                  size: AppSpacing.iconSizeLarge,
                ),
                SizedBox(width: AppSpacing.ms),
                Text(
                  'Add New Room',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSpacing.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        // Current room info
        Container(
          padding: AppSpacing.paddingMs,
          decoration: const BoxDecoration(
            color: AppColors.overlayBackground,
            borderRadius: AppSpacing.borderRadiusMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    model.currentRoom.type.icon,
                    color: model.currentRoom.type.color,
                    size: AppSpacing.iconSizeDefault,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Current: ${model.currentRoom.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${model.currentRoom.totalObjectCount} objects, ${model.currentRoom.doors.length} doors',
                style: const TextStyle(
                  color: AppColors.grey500,
                  fontSize: AppSpacing.fontSizeSmall,
                ),
              ),
            ],
          ),
        ),
        if (childRooms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Text(
            'Child Rooms (${childRooms.length})',
            style: const TextStyle(
              color: AppColors.grey500,
              fontSize: AppSpacing.fontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          ...childRooms.map((room) => _buildRoomCard(context, room, model)),
        ],
        // Parent room link
        if (model.currentRoom.parentId != null) ...[
          const SizedBox(height: AppSpacing.m),
          _buildParentRoomCard(context, model),
        ],
      ],
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room, GameModel model) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Container(
        padding: AppSpacing.paddingMs,
        decoration: const BoxDecoration(
          color: AppColors.overlayBackground,
          borderRadius: AppSpacing.borderRadiusMedium,
          border: Border.fromBorderSide(BorderSide(color: AppColors.grey700)),
        ),
        child: Row(
          children: [
            Icon(
              room.type.icon,
              color: room.type.color,
              size: AppSpacing.iconSizeMedium,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${room.totalObjectCount} objects',
                    style: const TextStyle(
                      color: AppColors.grey500,
                      fontSize: AppSpacing.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.redAccent,
              ),
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
    final parentId = model.currentRoom.parentId;
    if (parentId == null) return const SizedBox.shrink();

    final parentRoom = model.getRoomById(parentId);
    if (parentRoom == null) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.paddingMs,
      decoration: BoxDecoration(
        color: AppColors.blue900.withValues(alpha: 0.2),
        borderRadius: AppSpacing.borderRadiusMedium,
        border: const Border.fromBorderSide(BorderSide(color: AppColors.blue700)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_upward,
            color: AppColors.blue400,
            size: AppSpacing.iconSizeDefault,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Room',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSpacing.fontSizeSmall,
                  ),
                ),
                Text(
                  parentRoom.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
        backgroundColor: AppColors.grey900,
        title: const Text(
          'Delete Room?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${room.name}"? This will also remove all child rooms and their contents.',
          style: const TextStyle(color: AppColors.textSecondary),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
