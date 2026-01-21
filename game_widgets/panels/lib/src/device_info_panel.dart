import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';

import 'info_panel.dart';

/// Panel showing selected device info
class DeviceInfoPanel extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onRemove;

  const DeviceInfoPanel({super.key, required this.device, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InfoPanel(
      title: 'Device Info',
      icon: device.type.icon,
      children: [
        InfoRow(label: 'Name', value: device.name),
        InfoRow(label: 'Type', value: device.type.name),
        InfoRow(
          label: 'Position',
          value: '(${device.position.x}, ${device.position.y})',
        ),
        InfoRow(
          label: 'Status',
          value: device.isRunning ? 'Running' : 'Stopped',
        ),
        if (onRemove != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red800,
              ),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Remove Device'),
            ),
          ),
        ],
      ],
    );
  }
}
