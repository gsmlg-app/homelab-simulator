import 'package:flutter/widgets.dart';

/// Centralized text styles for the Homelab Simulator app.
///
/// These styles provide consistent typography across all UI components.
/// Use these instead of inline TextStyle() definitions.
abstract final class AppTextStyles {
  // ============ PANEL HEADERS ============

  /// Panel title style (UPPERCASE labels, cyan accent)
  static TextStyle panelTitle({Color? color}) => TextStyle(
        color: color ?? const Color(0xFF26C6DA), // cyan.shade400
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      );

  /// Section header style (medium weight labels)
  static TextStyle sectionHeader({Color? color}) => TextStyle(
        color: color ?? const Color(0xFFBDBDBD), // grey.shade400
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  /// Small uppercase label style
  static TextStyle smallLabel({Color? color}) => TextStyle(
        color: color ?? const Color(0xFF9E9E9E), // grey.shade500
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      );

  // ============ BODY TEXT ============

  /// Primary body text (white)
  static const TextStyle bodyPrimary = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 14,
  );

  /// Secondary body text (white70)
  static const TextStyle bodySecondary = TextStyle(
    color: Color(0xB3FFFFFF), // white with 70% opacity
    fontSize: 14,
  );

  /// Small body text
  static const TextStyle bodySmall = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 12,
  );

  /// Small secondary body text
  static const TextStyle bodySmallSecondary = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 12,
  );

  // ============ INFO ROW / DATA DISPLAY ============

  /// Info row label style
  static TextStyle infoLabel({Color? color, double fontSize = 12}) => TextStyle(
        color: color ?? const Color(0xFF9E9E9E), // grey.shade500
        fontSize: fontSize,
      );

  /// Info row value style
  static TextStyle infoValue({Color? color, double fontSize = 12}) => TextStyle(
        color: color ?? const Color(0xFFFFFFFF),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      );

  // ============ COUNT / BADGE TEXT ============

  /// Count text style (bold, used in chips and badges)
  static TextStyle countText({Color? color, double fontSize = 10}) => TextStyle(
        color: color ?? const Color(0xFFFFFFFF),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      );

  // ============ HINT / PLACEHOLDER TEXT ============

  /// Hint text style (semi-transparent white)
  static const TextStyle hintText = TextStyle(
    color: Color(0x66FFFFFF), // white with 40% opacity
    fontSize: 14,
  );

  /// Empty state / placeholder text
  static TextStyle emptyStateText({Color? color}) => TextStyle(
        color: color ?? const Color(0xFF757575), // grey.shade600
        fontSize: 11,
        fontStyle: FontStyle.italic,
      );

  // ============ ERROR / WARNING TEXT ============

  /// Error text style (red)
  static const TextStyle errorText = TextStyle(
    color: Color(0xFFFF5252), // redAccent
    fontSize: 12,
  );

  /// Warning text style (amber)
  static const TextStyle warningText = TextStyle(
    color: Color(0xFFFFB300), // amber.shade600
    fontSize: 12,
  );

  // ============ BUTTON / LINK TEXT ============

  /// Button text style (white, 16px)
  static const TextStyle buttonText = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Small link text style
  static TextStyle linkText({Color? color}) => TextStyle(
        color: color ?? const Color(0xFF9E9E9E), // grey.shade500
        fontSize: 10,
      );

  // ============ MODAL / DIALOG STYLES ============

  /// Modal title style (white, 18px)
  static const TextStyle modalTitle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// Modal subtitle style (white70, 14px)
  static const TextStyle modalSubtitle = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 14,
  );

  // ============ CHARACTER CARD / MENU STYLES ============

  /// Character card title style (white with letter spacing)
  static const TextStyle cardTitle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    letterSpacing: 2,
  );

  /// Character card detail text style
  static TextStyle cardDetail({Color? color}) => TextStyle(
        color: color ?? const Color(0xB3FFFFFF),
        fontSize: 12,
      );

  // ============ INPUT FIELD STYLES ============

  /// Text input style (white, 18px)
  static const TextStyle inputText = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 18,
  );

  /// Input counter style (white54)
  static TextStyle inputCounter({int? count, int? maxLength}) {
    final isWarning = count != null && maxLength != null && count > maxLength;
    return TextStyle(
      color: isWarning ? const Color(0xFFFF5252) : const Color(0x8AFFFFFF),
      fontSize: 12,
    );
  }

  /// Input label style (white70)
  static const TextStyle inputLabel = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 14,
  );
}
