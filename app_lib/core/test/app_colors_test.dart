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
        expect(
          AppColors.doorHighlight.b,
          greaterThan(AppColors.doorNormal.b),
        );
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
        expect(AppColors.terminalScreen.g, greaterThan(AppColors.terminalScreen.r));
        expect(AppColors.terminalScreen.g, greaterThan(AppColors.terminalScreen.b));
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
