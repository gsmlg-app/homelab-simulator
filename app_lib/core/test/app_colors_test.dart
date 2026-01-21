import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('AppColors', () {
    group('UI Backgrounds', () {
      test('darkBackground is defined', () {
        expect(AppColors.darkBackground, isA<Color>());
        expect(AppColors.darkBackground.toARGB32(), 0xFF0D0D1A);
      });

      test('secondaryBackground is defined', () {
        expect(AppColors.secondaryBackground, isA<Color>());
        expect(AppColors.secondaryBackground.toARGB32(), 0xFF1A1A2E);
      });

      test('componentBackground is defined', () {
        expect(AppColors.componentBackground, isA<Color>());
        expect(AppColors.componentBackground.toARGB32(), 0xFF252540);
      });

      test('containerBackground is defined', () {
        expect(AppColors.containerBackground, isA<Color>());
        expect(AppColors.containerBackground.toARGB32(), 0xFF151528);
      });

      test('selectionBackground is defined', () {
        expect(AppColors.selectionBackground, isA<Color>());
        expect(AppColors.selectionBackground.toARGB32(), 0xFF303060);
      });
    });

    group('Game Component Colors', () {
      test('roomBackground is defined', () {
        expect(AppColors.roomBackground, isA<Color>());
        expect(AppColors.roomBackground.toARGB32(), 0xFF1A1A2E);
      });

      test('gridOverlay is semi-transparent', () {
        expect(AppColors.gridOverlay, isA<Color>());
        expect(AppColors.gridOverlay.a, lessThan(1.0));
      });
    });

    group('Placement Feedback', () {
      test('validPlacementFill is semi-transparent green', () {
        expect(AppColors.validPlacementFill, isA<Color>());
        expect(AppColors.validPlacementFill.a, lessThan(1.0));
      });

      test('validPlacementBorder is opaque green', () {
        expect(AppColors.validPlacementBorder, isA<Color>());
        expect(AppColors.validPlacementBorder.a, 1.0);
      });

      test('invalidPlacementFill is semi-transparent red', () {
        expect(AppColors.invalidPlacementFill, isA<Color>());
        expect(AppColors.invalidPlacementFill.a, lessThan(1.0));
      });

      test('invalidPlacementBorder is opaque red', () {
        expect(AppColors.invalidPlacementBorder, isA<Color>());
        expect(AppColors.invalidPlacementBorder.a, 1.0);
      });
    });

    group('Device Status', () {
      test('deviceSelection is yellow', () {
        expect(AppColors.deviceSelection, isA<Color>());
        expect(AppColors.deviceSelection.toARGB32(), 0xFFFFFF00);
      });

      test('runningIndicator is green', () {
        expect(AppColors.runningIndicator, isA<Color>());
        expect(AppColors.runningIndicator.toARGB32(), 0xFF00FF00);
      });

      test('offIndicator is gray', () {
        expect(AppColors.offIndicator, isA<Color>());
        expect(AppColors.offIndicator.toARGB32(), 0xFF666666);
      });
    });

    group('Door Colors', () {
      test('all door colors are defined', () {
        expect(AppColors.doorFrame, isA<Color>());
        expect(AppColors.doorNormal, isA<Color>());
        expect(AppColors.doorHighlight, isA<Color>());
        expect(AppColors.doorHandle, isA<Color>());
        expect(AppColors.doorBorder, isA<Color>());
        expect(AppColors.doorArrow, isA<Color>());
      });

      test('doorHighlight is brighter than doorNormal', () {
        // Compare blue channel as a proxy for brightness
        expect(AppColors.doorHighlight.b, greaterThan(AppColors.doorNormal.b));
      });
    });

    group('Terminal Colors', () {
      test('all terminal colors are defined', () {
        expect(AppColors.terminalBase, isA<Color>());
        expect(AppColors.terminalScreen, isA<Color>());
        expect(AppColors.terminalHighlight, isA<Color>());
        expect(AppColors.terminalBorder, isA<Color>());
      });

      test('terminalScreen is green', () {
        expect(
          AppColors.terminalScreen.g,
          greaterThan(AppColors.terminalScreen.r),
        );
        expect(
          AppColors.terminalScreen.g,
          greaterThan(AppColors.terminalScreen.b),
        );
      });
    });

    group('Player Colors', () {
      test('playerBody is teal', () {
        expect(AppColors.playerBody, isA<Color>());
        expect(AppColors.playerBody.toARGB32(), 0xFF4ECDC4);
      });

      test('playerOutline is darker teal', () {
        expect(AppColors.playerOutline, isA<Color>());
        // Outline should be darker (lower overall values)
        expect(
          AppColors.playerOutline.computeLuminance(),
          lessThan(AppColors.playerBody.computeLuminance()),
        );
      });
    });

    group('Device Type Colors', () {
      test('all device type colors are defined', () {
        expect(AppColors.deviceServer, isA<Color>());
        expect(AppColors.deviceComputer, isA<Color>());
        expect(AppColors.devicePhone, isA<Color>());
        expect(AppColors.deviceRouter, isA<Color>());
        expect(AppColors.deviceSwitch, isA<Color>());
        expect(AppColors.deviceIot, isA<Color>());
        expect(AppColors.deviceNas, isA<Color>());
        expect(AppColors.deviceMonitor, isA<Color>());
      });

      test('device colors are all opaque', () {
        expect(AppColors.deviceServer.a, 1.0);
        expect(AppColors.deviceComputer.a, 1.0);
        expect(AppColors.devicePhone.a, 1.0);
        expect(AppColors.deviceRouter.a, 1.0);
        expect(AppColors.deviceSwitch.a, 1.0);
        expect(AppColors.deviceIot.a, 1.0);
        expect(AppColors.deviceNas.a, 1.0);
        expect(AppColors.deviceMonitor.a, 1.0);
      });
    });

    group('Cloud Provider Colors', () {
      test('all provider colors are defined', () {
        expect(AppColors.providerAws, isA<Color>());
        expect(AppColors.providerGcp, isA<Color>());
        expect(AppColors.providerAzure, isA<Color>());
        expect(AppColors.providerDigitalOcean, isA<Color>());
        expect(AppColors.providerVultr, isA<Color>());
        expect(AppColors.providerCloudflare, isA<Color>());
      });

      test('AWS color is orange', () {
        expect(AppColors.providerAws.toARGB32(), 0xFFFF9900);
      });

      test('GCP color is blue', () {
        expect(AppColors.providerGcp.toARGB32(), 0xFF4285F4);
      });

      test('Azure color is blue', () {
        expect(AppColors.providerAzure.toARGB32(), 0xFF0078D4);
      });
    });

    group('Service Category Colors', () {
      test('all category colors are defined', () {
        expect(AppColors.categoryCompute, isA<Color>());
        expect(AppColors.categoryStorage, isA<Color>());
        expect(AppColors.categoryDatabase, isA<Color>());
        expect(AppColors.categoryNetworking, isA<Color>());
        expect(AppColors.categoryServerless, isA<Color>());
        expect(AppColors.categoryContainer, isA<Color>());
      });

      test('category colors match device type colors for consistency', () {
        expect(AppColors.categoryCompute, AppColors.deviceServer);
        expect(AppColors.categoryStorage, AppColors.deviceIot);
        expect(AppColors.categoryDatabase, AppColors.deviceRouter);
        expect(AppColors.categoryNetworking, AppColors.deviceComputer);
        expect(AppColors.categoryServerless, AppColors.devicePhone);
        expect(AppColors.categoryContainer, AppColors.deviceSwitch);
      });
    });

    group('Room Type Colors', () {
      test('all room type colors are defined', () {
        expect(AppColors.roomServer, isA<Color>());
        expect(AppColors.roomNetwork, isA<Color>());
        expect(AppColors.roomCloudRegion, isA<Color>());
        expect(AppColors.roomStorage, isA<Color>());
        expect(AppColors.roomOffice, isA<Color>());
      });
    });

    group('Character Hair Colors', () {
      test('all hair colors are defined', () {
        expect(AppColors.hairBlack, isA<Color>());
        expect(AppColors.hairBrown, isA<Color>());
        expect(AppColors.hairBlonde, isA<Color>());
        expect(AppColors.hairRed, isA<Color>());
        expect(AppColors.hairGray, isA<Color>());
        expect(AppColors.hairBlue, isA<Color>());
        expect(AppColors.hairGreen, isA<Color>());
        expect(AppColors.hairPurple, isA<Color>());
      });

      test('hairBlack is very dark', () {
        expect(AppColors.hairBlack.computeLuminance(), lessThan(0.1));
      });

      test('hairBlonde is bright', () {
        expect(AppColors.hairBlonde.computeLuminance(), greaterThan(0.5));
      });
    });

    group('Cloud Service Icon Color', () {
      test('cloudServiceIcon is white', () {
        expect(AppColors.cloudServiceIcon, isA<Color>());
        expect(AppColors.cloudServiceIcon.toARGB32(), 0xFFFFFFFF);
      });
    });

    group('Grey Scale', () {
      test('all grey shades are defined', () {
        expect(AppColors.grey300, isA<Color>());
        expect(AppColors.grey400, isA<Color>());
        expect(AppColors.grey500, isA<Color>());
        expect(AppColors.grey600, isA<Color>());
        expect(AppColors.grey700, isA<Color>());
        expect(AppColors.grey800, isA<Color>());
        expect(AppColors.grey900, isA<Color>());
      });

      test('grey300 is correct shade', () {
        expect(AppColors.grey300.toARGB32(), 0xFFE0E0E0);
      });

      test('grey400 is correct shade', () {
        expect(AppColors.grey400.toARGB32(), 0xFFBDBDBD);
      });

      test('grey500 is correct shade', () {
        expect(AppColors.grey500.toARGB32(), 0xFF9E9E9E);
      });

      test('grey600 is correct shade', () {
        expect(AppColors.grey600.toARGB32(), 0xFF757575);
      });

      test('grey700 is correct shade', () {
        expect(AppColors.grey700.toARGB32(), 0xFF616161);
      });

      test('grey800 is correct shade', () {
        expect(AppColors.grey800.toARGB32(), 0xFF424242);
      });

      test('grey900 is correct shade', () {
        expect(AppColors.grey900.toARGB32(), 0xFF212121);
      });

      test('grey shades get progressively darker', () {
        expect(
          AppColors.grey300.computeLuminance(),
          greaterThan(AppColors.grey400.computeLuminance()),
        );
        expect(
          AppColors.grey400.computeLuminance(),
          greaterThan(AppColors.grey500.computeLuminance()),
        );
        expect(
          AppColors.grey500.computeLuminance(),
          greaterThan(AppColors.grey600.computeLuminance()),
        );
        expect(
          AppColors.grey600.computeLuminance(),
          greaterThan(AppColors.grey700.computeLuminance()),
        );
        expect(
          AppColors.grey700.computeLuminance(),
          greaterThan(AppColors.grey800.computeLuminance()),
        );
        expect(
          AppColors.grey800.computeLuminance(),
          greaterThan(AppColors.grey900.computeLuminance()),
        );
      });
    });

    group('Accent Colors', () {
      test('all cyan shades are defined', () {
        expect(AppColors.cyan200, isA<Color>());
        expect(AppColors.cyan400, isA<Color>());
        expect(AppColors.cyan500, isA<Color>());
        expect(AppColors.cyan700, isA<Color>());
        expect(AppColors.cyan800, isA<Color>());
        expect(AppColors.cyan900, isA<Color>());
      });

      test('cyan200 is correct shade', () {
        expect(AppColors.cyan200.toARGB32(), 0xFF80DEEA);
      });

      test('cyan400 is correct shade', () {
        expect(AppColors.cyan400.toARGB32(), 0xFF26C6DA);
      });

      test('cyan500 is correct shade', () {
        expect(AppColors.cyan500.toARGB32(), 0xFF00BCD4);
      });

      test('cyan700 is correct shade', () {
        expect(AppColors.cyan700.toARGB32(), 0xFF0097A7);
      });

      test('cyan900 is correct shade', () {
        expect(AppColors.cyan900.toARGB32(), 0xFF006064);
      });

      test('cyan shades get progressively darker', () {
        expect(
          AppColors.cyan200.computeLuminance(),
          greaterThan(AppColors.cyan400.computeLuminance()),
        );
        expect(
          AppColors.cyan400.computeLuminance(),
          greaterThan(AppColors.cyan500.computeLuminance()),
        );
        expect(
          AppColors.cyan500.computeLuminance(),
          greaterThan(AppColors.cyan700.computeLuminance()),
        );
        expect(
          AppColors.cyan700.computeLuminance(),
          greaterThan(AppColors.cyan800.computeLuminance()),
        );
        expect(
          AppColors.cyan800.computeLuminance(),
          greaterThan(AppColors.cyan900.computeLuminance()),
        );
      });

      test('all green shades are defined', () {
        expect(AppColors.green400, isA<Color>());
        expect(AppColors.green700, isA<Color>());
        expect(AppColors.green800, isA<Color>());
      });

      test('green400 is correct shade', () {
        expect(AppColors.green400.toARGB32(), 0xFF66BB6A);
      });

      test('green700 is correct shade', () {
        expect(AppColors.green700.toARGB32(), 0xFF388E3C);
      });

      test('green800 is correct shade', () {
        expect(AppColors.green800.toARGB32(), 0xFF2E7D32);
      });

      test('green shades get progressively darker', () {
        expect(
          AppColors.green400.computeLuminance(),
          greaterThan(AppColors.green700.computeLuminance()),
        );
        expect(
          AppColors.green700.computeLuminance(),
          greaterThan(AppColors.green800.computeLuminance()),
        );
      });

      test('red800 is defined', () {
        expect(AppColors.red800, isA<Color>());
        expect(AppColors.red800.toARGB32(), 0xFFC62828);
      });

      test('all blue shades are defined', () {
        expect(AppColors.blue400, isA<Color>());
        expect(AppColors.blue700, isA<Color>());
        expect(AppColors.blue800, isA<Color>());
        expect(AppColors.blue900, isA<Color>());
      });

      test('blue900 is correct shade', () {
        expect(AppColors.blue900.toARGB32(), 0xFF0D47A1);
      });

      test('blue shades get progressively darker', () {
        expect(
          AppColors.blue400.computeLuminance(),
          greaterThan(AppColors.blue700.computeLuminance()),
        );
        expect(
          AppColors.blue700.computeLuminance(),
          greaterThan(AppColors.blue800.computeLuminance()),
        );
        expect(
          AppColors.blue800.computeLuminance(),
          greaterThan(AppColors.blue900.computeLuminance()),
        );
      });

      test('orange800 is defined', () {
        expect(AppColors.orange800, isA<Color>());
        expect(AppColors.orange800.toARGB32(), 0xFFEF6C00);
      });

      test('amber400 is defined', () {
        expect(AppColors.amber400, isA<Color>());
        expect(AppColors.amber400.toARGB32(), 0xFFFFCA28);
      });

      test('amber700 is defined', () {
        expect(AppColors.amber700, isA<Color>());
        expect(AppColors.amber700.toARGB32(), 0xFFFFA000);
      });

      test('amber shades get progressively darker', () {
        expect(
          AppColors.amber400.computeLuminance(),
          greaterThan(AppColors.amber700.computeLuminance()),
        );
      });
    });

    group('Panel/Overlay Colors', () {
      test('panelBackground is defined (black87 equivalent)', () {
        expect(AppColors.panelBackground, isA<Color>());
        expect(AppColors.panelBackground.toARGB32(), 0xDD000000);
        // Alpha 0xDD = 221/255 ≈ 87%
        expect(AppColors.panelBackground.a, closeTo(0.87, 0.01));
      });

      test('overlayBackground is defined (black54 equivalent)', () {
        expect(AppColors.overlayBackground, isA<Color>());
        expect(AppColors.overlayBackground.toARGB32(), 0x8A000000);
        // Alpha 0x8A = 138/255 ≈ 54%
        expect(AppColors.overlayBackground.a, closeTo(0.54, 0.01));
      });

      test('divider is neutral grey', () {
        expect(AppColors.divider, isA<Color>());
        expect(AppColors.divider.toARGB32(), 0xFF9E9E9E);
      });

      test('panelBackground is darker than overlayBackground', () {
        // Higher alpha means more opaque (darker)
        expect(
          AppColors.panelBackground.a,
          greaterThan(AppColors.overlayBackground.a),
        );
      });
    });

    group('Text Colors', () {
      test('textSecondary is white with 70% opacity', () {
        expect(AppColors.textSecondary, isA<Color>());
        expect(AppColors.textSecondary.toARGB32(), 0xB3FFFFFF);
        // Alpha 0xB3 = 179/255 ≈ 70%
        expect(AppColors.textSecondary.a, closeTo(0.70, 0.01));
      });

      test('textTertiary is white with 54% opacity', () {
        expect(AppColors.textTertiary, isA<Color>());
        expect(AppColors.textTertiary.toARGB32(), 0x8AFFFFFF);
        // Alpha 0x8A = 138/255 ≈ 54%
        expect(AppColors.textTertiary.a, closeTo(0.54, 0.01));
      });

      test('textHint is white with 40% opacity', () {
        expect(AppColors.textHint, isA<Color>());
        expect(AppColors.textHint.toARGB32(), 0x66FFFFFF);
        // Alpha 0x66 = 102/255 ≈ 40%
        expect(AppColors.textHint.a, closeTo(0.40, 0.01));
      });

      test('text opacities decrease in order', () {
        expect(
          AppColors.textSecondary.a,
          greaterThan(AppColors.textTertiary.a),
        );
        expect(AppColors.textTertiary.a, greaterThan(AppColors.textHint.a));
      });
    });

    group('Color Consistency', () {
      test('all colors are const', () {
        // These should compile without error since they're const
        const colors = [
          AppColors.darkBackground,
          AppColors.secondaryBackground,
          AppColors.validPlacementFill,
          AppColors.deviceServer,
          AppColors.providerAws,
          AppColors.categoryCompute,
          AppColors.roomServer,
          AppColors.hairBlack,
        ];
        expect(colors.length, 8);
      });

      test('roomBackground equals secondaryBackground', () {
        expect(AppColors.roomBackground, AppColors.secondaryBackground);
      });
    });
  });
}
