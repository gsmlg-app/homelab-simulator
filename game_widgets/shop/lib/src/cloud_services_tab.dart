import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';

/// Tab content for browsing and selecting cloud services
class CloudServicesTab extends StatefulWidget {
  const CloudServicesTab({super.key});

  @override
  State<CloudServicesTab> createState() => _CloudServicesTabState();
}

class _CloudServicesTabState extends State<CloudServicesTab> {
  CloudProvider? _selectedProvider;
  ServiceCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameReady) return const SizedBox.shrink();

        // Filter services based on room type
        final roomType = state.model.currentRoom.type;
        final provider = _getProviderForRoomType(roomType);

        return Column(
          children: [
            // Provider filter chips
            _buildProviderFilter(provider),
            const Divider(height: 1),
            // Category filter chips
            _buildCategoryFilter(),
            const Divider(height: 1),
            // Services list
            Expanded(child: _buildServicesList(provider)),
          ],
        );
      },
    );
  }

  CloudProvider? _getProviderForRoomType(RoomType type) {
    return switch (type) {
      RoomType.aws => CloudProvider.aws,
      RoomType.gcp => CloudProvider.gcp,
      RoomType.cloudflare => CloudProvider.cloudflare,
      RoomType.vultr => CloudProvider.vultr,
      RoomType.azure => CloudProvider.azure,
      RoomType.digitalOcean => CloudProvider.digitalOcean,
      RoomType.serverRoom => null,
      RoomType.custom => null,
    };
  }

  Widget _buildProviderFilter(CloudProvider? roomProvider) {
    // If in a provider room, show only that provider
    if (roomProvider != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.overlayBackground,
        child: Row(
          children: [
            Icon(roomProvider.icon, color: roomProvider.color, size: 20),
            const SizedBox(width: 8),
            Text(
              '${roomProvider.displayName} Services',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // In server room, allow selecting any provider
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedProvider == null,
            onSelected: (_) => setState(() => _selectedProvider = null),
            selectedColor: AppColors.cyan700,
            labelStyle: TextStyle(
              color:
                  _selectedProvider == null ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.grey800,
          ),
          const SizedBox(width: 8),
          ...CloudProvider.values
              .where((p) => p != CloudProvider.none)
              .map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      provider.icon,
                      color: _selectedProvider == provider
                          ? AppColors.textPrimary
                          : provider.color,
                      size: 18,
                    ),
                    label: Text(provider.displayName),
                    selected: _selectedProvider == provider,
                    onSelected: (_) =>
                        setState(() => _selectedProvider = provider),
                    selectedColor: provider.color,
                    labelStyle: TextStyle(
                      color: _selectedProvider == provider
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.grey800,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
            selectedColor: AppColors.cyan700,
            labelStyle: TextStyle(
              color:
                  _selectedCategory == null ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            backgroundColor: AppColors.grey800,
          ),
          const SizedBox(width: 8),
          ...ServiceCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  category.icon,
                  color: _selectedCategory == category
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  size: 18,
                ),
                label: Text(category.displayName),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
                selectedColor: category.color,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(CloudProvider? roomProvider) {
    // Get base services based on provider filter
    final baseServices = roomProvider != null
        ? CloudServiceCatalog.getServicesForProvider(roomProvider)
        : _selectedProvider != null
        ? CloudServiceCatalog.getServicesForProvider(_selectedProvider!)
        : CloudServiceCatalog.allServices;

    // Filter by category if selected
    final services = _selectedCategory != null
        ? baseServices.where((s) => s.category == _selectedCategory).toList()
        : baseServices;

    if (services.isEmpty) {
      return Center(
        child: Text(
          'No services available',
          style: TextStyle(color: AppColors.grey500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final template = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ServiceCard(
            template: template,
            onTap: () {
              context.read<GameBloc>().add(GameSelectCloudService(template));
            },
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final CloudServiceTemplate template;
  final VoidCallback onTap;

  const _ServiceCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.overlayBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey700),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: template.provider.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                template.category.icon,
                color: template.provider.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChip(
                        template.provider.displayName,
                        template.provider.color,
                      ),
                      const SizedBox(width: 4),
                      _buildChip(
                        template.category.displayName,
                        AppColors.grey600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: AppColors.cyan400),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
