import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

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
        color: Colors.black26,
        child: Row(
          children: [
            Icon(
              roomProvider.icon,
              color: roomProvider.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${roomProvider.displayName} Services',
              style: const TextStyle(
                color: Colors.white,
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
            selectedColor: Colors.cyan.shade700,
            labelStyle: TextStyle(
              color: _selectedProvider == null ? Colors.white : Colors.white70,
            ),
            backgroundColor: Colors.grey.shade800,
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
                          ? Colors.white
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
                          ? Colors.white
                          : Colors.white70,
                    ),
                    backgroundColor: Colors.grey.shade800,
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
            selectedColor: Colors.cyan.shade700,
            labelStyle: TextStyle(
              color: _selectedCategory == null ? Colors.white : Colors.white70,
            ),
            backgroundColor: Colors.grey.shade800,
          ),
          const SizedBox(width: 8),
          ...ServiceCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  category.icon,
                  color: _selectedCategory == category
                      ? Colors.white
                      : Colors.white70,
                  size: 18,
                ),
                label: Text(category.displayName),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
                selectedColor: category.color,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? Colors.white
                      : Colors.white70,
                ),
                backgroundColor: Colors.grey.shade800,
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
          style: TextStyle(color: Colors.grey.shade500),
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
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                        Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: Colors.cyan.shade400),
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

extension on CloudProvider {
  String get displayName => switch (this) {
    CloudProvider.aws => 'AWS',
    CloudProvider.gcp => 'GCP',
    CloudProvider.cloudflare => 'Cloudflare',
    CloudProvider.vultr => 'Vultr',
    CloudProvider.azure => 'Azure',
    CloudProvider.digitalOcean => 'DigitalOcean',
    CloudProvider.none => 'None',
  };

  IconData get icon => switch (this) {
    CloudProvider.aws => Icons.cloud,
    CloudProvider.gcp => Icons.cloud_circle,
    CloudProvider.cloudflare => Icons.security,
    CloudProvider.vultr => Icons.dns,
    CloudProvider.azure => Icons.cloud_queue,
    CloudProvider.digitalOcean => Icons.water_drop,
    CloudProvider.none => Icons.settings,
  };

  Color get color => switch (this) {
    CloudProvider.aws => const Color(0xFFFF9900),
    CloudProvider.gcp => const Color(0xFF4285F4),
    CloudProvider.cloudflare => const Color(0xFFF38020),
    CloudProvider.vultr => const Color(0xFF007BFC),
    CloudProvider.azure => const Color(0xFF0078D4),
    CloudProvider.digitalOcean => const Color(0xFF0080FF),
    CloudProvider.none => Colors.purple,
  };
}

extension on ServiceCategory {
  String get displayName => switch (this) {
    ServiceCategory.compute => 'Compute',
    ServiceCategory.storage => 'Storage',
    ServiceCategory.database => 'Database',
    ServiceCategory.networking => 'Network',
    ServiceCategory.serverless => 'Serverless',
    ServiceCategory.container => 'Container',
    ServiceCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    ServiceCategory.compute => Icons.computer,
    ServiceCategory.storage => Icons.storage,
    ServiceCategory.database => Icons.table_chart,
    ServiceCategory.networking => Icons.hub,
    ServiceCategory.serverless => Icons.flash_on,
    ServiceCategory.container => Icons.view_in_ar,
    ServiceCategory.other => Icons.more_horiz,
  };

  Color get color => switch (this) {
    ServiceCategory.compute => Colors.blue,
    ServiceCategory.storage => Colors.green,
    ServiceCategory.database => Colors.orange,
    ServiceCategory.networking => Colors.purple,
    ServiceCategory.serverless => Colors.yellow.shade700,
    ServiceCategory.container => Colors.teal,
    ServiceCategory.other => Colors.grey,
  };
}
