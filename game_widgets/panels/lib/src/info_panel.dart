import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';

/// Generic info panel widget
class InfoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const InfoPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingM,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.cyan400,
                size: AppSpacing.iconSizeDefault,
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.cyan400,
                    fontSize: AppSpacing.fontSizeDefault,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}
