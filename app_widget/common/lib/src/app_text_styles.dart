import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/widgets.dart';

/// Centralized text styles for the Homelab Simulator app.
///
/// These styles provide consistent typography across all UI components.
/// Use these instead of inline TextStyle() definitions.
abstract final class AppTextStyles {
  // ============ FONT FAMILIES ============

  /// Monospace font family for numeric displays and code
  static const String monospaceFontFamily = 'monospace';

  // ============ PANEL HEADERS ============

  /// Panel title style (UPPERCASE labels, cyan accent)
  static TextStyle panelTitle({Color? color}) => TextStyle(
    color: color ?? AppColors.cyan400,
    fontSize: AppSpacing.fontSizeDefault,
    fontWeight: FontWeight.bold,
    letterSpacing: AppSpacing.letterSpacingWide,
  );

  /// Section header style (medium weight labels)
  static TextStyle sectionHeader({Color? color}) => TextStyle(
    color: color ?? AppColors.grey400,
    fontSize: AppSpacing.fontSizePanel,
    fontWeight: FontWeight.w500,
  );

  /// Small uppercase label style
  static TextStyle smallLabel({Color? color}) => TextStyle(
    color: color ?? AppColors.grey500,
    fontSize: AppSpacing.fontSizeXs,
    fontWeight: FontWeight.bold,
    letterSpacing: AppSpacing.letterSpacingWide,
  );

  // ============ BODY TEXT ============

  /// Primary body text (white)
  static const TextStyle bodyPrimary = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeDefault,
  );

  /// Secondary body text (white70)
  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: AppSpacing.fontSizeDefault,
  );

  /// Small body text
  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeSmall,
  );

  /// Small secondary body text
  static const TextStyle bodySmallSecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: AppSpacing.fontSizeSmall,
  );

  // ============ INFO ROW / DATA DISPLAY ============

  /// Info row label style
  static TextStyle infoLabel({
    Color? color,
    double fontSize = AppSpacing.fontSizeSmall,
  }) => TextStyle(
    color: color ?? AppColors.grey500,
    fontSize: fontSize,
  );

  /// Info row value style
  static TextStyle infoValue({
    Color? color,
    double fontSize = AppSpacing.fontSizeSmall,
  }) => TextStyle(
    color: color ?? AppColors.textPrimary,
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
  );

  // ============ COUNT / BADGE TEXT ============

  /// Count text style (bold, used in chips and badges)
  static TextStyle countText({
    Color? color,
    double fontSize = AppSpacing.fontSizeXs,
  }) => TextStyle(
    color: color ?? AppColors.textPrimary,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
  );

  // ============ HINT / PLACEHOLDER TEXT ============

  /// Hint text style (semi-transparent white)
  static const TextStyle hintText = TextStyle(
    color: AppColors.textHint,
    fontSize: AppSpacing.fontSizeDefault,
  );

  /// Empty state / placeholder text
  static TextStyle emptyStateText({Color? color}) => TextStyle(
    color: color ?? AppColors.grey600,
    fontSize: AppSpacing.fontSizePanel,
    fontStyle: FontStyle.italic,
  );

  // ============ ERROR / WARNING TEXT ============

  /// Error text style (red)
  static const TextStyle errorText = TextStyle(
    color: AppColors.redAccent,
    fontSize: AppSpacing.fontSizeSmall,
  );

  /// Warning text style (amber)
  static const TextStyle warningText = TextStyle(
    color: AppColors.amber600,
    fontSize: AppSpacing.fontSizeSmall,
  );

  // ============ BUTTON / LINK TEXT ============

  /// Button text style (white, 16px)
  static const TextStyle buttonText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeMedium,
    fontWeight: FontWeight.w500,
  );

  /// Small link text style
  static TextStyle linkText({Color? color}) => TextStyle(
    color: color ?? AppColors.grey500,
    fontSize: AppSpacing.fontSizeXs,
  );

  // ============ MODAL / DIALOG STYLES ============

  /// Modal title style (white, 18px)
  static const TextStyle modalTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeLarge,
    fontWeight: FontWeight.bold,
  );

  /// Modal subtitle style (white70, 14px)
  static const TextStyle modalSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: AppSpacing.fontSizeDefault,
  );

  // ============ CHARACTER CARD / MENU STYLES ============

  /// Character card title style (white with letter spacing)
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeMedium,
    letterSpacing: AppSpacing.letterSpacingExtraWide,
  );

  /// Character card detail text style
  static TextStyle cardDetail({Color? color}) => TextStyle(
    color: color ?? AppColors.textSecondary,
    fontSize: AppSpacing.fontSizeSmall,
  );

  // ============ INPUT FIELD STYLES ============

  /// Text input style (white, 18px)
  static const TextStyle inputText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: AppSpacing.fontSizeLarge,
  );

  /// Input counter style (white54)
  static TextStyle inputCounter({int? count, int? maxLength}) {
    final isWarning = count != null && maxLength != null && count > maxLength;
    return TextStyle(
      color: isWarning ? AppColors.redAccent : AppColors.textTertiary,
      fontSize: AppSpacing.fontSizeSmall,
    );
  }

  /// Input label style (white70)
  static const TextStyle inputLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: AppSpacing.fontSizeDefault,
  );
}
