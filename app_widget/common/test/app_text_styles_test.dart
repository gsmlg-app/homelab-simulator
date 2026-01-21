import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('AppTextStyles', () {
    group('font families', () {
      test('monospaceFontFamily is monospace', () {
        expect(AppTextStyles.monospaceFontFamily, 'monospace');
      });
    });

    group('panelTitle', () {
      test('returns TextStyle with default cyan color', () {
        final style = AppTextStyles.panelTitle();
        expect(style.color, const Color(0xFF26C6DA));
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.letterSpacing, 1);
      });

      test('returns TextStyle with custom color', () {
        const customColor = Color(0xFF00FF00);
        final style = AppTextStyles.panelTitle(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('sectionHeader', () {
      test('returns TextStyle with default grey color', () {
        final style = AppTextStyles.sectionHeader();
        expect(style.color, const Color(0xFFBDBDBD));
        expect(style.fontSize, 11);
        expect(style.fontWeight, FontWeight.w500);
      });

      test('returns TextStyle with custom color', () {
        const customColor = Color(0xFF0000FF);
        final style = AppTextStyles.sectionHeader(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('smallLabel', () {
      test('returns TextStyle with default grey color', () {
        final style = AppTextStyles.smallLabel();
        expect(style.color, const Color(0xFF9E9E9E));
        expect(style.fontSize, 10);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.letterSpacing, 1);
      });

      test('returns TextStyle with custom color', () {
        const customColor = Color(0xFFFF0000);
        final style = AppTextStyles.smallLabel(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('body text styles', () {
      test('bodyPrimary has correct style', () {
        expect(AppTextStyles.bodyPrimary.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.bodyPrimary.fontSize, 14);
      });

      test('bodySecondary has correct style', () {
        expect(AppTextStyles.bodySecondary.color, const Color(0xB3FFFFFF));
        expect(AppTextStyles.bodySecondary.fontSize, 14);
      });

      test('bodySmall has correct style', () {
        expect(AppTextStyles.bodySmall.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.bodySmall.fontSize, 12);
      });

      test('bodySmallSecondary has correct style', () {
        expect(AppTextStyles.bodySmallSecondary.color, const Color(0xB3FFFFFF));
        expect(AppTextStyles.bodySmallSecondary.fontSize, 12);
      });
    });

    group('infoLabel', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.infoLabel();
        expect(style.color, const Color(0xFF9E9E9E));
        expect(style.fontSize, 12);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFFABCDEF);
        final style = AppTextStyles.infoLabel(color: customColor, fontSize: 14);
        expect(style.color, customColor);
        expect(style.fontSize, 14);
      });
    });

    group('infoValue', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.infoValue();
        expect(style.color, const Color(0xFFFFFFFF));
        expect(style.fontSize, 12);
        expect(style.fontWeight, FontWeight.w500);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFF123456);
        final style = AppTextStyles.infoValue(color: customColor, fontSize: 16);
        expect(style.color, customColor);
        expect(style.fontSize, 16);
      });
    });

    group('countText', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.countText();
        expect(style.color, const Color(0xFFFFFFFF));
        expect(style.fontSize, 10);
        expect(style.fontWeight, FontWeight.bold);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFF654321);
        final style = AppTextStyles.countText(color: customColor, fontSize: 12);
        expect(style.color, customColor);
        expect(style.fontSize, 12);
      });
    });

    group('hint and placeholder text', () {
      test('hintText has correct style', () {
        expect(AppTextStyles.hintText.color, const Color(0x66FFFFFF));
        expect(AppTextStyles.hintText.fontSize, 14);
      });

      test('emptyStateText returns correct default style', () {
        final style = AppTextStyles.emptyStateText();
        expect(style.color, const Color(0xFF757575));
        expect(style.fontSize, 11);
        expect(style.fontStyle, FontStyle.italic);
      });

      test('emptyStateText returns style with custom color', () {
        const customColor = Color(0xFFDEADBE);
        final style = AppTextStyles.emptyStateText(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('error and warning text', () {
      test('errorText has correct style', () {
        expect(AppTextStyles.errorText.color, const Color(0xFFFF5252));
        expect(AppTextStyles.errorText.fontSize, 12);
      });

      test('warningText has correct style', () {
        expect(AppTextStyles.warningText.color, const Color(0xFFFFB300));
        expect(AppTextStyles.warningText.fontSize, 12);
      });
    });

    group('button and link text', () {
      test('buttonText has correct style', () {
        expect(AppTextStyles.buttonText.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.buttonText.fontSize, 16);
        expect(AppTextStyles.buttonText.fontWeight, FontWeight.w500);
      });

      test('linkText returns correct default style', () {
        final style = AppTextStyles.linkText();
        expect(style.color, const Color(0xFF9E9E9E));
        expect(style.fontSize, 10);
      });

      test('linkText returns style with custom color', () {
        const customColor = Color(0xFFCAFEBA);
        final style = AppTextStyles.linkText(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('modal styles', () {
      test('modalTitle has correct style', () {
        expect(AppTextStyles.modalTitle.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.modalTitle.fontSize, 18);
        expect(AppTextStyles.modalTitle.fontWeight, FontWeight.bold);
      });

      test('modalSubtitle has correct style', () {
        expect(AppTextStyles.modalSubtitle.color, const Color(0xB3FFFFFF));
        expect(AppTextStyles.modalSubtitle.fontSize, 14);
      });
    });

    group('card styles', () {
      test('cardTitle has correct style', () {
        expect(AppTextStyles.cardTitle.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.cardTitle.fontSize, 16);
        expect(AppTextStyles.cardTitle.letterSpacing, 2);
      });

      test('cardDetail returns correct default style', () {
        final style = AppTextStyles.cardDetail();
        expect(style.color, const Color(0xB3FFFFFF));
        expect(style.fontSize, 12);
      });

      test('cardDetail returns style with custom color', () {
        const customColor = Color(0xFF000000);
        final style = AppTextStyles.cardDetail(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('input styles', () {
      test('inputText has correct style', () {
        expect(AppTextStyles.inputText.color, const Color(0xFFFFFFFF));
        expect(AppTextStyles.inputText.fontSize, 18);
      });

      test('inputLabel has correct style', () {
        expect(AppTextStyles.inputLabel.color, const Color(0xB3FFFFFF));
        expect(AppTextStyles.inputLabel.fontSize, 14);
      });

      test('inputCounter returns normal style when under limit', () {
        final style = AppTextStyles.inputCounter(count: 5, maxLength: 10);
        expect(style.color, const Color(0x8AFFFFFF));
        expect(style.fontSize, 12);
      });

      test('inputCounter returns warning style when over limit', () {
        final style = AppTextStyles.inputCounter(count: 15, maxLength: 10);
        expect(style.color, const Color(0xFFFF5252));
        expect(style.fontSize, 12);
      });

      test('inputCounter returns normal style when at limit', () {
        final style = AppTextStyles.inputCounter(count: 10, maxLength: 10);
        expect(style.color, const Color(0x8AFFFFFF));
      });

      test('inputCounter returns normal style when count is null', () {
        final style = AppTextStyles.inputCounter(count: null, maxLength: 10);
        expect(style.color, const Color(0x8AFFFFFF));
      });

      test('inputCounter returns normal style when maxLength is null', () {
        final style = AppTextStyles.inputCounter(count: 5, maxLength: null);
        expect(style.color, const Color(0x8AFFFFFF));
      });
    });
  });
}
