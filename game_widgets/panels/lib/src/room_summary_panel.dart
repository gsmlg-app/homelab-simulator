import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';

import 'info_panel.dart';

/// Panel showing room summary with object counts
class RoomSummaryPanel extends StatelessWidget {
  final RoomModel room;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  const RoomSummaryPanel({
    super.key,
    required this.room,
    this.expanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return InfoPanel(
      title: room.name,
      icon: room.type.icon,
      children: [
        // Room type and size
        _buildInfoRow('Type', room.type.displayName, room.type.color),
        _buildInfoRow(
          'Size',
          '${room.width} × ${room.height}',
          Colors.grey.shade400,
        ),
        if (room.regionCode != null)
          _buildInfoRow('Region', room.regionCode!, Colors.cyan.shade400),

        const SizedBox(height: 8),
        const Divider(color: Colors.grey, height: 1),
        const SizedBox(height: 8),

        // Object counts header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OBJECTS',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${room.totalObjectCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Device counts
        if (room.devices.isNotEmpty) ...[
          _buildSectionHeader('Devices', room.devices.length),
          if (expanded)
            _buildDeviceCounts()
          else
            _buildCompactCounts('devices'),
        ],

        // Cloud service counts
        if (room.cloudServices.isNotEmpty) ...[
          if (room.devices.isNotEmpty) const SizedBox(height: 8),
          _buildSectionHeader('Cloud Services', room.cloudServices.length),
          if (expanded)
            _buildCloudServiceCounts()
          else
            _buildCompactCounts('services'),
        ],

        // Door count
        if (room.doors.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader('Doors', room.doors.length),
        ],

        // Empty state
        if (room.totalObjectCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No objects placed',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Expand/collapse button
        if (room.totalObjectCount > 0 && onToggleExpand != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggleExpand,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  expanded ? 'Show less' : 'Show details',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCompactCounts(String type) {
    if (type == 'devices') {
      final counts = <DeviceType, int>{};
      for (final device in room.devices) {
        counts[device.type] = (counts[device.type] ?? 0) + 1;
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((e) {
          return _buildCountChip(
            _getDeviceIcon(e.key),
            e.value,
            Colors.blue.shade700,
          );
        }).toList(),
      );
    } else {
      final counts = <CloudProvider, int>{};
      for (final service in room.cloudServices) {
        counts[service.provider] = (counts[service.provider] ?? 0) + 1;
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((e) {
          return _buildCountChip(
            _getProviderIcon(e.key),
            e.value,
            _getProviderColor(e.key),
          );
        }).toList(),
      );
    }
  }

  Widget _buildCountChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCounts() {
    final counts = <DeviceType, int>{};
    for (final device in room.devices) {
      counts[device.type] = (counts[device.type] ?? 0) + 1;
    }

    return Column(
      children: counts.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                _getDeviceIcon(e.key),
                size: 14,
                color: Colors.blue.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDeviceTypeName(e.key),
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                ),
              ),
              Text(
                '${e.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCloudServiceCounts() {
    // Group by provider and category
    final byProvider = <CloudProvider, Map<ServiceCategory, int>>{};
    for (final service in room.cloudServices) {
      byProvider.putIfAbsent(service.provider, () => {});
      byProvider[service.provider]![service.category] =
          (byProvider[service.provider]![service.category] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byProvider.entries.map((providerEntry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider header
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  Icon(
                    _getProviderIcon(providerEntry.key),
                    size: 12,
                    color: _getProviderColor(providerEntry.key),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getProviderName(providerEntry.key),
                    style: TextStyle(
                      color: _getProviderColor(providerEntry.key),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Category counts
            ...providerEntry.value.entries.map((catEntry) {
              return Padding(
                padding: const EdgeInsets.only(left: 18, top: 1, bottom: 1),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(catEntry.key),
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getCategoryName(catEntry.key),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      '${catEntry.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.server => Icons.dns,
      DeviceType.computer => Icons.computer,
      DeviceType.phone => Icons.phone_android,
      DeviceType.router => Icons.router,
      DeviceType.switch_ => Icons.hub,
      DeviceType.nas => Icons.storage,
      DeviceType.iot => Icons.sensors,
    };
  }

  String _getDeviceTypeName(DeviceType type) {
    return switch (type) {
      DeviceType.server => 'Server',
      DeviceType.computer => 'Computer',
      DeviceType.phone => 'Phone',
      DeviceType.router => 'Router',
      DeviceType.switch_ => 'Switch',
      DeviceType.nas => 'NAS',
      DeviceType.iot => 'IoT Device',
    };
  }

  IconData _getProviderIcon(CloudProvider provider) {
    return switch (provider) {
      CloudProvider.aws => Icons.cloud,
      CloudProvider.gcp => Icons.cloud_circle,
      CloudProvider.cloudflare => Icons.security,
      CloudProvider.vultr => Icons.dns,
      CloudProvider.azure => Icons.cloud_queue,
      CloudProvider.digitalOcean => Icons.water_drop,
      CloudProvider.none => Icons.cloud_off,
    };
  }

  Color _getProviderColor(CloudProvider provider) {
    return switch (provider) {
      CloudProvider.aws => const Color(0xFFFF9900),
      CloudProvider.gcp => const Color(0xFF4285F4),
      CloudProvider.cloudflare => const Color(0xFFF38020),
      CloudProvider.vultr => const Color(0xFF007BFC),
      CloudProvider.azure => const Color(0xFF0078D4),
      CloudProvider.digitalOcean => const Color(0xFF0080FF),
      CloudProvider.none => Colors.grey,
    };
  }

  String _getProviderName(CloudProvider provider) {
    return switch (provider) {
      CloudProvider.aws => 'AWS',
      CloudProvider.gcp => 'GCP',
      CloudProvider.cloudflare => 'Cloudflare',
      CloudProvider.vultr => 'Vultr',
      CloudProvider.azure => 'Azure',
      CloudProvider.digitalOcean => 'DigitalOcean',
      CloudProvider.none => 'None',
    };
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    return switch (category) {
      ServiceCategory.compute => Icons.computer,
      ServiceCategory.storage => Icons.storage,
      ServiceCategory.database => Icons.table_chart,
      ServiceCategory.networking => Icons.hub,
      ServiceCategory.serverless => Icons.flash_on,
      ServiceCategory.container => Icons.view_in_ar,
      ServiceCategory.other => Icons.more_horiz,
    };
  }

  String _getCategoryName(ServiceCategory category) {
    return switch (category) {
      ServiceCategory.compute => 'Compute',
      ServiceCategory.storage => 'Storage',
      ServiceCategory.database => 'Database',
      ServiceCategory.networking => 'Networking',
      ServiceCategory.serverless => 'Serverless',
      ServiceCategory.container => 'Container',
      ServiceCategory.other => 'Other',
    };
  }
}
