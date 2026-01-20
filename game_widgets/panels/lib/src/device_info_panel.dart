import 'package:flutter/material.dart';
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
        _buildRow('Name', device.name),
        _buildRow('Type', device.type.name),
        _buildRow('Position', '(${device.position.x}, ${device.position.y})'),
        _buildRow('Status', device.isRunning ? 'Running' : 'Stopped'),
        if (onRemove != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Remove Device'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
