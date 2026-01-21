import 'package:flutter_test/flutter_test.dart';
import 'package:game_audio_sfx/game_audio_sfx.dart';

void main() {
  group('SfxType', () {
    test('has 12 sound effect types', () {
      expect(SfxType.values.length, 12);
    });

    test('doorOpen has correct filename', () {
      expect(SfxType.doorOpen.filename, 'door_open.ogg');
    });

    test('doorClose has correct filename', () {
      expect(SfxType.doorClose.filename, 'door_close.ogg');
    });

    test('buttonClick has correct filename', () {
      expect(SfxType.buttonClick.filename, 'button_click.ogg');
    });

    test('buttonHover has correct filename', () {
      expect(SfxType.buttonHover.filename, 'button_hover.ogg');
    });

    test('itemPickup has correct filename', () {
      expect(SfxType.itemPickup.filename, 'item_pickup.ogg');
    });

    test('itemPlace has correct filename', () {
      expect(SfxType.itemPlace.filename, 'item_place.ogg');
    });

    test('error has correct filename', () {
      expect(SfxType.error.filename, 'error.ogg');
    });

    test('success has correct filename', () {
      expect(SfxType.success.filename, 'success.ogg');
    });

    test('menuOpen has correct filename', () {
      expect(SfxType.menuOpen.filename, 'menu_open.ogg');
    });

    test('menuClose has correct filename', () {
      expect(SfxType.menuClose.filename, 'menu_close.ogg');
    });

    test('devicePowerOn has correct filename', () {
      expect(SfxType.devicePowerOn.filename, 'device_power_on.ogg');
    });

    test('devicePowerOff has correct filename', () {
      expect(SfxType.devicePowerOff.filename, 'device_power_off.ogg');
    });

    group('assetPath', () {
      test('doorOpen asset path includes sfx folder', () {
        expect(SfxType.doorOpen.assetPath, 'sfx/door_open.ogg');
      });

      test('buttonClick asset path includes sfx folder', () {
        expect(SfxType.buttonClick.assetPath, 'sfx/button_click.ogg');
      });

      test('all asset paths start with sfx/', () {
        for (final sfx in SfxType.values) {
          expect(sfx.assetPath, startsWith('sfx/'));
        }
      });

      test('all asset paths end with .ogg', () {
        for (final sfx in SfxType.values) {
          expect(sfx.assetPath, endsWith('.ogg'));
        }
      });

      test('all asset paths contain filename', () {
        for (final sfx in SfxType.values) {
          expect(sfx.assetPath, contains(sfx.filename));
        }
      });
    });

    group('enum properties', () {
      test('all values have non-empty filename', () {
        for (final sfx in SfxType.values) {
          expect(sfx.filename, isNotEmpty);
        }
      });

      test('all filenames are unique', () {
        final filenames = SfxType.values.map((e) => e.filename).toSet();
        expect(filenames.length, SfxType.values.length);
      });

      test('all filenames have .ogg extension', () {
        for (final sfx in SfxType.values) {
          expect(sfx.filename, endsWith('.ogg'));
        }
      });

      test('all filenames use snake_case', () {
        final snakeCasePattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*\.ogg$');
        for (final sfx in SfxType.values) {
          expect(
            snakeCasePattern.hasMatch(sfx.filename),
            isTrue,
            reason: '${sfx.filename} should be snake_case',
          );
        }
      });
    });

    group('enum values', () {
      test('has doorOpen', () {
        expect(SfxType.values, contains(SfxType.doorOpen));
      });

      test('has doorClose', () {
        expect(SfxType.values, contains(SfxType.doorClose));
      });

      test('has buttonClick', () {
        expect(SfxType.values, contains(SfxType.buttonClick));
      });

      test('has buttonHover', () {
        expect(SfxType.values, contains(SfxType.buttonHover));
      });

      test('has itemPickup', () {
        expect(SfxType.values, contains(SfxType.itemPickup));
      });

      test('has itemPlace', () {
        expect(SfxType.values, contains(SfxType.itemPlace));
      });

      test('has error', () {
        expect(SfxType.values, contains(SfxType.error));
      });

      test('has success', () {
        expect(SfxType.values, contains(SfxType.success));
      });

      test('has menuOpen', () {
        expect(SfxType.values, contains(SfxType.menuOpen));
      });

      test('has menuClose', () {
        expect(SfxType.values, contains(SfxType.menuClose));
      });

      test('has devicePowerOn', () {
        expect(SfxType.values, contains(SfxType.devicePowerOn));
      });

      test('has devicePowerOff', () {
        expect(SfxType.values, contains(SfxType.devicePowerOff));
      });
    });
  });
}
