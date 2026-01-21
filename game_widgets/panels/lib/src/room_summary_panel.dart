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
        InfoRow(
          label: 'Type',
          value: room.type.displayName,
          valueColor: room.type.color,
          fontSize: AppSpacing.fontSizePanel,
          verticalPadding: 2,
          labelColor: AppColors.grey500,
        ),
        InfoRow(
          label: 'Size',
          value: '${room.width} × ${room.height}',
          valueColor: AppColors.grey400,
          fontSize: AppSpacing.fontSizePanel,
          verticalPadding: 2,
          labelColor: AppColors.grey500,
        ),
        if (room.regionCode != null)
          InfoRow(
            label: 'Region',
            value: room.regionCode!,
            valueColor: AppColors.cyan400,
            fontSize: AppSpacing.fontSizePanel,
            verticalPadding: 2,
            labelColor: AppColors.grey500,
          ),

        const SizedBox(height: AppSpacing.s),
        const Divider(color: AppColors.grey600, height: 1),
        const SizedBox(height: AppSpacing.s),

        // Object counts header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'OBJECTS',
                style: TextStyle(
                  color: AppColors.grey500,
                  fontSize: AppSpacing.fontSizeXs,
                  fontWeight: FontWeight.bold,
                  letterSpacing: AppSpacing.letterSpacingWide,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.borderWidth,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cyan800,
                borderRadius: AppSpacing.borderRadiusMedium,
              ),
              child: Text(
                '${room.totalObjectCount}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSpacing.fontSizeXs,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // Device counts
        if (room.devices.isNotEmpty) ...[
          _buildSectionHeader('Devices', room.devices.length),
          if (expanded) _buildDeviceCounts() else _buildCompactDeviceCounts(),
        ],

        // Cloud service counts
        if (room.cloudServices.isNotEmpty) ...[
          if (room.devices.isNotEmpty) const SizedBox(height: AppSpacing.s),
          _buildSectionHeader('Cloud Services', room.cloudServices.length),
          if (expanded)
            _buildCloudServiceCounts()
          else
            _buildCompactServiceCounts(),
        ],

        // Door count
        if (room.doors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _buildSectionHeader('Doors', room.doors.length),
        ],

        // Empty state
        if (room.totalObjectCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text(
              'No objects placed',
              style: TextStyle(
                color: AppColors.grey600,
                fontSize: AppSpacing.fontSizePanel,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Expand/collapse button
        if (room.totalObjectCount > 0 && onToggleExpand != null) ...[
          const SizedBox(height: AppSpacing.s),
          GestureDetector(
            onTap: onToggleExpand,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.grey500,
                  size: AppSpacing.iconSizeSmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  expanded ? 'Show less' : 'Show details',
                  style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: AppSpacing.fontSizeXs,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.grey400,
              fontSize: AppSpacing.fontSizePanel,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.grey400,
            fontSize: AppSpacing.fontSizePanel,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDeviceCounts() {
    final counts = countBy(room.devices, (d) => d.type);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: counts.entries.map((e) {
        return _buildCountChip(e.key.icon, e.value, AppColors.blue700);
      }).toList(),
    );
  }

  Widget _buildCompactServiceCounts() {
    final counts = countBy(room.cloudServices, (s) => s.provider);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: counts.entries.map((e) {
        return _buildCountChip(e.key.icon, e.value, e.key.color);
      }).toList(),
    );
  }

  Widget _buildCountChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.borderWidth,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: AppSpacing.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconSizeXs, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: AppSpacing.fontSizeXs,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCounts() {
    final counts = countBy(room.devices, (d) => d.type);

    return Column(
      children: counts.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.borderWidth),
          child: Row(
            children: [
              Icon(e.key.icon, size: AppSpacing.iconSizeSm, color: AppColors.blue400),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  e.key.displayName,
                  style: const TextStyle(
                    color: AppColors.grey300,
                    fontSize: AppSpacing.fontSizePanel,
                  ),
                ),
              ),
              Text(
                '${e.value}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSpacing.fontSizePanel,
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
    // Group by provider, then count by category
    final byProvider = groupBy(room.cloudServices, (s) => s.provider);
    final categoryCounts = <CloudProvider, Map<ServiceCategory, int>>{};
    for (final entry in byProvider.entries) {
      categoryCounts[entry.key] = countBy(entry.value, (s) => s.category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryCounts.entries.map((providerEntry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider header
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.borderWidth,
              ),
              child: Row(
                children: [
                  Icon(
                    providerEntry.key.icon,
                    size: AppSpacing.iconSizeXs,
                    color: providerEntry.key.color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      providerEntry.key.displayName,
                      style: TextStyle(
                        color: providerEntry.key.color,
                        fontSize: AppSpacing.fontSizeXs,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    Icon(catEntry.key.icon, size: AppSpacing.iconSizeXs, color: AppColors.grey400),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        catEntry.key.displayName,
                        style: const TextStyle(
                          color: AppColors.grey400,
                          fontSize: AppSpacing.fontSizeXs,
                        ),
                      ),
                    ),
                    Text(
                      '${catEntry.value}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppSpacing.fontSizeXs,
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
}
