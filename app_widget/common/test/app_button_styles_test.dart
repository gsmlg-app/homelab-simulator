import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('AppButtonStyles', () {
    group('primary', () {
      test('returns ButtonStyle with cyan background', () {
        final style = AppButtonStyles.primary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.cyan600);
      });

      test('returns ButtonStyle with white foreground', () {
        final style = AppButtonStyles.primary;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.textPrimary);
      });
    });

    group('primaryColored', () {
      test('returns ButtonStyle with custom background color', () {
        const customColor = Color(0xFF00FF00);
        final style = AppButtonStyles.primaryColored(customColor);
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, customColor);
      });

      test('returns ButtonStyle with white foreground', () {
        const customColor = Color(0xFF00FF00);
        final style = AppButtonStyles.primaryColored(customColor);
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.textPrimary);
      });
    });

    group('secondary', () {
      test('returns ButtonStyle with cyan foreground', () {
        final style = AppButtonStyles.secondary;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.cyan400);
      });

      test('returns ButtonStyle with cyan border', () {
        final style = AppButtonStyles.secondary;
        final side = style.side?.resolve({});
        expect(side?.color, AppColors.cyan400);
      });
    });

    group('secondaryColored', () {
      test(
        'returns ButtonStyle with custom color for foreground and border',
        () {
          const customColor = Color(0xFF0000FF);
          final style = AppButtonStyles.secondaryColored(customColor);
          final fgColor = style.foregroundColor?.resolve({});
          final side = style.side?.resolve({});
          expect(fgColor, customColor);
          expect(side?.color, customColor);
        },
      );
    });

    group('danger', () {
      test('returns ButtonStyle with red background', () {
        final style = AppButtonStyles.danger;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.red700);
      });

      test('returns ButtonStyle with white foreground', () {
        final style = AppButtonStyles.danger;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.textPrimary);
      });
    });

    group('dangerOutlined', () {
      test('returns ButtonStyle with red foreground', () {
        final style = AppButtonStyles.dangerOutlined;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.red700);
      });

      test('returns ButtonStyle with red border', () {
        final style = AppButtonStyles.dangerOutlined;
        final side = style.side?.resolve({});
        expect(side?.color, AppColors.red700);
      });
    });

    group('modalPrimary', () {
      test('returns ButtonStyle with purple background', () {
        final style = AppButtonStyles.modalPrimary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.modalAccent);
      });
    });

    group('modalSecondary', () {
      test('returns ButtonStyle with gray background', () {
        final style = AppButtonStyles.modalSecondary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.grey800);
      });
    });

    group('iconCircular', () {
      test('returns ButtonStyle with CircleBorder shape', () {
        final style = AppButtonStyles.iconCircular;
        final shape = style.shape?.resolve({});
        expect(shape, isA<CircleBorder>());
      });
    });

    group('iconRounded', () {
      test('returns ButtonStyle with RoundedRectangleBorder shape', () {
        final style = AppButtonStyles.iconRounded;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
      });
    });

    group('small', () {
      test('returns ButtonStyle with cyan background', () {
        final style = AppButtonStyles.small;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.cyan600);
      });

      test('returns ButtonStyle with smaller minimumSize', () {
        final style = AppButtonStyles.small;
        final minSize = style.minimumSize?.resolve({});
        expect(
          minSize,
          const Size(
            AppSpacing.buttonMinWidthSmall,
            AppSpacing.buttonMinHeightSmall,
          ),
        );
      });
    });

    group('smallOutlined', () {
      test('returns ButtonStyle with cyan foreground', () {
        final style = AppButtonStyles.smallOutlined;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.cyan400);
      });

      test('returns ButtonStyle with smaller minimumSize', () {
        final style = AppButtonStyles.smallOutlined;
        final minSize = style.minimumSize?.resolve({});
        expect(
          minSize,
          const Size(
            AppSpacing.buttonMinWidthSmall,
            AppSpacing.buttonMinHeightSmall,
          ),
        );
      });
    });

    group('disabled', () {
      test('applies gray background to any style', () {
        final baseStyle = AppButtonStyles.primary;
        final disabledStyle = AppButtonStyles.disabled(baseStyle);
        final bgColor = disabledStyle.backgroundColor?.resolve({});
        expect(bgColor, AppColors.grey700);
      });

      test('applies semi-transparent foreground to any style', () {
        final baseStyle = AppButtonStyles.primary;
        final disabledStyle = AppButtonStyles.disabled(baseStyle);
        final fgColor = disabledStyle.foregroundColor?.resolve({});
        expect(fgColor, AppColors.textDisabled);
      });
    });

    group('toggleSelected', () {
      test('returns ButtonStyle with cyan background', () {
        final style = AppButtonStyles.toggleSelected;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.cyan600);
      });
    });

    group('toggleUnselected', () {
      test('returns ButtonStyle with dark gray background', () {
        final style = AppButtonStyles.toggleUnselected;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.grey300Dark);
      });

      test('returns ButtonStyle with semi-transparent foreground', () {
        final style = AppButtonStyles.toggleUnselected;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, AppColors.textTertiary);
      });
    });

    group('toggle', () {
      test('returns toggleSelected when selected is true', () {
        final style = AppButtonStyles.toggle(selected: true);
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.cyan600);
      });

      test('returns toggleUnselected when selected is false', () {
        final style = AppButtonStyles.toggle(selected: false);
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, AppColors.grey300Dark);
      });
    });

    group('shape consistency', () {
      test('primary has rounded rectangle border with radius 8', () {
        final style = AppButtonStyles.primary;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, AppSpacing.borderRadiusMedium);
        }
      });

      test('secondary has rounded rectangle border with radius 8', () {
        final style = AppButtonStyles.secondary;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, AppSpacing.borderRadiusMedium);
        }
      });

      test('small has rounded rectangle border with radius 6', () {
        final style = AppButtonStyles.small;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, AppSpacing.borderRadiusSm);
        }
      });
    });

    group('padding consistency', () {
      test('primary has standard padding', () {
        final style = AppButtonStyles.primary;
        final padding = style.padding?.resolve({});
        expect(padding, AppSpacing.paddingButton);
      });

      test('small has smaller padding', () {
        final style = AppButtonStyles.small;
        final padding = style.padding?.resolve({});
        expect(padding, AppSpacing.paddingChip);
      });
    });
  });
}
