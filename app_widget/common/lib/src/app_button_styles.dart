import 'package:flutter/material.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Centralized button styles for the Homelab Simulator app.
///
/// These styles provide consistent button appearance across all UI components.
/// Use these instead of inline ButtonStyle definitions.
abstract final class AppButtonStyles {
  // ============ PRIMARY BUTTONS ============

  /// Primary button style (cyan accent)
  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00ACC1), // cyan.shade600
    foregroundColor: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Primary button style with custom color
  static ButtonStyle primaryColored(Color backgroundColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMedium,
        ),
      );

  // ============ SECONDARY BUTTONS ============

  /// Secondary button style (outlined, cyan border)
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF26C6DA), // cyan.shade400
    side: const BorderSide(color: Color(0xFF26C6DA)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Secondary button style with custom color
  static ButtonStyle secondaryColored(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ DANGER / DESTRUCTIVE BUTTONS ============

  /// Danger button style (red)
  static ButtonStyle get danger => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFD32F2F), // red.shade700
    foregroundColor: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Danger outlined button style
  static ButtonStyle get dangerOutlined => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFD32F2F),
    side: const BorderSide(color: Color(0xFFD32F2F)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ MODAL / DIALOG BUTTONS ============

  /// Modal primary button style (purple accent)
  static ButtonStyle get modalPrimary => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF9C27B0), // purple
    foregroundColor: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Modal secondary button style (gray)
  static ButtonStyle get modalSecondary => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF424242), // grey.shade800
    foregroundColor: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ ICON BUTTONS ============

  /// Icon button style with circular shape
  static ButtonStyle get iconCircular => IconButton.styleFrom(
    shape: const CircleBorder(),
    padding: const EdgeInsets.all(8),
  );

  /// Icon button style with rounded rectangle
  static ButtonStyle get iconRounded => IconButton.styleFrom(
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
    padding: const EdgeInsets.all(8),
  );

  // ============ SMALL / COMPACT BUTTONS ============

  /// Small button style
  static ButtonStyle get small => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00ACC1),
    foregroundColor: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minimumSize: const Size(60, 32),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    textStyle: const TextStyle(fontSize: 12),
  );

  /// Small outlined button style
  static ButtonStyle get smallOutlined => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF26C6DA),
    side: const BorderSide(color: Color(0xFF26C6DA)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minimumSize: const Size(60, 32),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    textStyle: const TextStyle(fontSize: 12),
  );

  // ============ DISABLED STATE HELPERS ============

  /// Apply disabled style to any button style
  static ButtonStyle disabled(ButtonStyle baseStyle) {
    return baseStyle.copyWith(
      backgroundColor: WidgetStateProperty.all(const Color(0xFF616161)),
      foregroundColor: WidgetStateProperty.all(const Color(0x61FFFFFF)),
    );
  }

  // ============ TOGGLE BUTTONS ============

  /// Toggle button style (selected state)
  static ButtonStyle get toggleSelected => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00ACC1),
    foregroundColor: const Color(0xFFFFFFFF),
    padding: AppSpacing.paddingHudPill,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Toggle button style (unselected state)
  static ButtonStyle get toggleUnselected => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF303030),
    foregroundColor: const Color(0x8AFFFFFF),
    padding: AppSpacing.paddingHudPill,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Toggle button style based on selection state
  static ButtonStyle toggle({required bool selected}) =>
      selected ? toggleSelected : toggleUnselected;
}
