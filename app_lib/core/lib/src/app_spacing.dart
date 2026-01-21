import 'package:flutter/widgets.dart';

/// Centralized spacing and sizing constants for the Homelab Simulator app.
///
/// These constants provide consistent spacing across all UI components.
/// Use these instead of inline numeric values for margins, padding, and sizes.
abstract final class AppSpacing {
  // ============ SPACING VALUES ============
  // Base spacing scale (multiples of 4px)

  /// 4px - Extra small spacing
  static const double xs = 4.0;

  /// 6px - Small-medium spacing
  static const double sm = 6.0;

  /// 8px - Small spacing
  static const double s = 8.0;

  /// 12px - Medium-small spacing
  static const double ms = 12.0;

  /// 16px - Medium spacing
  static const double m = 16.0;

  /// 20px - Medium-large spacing
  static const double ml = 20.0;

  /// 24px - Large spacing
  static const double l = 24.0;

  /// 32px - Extra large spacing
  static const double xl = 32.0;

  /// 40px - XXL spacing (for step lines, wide gaps)
  static const double xxl = 40.0;

  // ============ COMMON EDGE INSETS ============

  /// EdgeInsets.all(4)
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);

  /// EdgeInsets.all(8)
  static const EdgeInsets paddingS = EdgeInsets.all(s);

  /// EdgeInsets.all(12)
  static const EdgeInsets paddingMs = EdgeInsets.all(ms);

  /// EdgeInsets.all(16)
  static const EdgeInsets paddingM = EdgeInsets.all(m);

  /// EdgeInsets.all(24)
  static const EdgeInsets paddingL = EdgeInsets.all(l);

  /// EdgeInsets.all(32)
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // ============ HORIZONTAL PADDING ============

  /// EdgeInsets.symmetric(horizontal: 12, vertical: 6)
  static const EdgeInsets paddingChip = EdgeInsets.symmetric(
    horizontal: ms,
    vertical: sm,
  );

  /// EdgeInsets.symmetric(horizontal: 24, vertical: 12)
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: l,
    vertical: ms,
  );

  /// EdgeInsets.symmetric(horizontal: 32, vertical: 12)
  static const EdgeInsets paddingButtonLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: ms,
  );

  /// EdgeInsets.symmetric(horizontal: 24, vertical: 16)
  static const EdgeInsets paddingStepIndicator = EdgeInsets.symmetric(
    horizontal: l,
    vertical: m,
  );

  /// EdgeInsets.symmetric(horizontal: 16, vertical: 8) - common HUD/pill padding
  static const EdgeInsets paddingHudPill = EdgeInsets.symmetric(
    horizontal: m,
    vertical: s,
  );

  // ============ WIDGET SIZES ============

  /// Step indicator dot size (32x32)
  static const double stepDotSize = 32.0;

  /// Step line width (40px)
  static const double stepLineWidth = 40.0;

  /// Step line height (2px)
  static const double stepLineHeight = 2.0;

  /// Character preview width (192px)
  static const double characterPreviewWidth = 192.0;

  /// Character preview height (256px)
  static const double characterPreviewHeight = 256.0;

  /// Character summary preview width (120px)
  static const double characterSummaryWidth = 120.0;

  /// Character summary preview height (160px)
  static const double characterSummaryHeight = 160.0;

  /// Summary label width (100px)
  static const double summaryLabelWidth = 100.0;

  /// SizedBox placeholder width (100px)
  static const double placeholderWidth = 100.0;

  /// Room summary panel width (200px)
  static const double roomSummaryWidth = 200.0;

  /// Shop modal width (500px)
  static const double shopModalWidth = 500.0;

  /// Shop modal max height ratio (0.8 of screen height)
  static const double shopModalMaxHeightRatio = 0.8;

  // ============ ICON SIZES ============

  /// Extra small icon size (12px) - for compact badges/counts
  static const double iconSizeXs = 12.0;

  /// Small-compact icon size (14px) - for dense list items
  static const double iconSizeSm = 14.0;

  /// Small icon size (16px)
  static const double iconSizeSmall = 16.0;

  /// Compact icon size (18px) - for slightly larger list items
  static const double iconSizeCompact = 18.0;

  /// Default icon size (20px)
  static const double iconSizeDefault = 20.0;

  /// Medium icon size (24px)
  static const double iconSizeMedium = 24.0;

  /// Large icon size (28px)
  static const double iconSizeLarge = 28.0;

  /// XL icon size (32px) - for feature cards
  static const double iconSizeXl = 32.0;

  /// Error icon size (48px)
  static const double errorIconSize = 48.0;

  /// Hero icon size (64px) - for large error/empty states
  static const double iconSizeHero = 64.0;

  // ============ BORDER RADIUS VALUES ============

  /// Small border radius (4px)
  static const double radiusSmall = 4.0;

  /// Medium border radius (8px)
  static const double radiusMedium = 8.0;

  /// Large border radius (12px)
  static const double radiusLarge = 12.0;

  /// Extra large border radius (16px)
  static const double radiusXl = 16.0;

  // ============ BORDER RADIUS PRESETS ============

  /// BorderRadius.circular(4) - small elements like tags, chips
  static const BorderRadius borderRadiusSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );

  /// BorderRadius.circular(6) - small buttons
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(6.0),
  );

  /// BorderRadius.circular(8) - medium elements like cards, buttons
  static const BorderRadius borderRadiusMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );

  /// BorderRadius.circular(12) - large elements
  static const BorderRadius borderRadiusLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );

  /// BorderRadius.circular(16) - extra large elements like modals
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  // ============ BORDER WIDTHS ============

  /// Default border width (2px)
  static const double borderWidth = 2.0;

  // ============ FONT SIZES ============

  /// Extra small font size (10px) - for captions and fine print
  static const double fontSizeXs = 10.0;

  /// Panel font size (11px) - for dense panel text and labels
  static const double fontSizePanel = 11.0;

  /// Small font size (12px)
  static const double fontSizeSmall = 12.0;

  /// Default font size (14px)
  static const double fontSizeDefault = 14.0;

  /// Medium font size (16px)
  static const double fontSizeMedium = 16.0;

  /// Large font size (18px)
  static const double fontSizeLarge = 18.0;

  /// Extra large font size (20px)
  static const double fontSizeXl = 20.0;

  /// Heading font size (24px)
  static const double fontSizeHeading = 24.0;

  /// Title font size (28px)
  static const double fontSizeTitle = 28.0;

  // ============ ANIMATION DURATIONS ============

  /// Fast animation duration (200ms)
  static const Duration animationFast = Duration(milliseconds: 200);

  // ============ POSITIONED OFFSETS ============

  /// Top bar offset from top (16px)
  static const double topBarOffset = 16.0;

  /// Room summary offset from top (56px)
  static const double roomSummaryOffset = 56.0;

  /// Bottom hint offset from bottom (100px)
  static const double bottomHintOffset = 100.0;
}
