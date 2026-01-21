import 'package:flutter/material.dart';

/// A reusable row widget for displaying label-value pairs.
///
/// Commonly used in info panels and summary displays.
/// The label is left-aligned with a muted color, and the value
/// is right-aligned with configurable styling.
class InfoRow extends StatelessWidget {
  /// The label text (left side)
  final String label;

  /// The value text (right side)
  final String value;

  /// Color for the value text. Defaults to white.
  final Color valueColor;

  /// Color for the label text. Defaults to grey.shade400.
  final Color? labelColor;

  /// Font size for both label and value. Defaults to 12.
  final double fontSize;

  /// Vertical padding around the row. Defaults to 4.
  final double verticalPadding;

  /// Whether the value should be bold. Defaults to true.
  final bool boldValue;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.labelColor,
    this.fontSize = 12,
    this.verticalPadding = 4,
    this.boldValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? Colors.grey.shade400,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: fontSize,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
