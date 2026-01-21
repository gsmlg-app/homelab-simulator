import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
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
        expect(style.color, AppColors.cyan400);
        expect(style.fontSize, AppSpacing.fontSizeDefault);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.letterSpacing, AppSpacing.letterSpacingWide);
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
        expect(style.color, AppColors.grey400);
        expect(style.fontSize, AppSpacing.fontSizePanel);
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
        expect(style.color, AppColors.grey500);
        expect(style.fontSize, AppSpacing.fontSizeXs);
        expect(style.fontWeight, FontWeight.bold);
        expect(style.letterSpacing, AppSpacing.letterSpacingWide);
      });

      test('returns TextStyle with custom color', () {
        const customColor = Color(0xFFFF0000);
        final style = AppTextStyles.smallLabel(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('body text styles', () {
      test('bodyPrimary has correct style', () {
        expect(AppTextStyles.bodyPrimary.color, AppColors.textPrimary);
        expect(AppTextStyles.bodyPrimary.fontSize, AppSpacing.fontSizeDefault);
      });

      test('bodySecondary has correct style', () {
        expect(AppTextStyles.bodySecondary.color, AppColors.textSecondary);
        expect(AppTextStyles.bodySecondary.fontSize, AppSpacing.fontSizeDefault);
      });

      test('bodySmall has correct style', () {
        expect(AppTextStyles.bodySmall.color, AppColors.textPrimary);
        expect(AppTextStyles.bodySmall.fontSize, AppSpacing.fontSizeSmall);
      });

      test('bodySmallSecondary has correct style', () {
        expect(AppTextStyles.bodySmallSecondary.color, AppColors.textSecondary);
        expect(AppTextStyles.bodySmallSecondary.fontSize, AppSpacing.fontSizeSmall);
      });
    });

    group('infoLabel', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.infoLabel();
        expect(style.color, AppColors.grey500);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFFABCDEF);
        final style = AppTextStyles.infoLabel(
          color: customColor,
          fontSize: AppSpacing.fontSizeDefault,
        );
        expect(style.color, customColor);
        expect(style.fontSize, AppSpacing.fontSizeDefault);
      });
    });

    group('infoValue', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.infoValue();
        expect(style.color, AppColors.textPrimary);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
        expect(style.fontWeight, FontWeight.w500);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFF123456);
        final style = AppTextStyles.infoValue(
          color: customColor,
          fontSize: AppSpacing.fontSizeMedium,
        );
        expect(style.color, customColor);
        expect(style.fontSize, AppSpacing.fontSizeMedium);
      });
    });

    group('countText', () {
      test('returns TextStyle with default values', () {
        final style = AppTextStyles.countText();
        expect(style.color, AppColors.textPrimary);
        expect(style.fontSize, AppSpacing.fontSizeXs);
        expect(style.fontWeight, FontWeight.bold);
      });

      test('returns TextStyle with custom color and fontSize', () {
        const customColor = Color(0xFF654321);
        final style = AppTextStyles.countText(
          color: customColor,
          fontSize: AppSpacing.fontSizeSmall,
        );
        expect(style.color, customColor);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
      });
    });

    group('hint and placeholder text', () {
      test('hintText has correct style', () {
        expect(AppTextStyles.hintText.color, AppColors.textHint);
        expect(AppTextStyles.hintText.fontSize, AppSpacing.fontSizeDefault);
      });

      test('emptyStateText returns correct default style', () {
        final style = AppTextStyles.emptyStateText();
        expect(style.color, AppColors.grey600);
        expect(style.fontSize, AppSpacing.fontSizePanel);
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
        expect(AppTextStyles.errorText.color, AppColors.redAccent);
        expect(AppTextStyles.errorText.fontSize, AppSpacing.fontSizeSmall);
      });

      test('warningText has correct style', () {
        expect(AppTextStyles.warningText.color, AppColors.amber600);
        expect(AppTextStyles.warningText.fontSize, AppSpacing.fontSizeSmall);
      });
    });

    group('button and link text', () {
      test('buttonText has correct style', () {
        expect(AppTextStyles.buttonText.color, AppColors.textPrimary);
        expect(AppTextStyles.buttonText.fontSize, AppSpacing.fontSizeMedium);
        expect(AppTextStyles.buttonText.fontWeight, FontWeight.w500);
      });

      test('linkText returns correct default style', () {
        final style = AppTextStyles.linkText();
        expect(style.color, AppColors.grey500);
        expect(style.fontSize, AppSpacing.fontSizeXs);
      });

      test('linkText returns style with custom color', () {
        const customColor = Color(0xFFCAFEBA);
        final style = AppTextStyles.linkText(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('modal styles', () {
      test('modalTitle has correct style', () {
        expect(AppTextStyles.modalTitle.color, AppColors.textPrimary);
        expect(AppTextStyles.modalTitle.fontSize, AppSpacing.fontSizeLarge);
        expect(AppTextStyles.modalTitle.fontWeight, FontWeight.bold);
      });

      test('modalSubtitle has correct style', () {
        expect(AppTextStyles.modalSubtitle.color, AppColors.textSecondary);
        expect(AppTextStyles.modalSubtitle.fontSize, AppSpacing.fontSizeDefault);
      });
    });

    group('card styles', () {
      test('cardTitle has correct style', () {
        expect(AppTextStyles.cardTitle.color, AppColors.textPrimary);
        expect(AppTextStyles.cardTitle.fontSize, AppSpacing.fontSizeMedium);
        expect(AppTextStyles.cardTitle.letterSpacing, AppSpacing.letterSpacingExtraWide);
      });

      test('cardDetail returns correct default style', () {
        final style = AppTextStyles.cardDetail();
        expect(style.color, AppColors.textSecondary);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
      });

      test('cardDetail returns style with custom color', () {
        const customColor = Color(0xFF000000);
        final style = AppTextStyles.cardDetail(color: customColor);
        expect(style.color, customColor);
      });
    });

    group('input styles', () {
      test('inputText has correct style', () {
        expect(AppTextStyles.inputText.color, AppColors.textPrimary);
        expect(AppTextStyles.inputText.fontSize, AppSpacing.fontSizeLarge);
      });

      test('inputLabel has correct style', () {
        expect(AppTextStyles.inputLabel.color, AppColors.textSecondary);
        expect(AppTextStyles.inputLabel.fontSize, AppSpacing.fontSizeDefault);
      });

      test('inputCounter returns normal style when under limit', () {
        final style = AppTextStyles.inputCounter(count: 5, maxLength: 10);
        expect(style.color, AppColors.textTertiary);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
      });

      test('inputCounter returns warning style when over limit', () {
        final style = AppTextStyles.inputCounter(count: 15, maxLength: 10);
        expect(style.color, AppColors.redAccent);
        expect(style.fontSize, AppSpacing.fontSizeSmall);
      });

      test('inputCounter returns normal style when at limit', () {
        final style = AppTextStyles.inputCounter(count: 10, maxLength: 10);
        expect(style.color, AppColors.textTertiary);
      });

      test('inputCounter returns normal style when count is null', () {
        final style = AppTextStyles.inputCounter(count: null, maxLength: 10);
        expect(style.color, AppColors.textTertiary);
      });

      test('inputCounter returns normal style when maxLength is null', () {
        final style = AppTextStyles.inputCounter(count: 5, maxLength: null);
        expect(style.color, AppColors.textTertiary);
      });
    });
  });
}
