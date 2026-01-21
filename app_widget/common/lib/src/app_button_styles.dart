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
    backgroundColor: AppColors.cyan600,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Primary button style with custom color
  static ButtonStyle primaryColored(Color backgroundColor) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.textPrimary,
        padding: AppSpacing.paddingButton,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMedium,
        ),
      );

  // ============ SECONDARY BUTTONS ============

  /// Secondary button style (outlined, cyan border)
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: AppColors.cyan400,
    side: const BorderSide(color: AppColors.cyan400),
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Secondary button style with custom color
  static ButtonStyle secondaryColored(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color),
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ DANGER / DESTRUCTIVE BUTTONS ============

  /// Danger button style (red)
  static ButtonStyle get danger => ElevatedButton.styleFrom(
    backgroundColor: AppColors.red700,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Danger outlined button style
  static ButtonStyle get dangerOutlined => OutlinedButton.styleFrom(
    foregroundColor: AppColors.red700,
    side: const BorderSide(color: AppColors.red700),
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ MODAL / DIALOG BUTTONS ============

  /// Modal primary button style (purple accent)
  static ButtonStyle get modalPrimary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.modalAccent,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Modal secondary button style (gray)
  static ButtonStyle get modalSecondary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.grey800,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingButton,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  // ============ ICON BUTTONS ============

  /// Icon button style with circular shape
  static ButtonStyle get iconCircular => IconButton.styleFrom(
    shape: const CircleBorder(),
    padding: AppSpacing.paddingS,
  );

  /// Icon button style with rounded rectangle
  static ButtonStyle get iconRounded => IconButton.styleFrom(
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
    padding: AppSpacing.paddingS,
  );

  // ============ SMALL / COMPACT BUTTONS ============

  /// Small button style
  static ButtonStyle get small => ElevatedButton.styleFrom(
    backgroundColor: AppColors.cyan600,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingChip,
    minimumSize: const Size(
      AppSpacing.buttonMinWidthSmall,
      AppSpacing.buttonMinHeightSmall,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    textStyle: const TextStyle(fontSize: AppSpacing.fontSizeSmall),
  );

  /// Small outlined button style
  static ButtonStyle get smallOutlined => OutlinedButton.styleFrom(
    foregroundColor: AppColors.cyan400,
    side: const BorderSide(color: AppColors.cyan400),
    padding: AppSpacing.paddingChip,
    minimumSize: const Size(
      AppSpacing.buttonMinWidthSmall,
      AppSpacing.buttonMinHeightSmall,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusSm,
    ),
    textStyle: const TextStyle(fontSize: AppSpacing.fontSizeSmall),
  );

  // ============ DISABLED STATE HELPERS ============

  /// Apply disabled style to any button style
  static ButtonStyle disabled(ButtonStyle baseStyle) {
    return baseStyle.copyWith(
      backgroundColor: WidgetStateProperty.all(AppColors.grey700),
      foregroundColor: WidgetStateProperty.all(AppColors.textDisabled),
    );
  }

  // ============ TOGGLE BUTTONS ============

  /// Toggle button style (selected state)
  static ButtonStyle get toggleSelected => ElevatedButton.styleFrom(
    backgroundColor: AppColors.cyan600,
    foregroundColor: AppColors.textPrimary,
    padding: AppSpacing.paddingHudPill,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Toggle button style (unselected state)
  static ButtonStyle get toggleUnselected => ElevatedButton.styleFrom(
    backgroundColor: AppColors.grey300Dark,
    foregroundColor: AppColors.textTertiary,
    padding: AppSpacing.paddingHudPill,
    shape: const RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
    ),
  );

  /// Toggle button style based on selection state
  static ButtonStyle toggle({required bool selected}) =>
      selected ? toggleSelected : toggleUnselected;
}
