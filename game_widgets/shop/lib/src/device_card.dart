import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';

/// Card displaying a device template in the shop
class DeviceCard extends StatelessWidget {
  final DeviceTemplate template;
  final int currentCredits;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.template,
    required this.currentCredits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = currentCredits >= template.cost;
    final deviceColor = template.type.color;
    final deviceIcon = template.type.icon;

    return Card(
      color: AppColors.grey900,
      child: InkWell(
        onTap: canAfford ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: canAfford ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: deviceColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(deviceIcon, color: deviceColor, size: 32),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            template.type.name.toUpperCase(),
                            style: TextStyle(
                              color: deviceColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppColors.green800
                            : AppColors.red800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\$${template.cost}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: const TextStyle(
                    color: AppColors.grey400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
