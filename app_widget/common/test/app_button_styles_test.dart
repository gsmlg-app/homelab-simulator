import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('AppButtonStyles', () {
    group('primary', () {
      test('returns ButtonStyle with cyan background', () {
        final style = AppButtonStyles.primary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF00ACC1));
      });

      test('returns ButtonStyle with white foreground', () {
        final style = AppButtonStyles.primary;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0xFFFFFFFF));
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
        expect(fgColor, const Color(0xFFFFFFFF));
      });
    });

    group('secondary', () {
      test('returns ButtonStyle with cyan foreground', () {
        final style = AppButtonStyles.secondary;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0xFF26C6DA));
      });

      test('returns ButtonStyle with cyan border', () {
        final style = AppButtonStyles.secondary;
        final side = style.side?.resolve({});
        expect(side?.color, const Color(0xFF26C6DA));
      });
    });

    group('secondaryColored', () {
      test('returns ButtonStyle with custom color for foreground and border',
          () {
        const customColor = Color(0xFF0000FF);
        final style = AppButtonStyles.secondaryColored(customColor);
        final fgColor = style.foregroundColor?.resolve({});
        final side = style.side?.resolve({});
        expect(fgColor, customColor);
        expect(side?.color, customColor);
      });
    });

    group('danger', () {
      test('returns ButtonStyle with red background', () {
        final style = AppButtonStyles.danger;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFFD32F2F));
      });

      test('returns ButtonStyle with white foreground', () {
        final style = AppButtonStyles.danger;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0xFFFFFFFF));
      });
    });

    group('dangerOutlined', () {
      test('returns ButtonStyle with red foreground', () {
        final style = AppButtonStyles.dangerOutlined;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0xFFD32F2F));
      });

      test('returns ButtonStyle with red border', () {
        final style = AppButtonStyles.dangerOutlined;
        final side = style.side?.resolve({});
        expect(side?.color, const Color(0xFFD32F2F));
      });
    });

    group('modalPrimary', () {
      test('returns ButtonStyle with purple background', () {
        final style = AppButtonStyles.modalPrimary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF9C27B0));
      });
    });

    group('modalSecondary', () {
      test('returns ButtonStyle with gray background', () {
        final style = AppButtonStyles.modalSecondary;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF424242));
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
        expect(bgColor, const Color(0xFF00ACC1));
      });

      test('returns ButtonStyle with smaller minimumSize', () {
        final style = AppButtonStyles.small;
        final minSize = style.minimumSize?.resolve({});
        expect(minSize, const Size(60, 32));
      });
    });

    group('smallOutlined', () {
      test('returns ButtonStyle with cyan foreground', () {
        final style = AppButtonStyles.smallOutlined;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0xFF26C6DA));
      });

      test('returns ButtonStyle with smaller minimumSize', () {
        final style = AppButtonStyles.smallOutlined;
        final minSize = style.minimumSize?.resolve({});
        expect(minSize, const Size(60, 32));
      });
    });

    group('disabled', () {
      test('applies gray background to any style', () {
        final baseStyle = AppButtonStyles.primary;
        final disabledStyle = AppButtonStyles.disabled(baseStyle);
        final bgColor = disabledStyle.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF616161));
      });

      test('applies semi-transparent foreground to any style', () {
        final baseStyle = AppButtonStyles.primary;
        final disabledStyle = AppButtonStyles.disabled(baseStyle);
        final fgColor = disabledStyle.foregroundColor?.resolve({});
        expect(fgColor, const Color(0x61FFFFFF));
      });
    });

    group('toggleSelected', () {
      test('returns ButtonStyle with cyan background', () {
        final style = AppButtonStyles.toggleSelected;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF00ACC1));
      });
    });

    group('toggleUnselected', () {
      test('returns ButtonStyle with dark gray background', () {
        final style = AppButtonStyles.toggleUnselected;
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF303030));
      });

      test('returns ButtonStyle with semi-transparent foreground', () {
        final style = AppButtonStyles.toggleUnselected;
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, const Color(0x8AFFFFFF));
      });
    });

    group('toggle', () {
      test('returns toggleSelected when selected is true', () {
        final style = AppButtonStyles.toggle(selected: true);
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF00ACC1));
      });

      test('returns toggleUnselected when selected is false', () {
        final style = AppButtonStyles.toggle(selected: false);
        final bgColor = style.backgroundColor?.resolve({});
        expect(bgColor, const Color(0xFF303030));
      });
    });

    group('shape consistency', () {
      test('primary has rounded rectangle border with radius 8', () {
        final style = AppButtonStyles.primary;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, BorderRadius.circular(8));
        }
      });

      test('secondary has rounded rectangle border with radius 8', () {
        final style = AppButtonStyles.secondary;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, BorderRadius.circular(8));
        }
      });

      test('small has rounded rectangle border with radius 6', () {
        final style = AppButtonStyles.small;
        final shape = style.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        if (shape is RoundedRectangleBorder) {
          expect(shape.borderRadius, BorderRadius.circular(6));
        }
      });
    });

    group('padding consistency', () {
      test('primary has standard padding', () {
        final style = AppButtonStyles.primary;
        final padding = style.padding?.resolve({});
        expect(
          padding,
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        );
      });

      test('small has smaller padding', () {
        final style = AppButtonStyles.small;
        final padding = style.padding?.resolve({});
        expect(
          padding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        );
      });
    });
  });
}
