import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('AppSpacing', () {
    group('spacing values', () {
      test('xs is 4.0', () {
        expect(AppSpacing.xs, 4.0);
      });

      test('sm is 6.0', () {
        expect(AppSpacing.sm, 6.0);
      });

      test('s is 8.0', () {
        expect(AppSpacing.s, 8.0);
      });

      test('ms is 12.0', () {
        expect(AppSpacing.ms, 12.0);
      });

      test('m is 16.0', () {
        expect(AppSpacing.m, 16.0);
      });

      test('ml is 20.0', () {
        expect(AppSpacing.ml, 20.0);
      });

      test('l is 24.0', () {
        expect(AppSpacing.l, 24.0);
      });

      test('xl is 32.0', () {
        expect(AppSpacing.xl, 32.0);
      });

      test('xxl is 40.0', () {
        expect(AppSpacing.xxl, 40.0);
      });
    });

    group('common edge insets', () {
      test('paddingXs is EdgeInsets.all(4)', () {
        expect(AppSpacing.paddingXs, const EdgeInsets.all(4.0));
      });

      test('paddingS is EdgeInsets.all(8)', () {
        expect(AppSpacing.paddingS, const EdgeInsets.all(8.0));
      });

      test('paddingMs is EdgeInsets.all(12)', () {
        expect(AppSpacing.paddingMs, const EdgeInsets.all(12.0));
      });

      test('paddingM is EdgeInsets.all(16)', () {
        expect(AppSpacing.paddingM, const EdgeInsets.all(16.0));
      });

      test('paddingL is EdgeInsets.all(24)', () {
        expect(AppSpacing.paddingL, const EdgeInsets.all(24.0));
      });

      test('paddingXl is EdgeInsets.all(32)', () {
        expect(AppSpacing.paddingXl, const EdgeInsets.all(32.0));
      });

      test('paddingChip is horizontal 12, vertical 6', () {
        expect(
          AppSpacing.paddingChip,
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        );
      });

      test('paddingButton is horizontal 24, vertical 12', () {
        expect(
          AppSpacing.paddingButton,
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        );
      });

      test('paddingButtonLarge is horizontal 32, vertical 12', () {
        expect(
          AppSpacing.paddingButtonLarge,
          const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
        );
      });

      test('paddingStepIndicator is horizontal 24, vertical 16', () {
        expect(
          AppSpacing.paddingStepIndicator,
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        );
      });

      test('paddingHudPill is horizontal 16, vertical 8', () {
        expect(
          AppSpacing.paddingHudPill,
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        );
      });
    });

    group('widget sizes', () {
      test('stepDotSize is 32.0', () {
        expect(AppSpacing.stepDotSize, 32.0);
      });

      test('stepLineWidth is 40.0', () {
        expect(AppSpacing.stepLineWidth, 40.0);
      });

      test('stepLineHeight is 2.0', () {
        expect(AppSpacing.stepLineHeight, 2.0);
      });

      test('characterPreviewWidth is 192.0', () {
        expect(AppSpacing.characterPreviewWidth, 192.0);
      });

      test('characterPreviewHeight is 256.0', () {
        expect(AppSpacing.characterPreviewHeight, 256.0);
      });

      test('roomSummaryWidth is 200.0', () {
        expect(AppSpacing.roomSummaryWidth, 200.0);
      });

      test('shopModalWidth is 500.0', () {
        expect(AppSpacing.shopModalWidth, 500.0);
      });
    });

    group('icon sizes', () {
      test('iconSizeXs is 12.0', () {
        expect(AppSpacing.iconSizeXs, 12.0);
      });

      test('iconSizeSm is 14.0', () {
        expect(AppSpacing.iconSizeSm, 14.0);
      });

      test('iconSizeSmall is 16.0', () {
        expect(AppSpacing.iconSizeSmall, 16.0);
      });

      test('iconSizeCompact is 18.0', () {
        expect(AppSpacing.iconSizeCompact, 18.0);
      });

      test('iconSizeDefault is 20.0', () {
        expect(AppSpacing.iconSizeDefault, 20.0);
      });

      test('iconSizeMedium is 24.0', () {
        expect(AppSpacing.iconSizeMedium, 24.0);
      });

      test('iconSizeLarge is 28.0', () {
        expect(AppSpacing.iconSizeLarge, 28.0);
      });

      test('iconSizeXl is 32.0', () {
        expect(AppSpacing.iconSizeXl, 32.0);
      });

      test('errorIconSize is 48.0', () {
        expect(AppSpacing.errorIconSize, 48.0);
      });

      test('iconSizeHero is 64.0', () {
        expect(AppSpacing.iconSizeHero, 64.0);
      });
    });

    group('border radius values', () {
      test('radiusSmall is 4.0', () {
        expect(AppSpacing.radiusSmall, 4.0);
      });

      test('radiusMedium is 8.0', () {
        expect(AppSpacing.radiusMedium, 8.0);
      });

      test('radiusLarge is 12.0', () {
        expect(AppSpacing.radiusLarge, 12.0);
      });

      test('radiusXl is 16.0', () {
        expect(AppSpacing.radiusXl, 16.0);
      });
    });

    group('border radius presets', () {
      test('borderRadiusSmall is BorderRadius.circular(4)', () {
        expect(
          AppSpacing.borderRadiusSmall,
          const BorderRadius.all(Radius.circular(4.0)),
        );
      });

      test('borderRadiusSm is BorderRadius.circular(6)', () {
        expect(
          AppSpacing.borderRadiusSm,
          const BorderRadius.all(Radius.circular(6.0)),
        );
      });

      test('borderRadiusMedium is BorderRadius.circular(8)', () {
        expect(
          AppSpacing.borderRadiusMedium,
          const BorderRadius.all(Radius.circular(8.0)),
        );
      });

      test('borderRadiusLarge is BorderRadius.circular(12)', () {
        expect(
          AppSpacing.borderRadiusLarge,
          const BorderRadius.all(Radius.circular(12.0)),
        );
      });

      test('borderRadiusXl is BorderRadius.circular(16)', () {
        expect(
          AppSpacing.borderRadiusXl,
          const BorderRadius.all(Radius.circular(16.0)),
        );
      });

      test('borderRadiusSmall uses radiusSmall constant', () {
        expect(
          AppSpacing.borderRadiusSmall,
          const BorderRadius.all(Radius.circular(AppSpacing.radiusSmall)),
        );
      });

      test('borderRadiusMedium uses radiusMedium constant', () {
        expect(
          AppSpacing.borderRadiusMedium,
          const BorderRadius.all(Radius.circular(AppSpacing.radiusMedium)),
        );
      });

      test('borderRadiusLarge uses radiusLarge constant', () {
        expect(
          AppSpacing.borderRadiusLarge,
          const BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
        );
      });

      test('borderRadiusXl uses radiusXl constant', () {
        expect(
          AppSpacing.borderRadiusXl,
          const BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
        );
      });
    });

    group('letter spacing', () {
      test('letterSpacingWide is 1.0', () {
        expect(AppSpacing.letterSpacingWide, 1.0);
      });

      test('letterSpacingExtraWide is 2.0', () {
        expect(AppSpacing.letterSpacingExtraWide, 2.0);
      });
    });

    group('font sizes', () {
      test('fontSizeXs is 10.0', () {
        expect(AppSpacing.fontSizeXs, 10.0);
      });

      test('fontSizePanel is 11.0', () {
        expect(AppSpacing.fontSizePanel, 11.0);
      });

      test('fontSizeSmall is 12.0', () {
        expect(AppSpacing.fontSizeSmall, 12.0);
      });

      test('fontSizeDefault is 14.0', () {
        expect(AppSpacing.fontSizeDefault, 14.0);
      });

      test('fontSizeMedium is 16.0', () {
        expect(AppSpacing.fontSizeMedium, 16.0);
      });

      test('fontSizeLarge is 18.0', () {
        expect(AppSpacing.fontSizeLarge, 18.0);
      });

      test('fontSizeXl is 20.0', () {
        expect(AppSpacing.fontSizeXl, 20.0);
      });

      test('fontSizeHeading is 24.0', () {
        expect(AppSpacing.fontSizeHeading, 24.0);
      });

      test('fontSizeTitle is 28.0', () {
        expect(AppSpacing.fontSizeTitle, 28.0);
      });
    });

    group('animation durations', () {
      test('animationFast is 200ms', () {
        expect(AppSpacing.animationFast, const Duration(milliseconds: 200));
      });
    });

    group('positioned offsets', () {
      test('topBarOffset is 16.0', () {
        expect(AppSpacing.topBarOffset, 16.0);
      });

      test('roomSummaryOffset is 56.0', () {
        expect(AppSpacing.roomSummaryOffset, 56.0);
      });

      test('bottomHintOffset is 100.0', () {
        expect(AppSpacing.bottomHintOffset, 100.0);
      });
    });
  });
}
