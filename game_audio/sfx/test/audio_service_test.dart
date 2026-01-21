import 'package:flutter_test/flutter_test.dart';
import 'package:game_audio_sfx/game_audio_sfx.dart';

void main() {
  group('AudioService', () {
    late AudioService service;

    setUp(() {
      service = AudioService();
    });

    group('construction', () {
      test('creates instance', () {
        expect(service, isA<AudioService>());
      });

      test('singleton instance exists', () {
        expect(AudioService.instance, isA<AudioService>());
      });

      test('singleton is same instance across accesses', () {
        expect(AudioService.instance, same(AudioService.instance));
      });

      test('new instances are not singleton', () {
        final instance1 = AudioService();
        final instance2 = AudioService();
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('initial state', () {
      test('isInitialized defaults to false', () {
        expect(service.isInitialized, isFalse);
      });

      test('sfxEnabled defaults to true', () {
        expect(service.sfxEnabled, isTrue);
      });

      test('sfxVolume defaults to 1.0', () {
        expect(service.sfxVolume, 1.0);
      });

      test('musicEnabled defaults to true', () {
        expect(service.musicEnabled, isTrue);
      });

      test('musicVolume defaults to 0.5', () {
        expect(service.musicVolume, 0.5);
      });
    });

    group('setSfxEnabled', () {
      test('can disable sound effects', () {
        service.setSfxEnabled(false);
        expect(service.sfxEnabled, isFalse);
      });

      test('can enable sound effects', () {
        service.setSfxEnabled(false);
        service.setSfxEnabled(true);
        expect(service.sfxEnabled, isTrue);
      });

      test('setting to same value is idempotent', () {
        service.setSfxEnabled(true);
        service.setSfxEnabled(true);
        expect(service.sfxEnabled, isTrue);
      });
    });

    group('setSfxVolume', () {
      test('sets volume to specified value', () {
        service.setSfxVolume(0.5);
        expect(service.sfxVolume, 0.5);
      });

      test('clamps volume to minimum 0.0', () {
        service.setSfxVolume(-0.5);
        expect(service.sfxVolume, 0.0);
      });

      test('clamps volume to maximum 1.0', () {
        service.setSfxVolume(1.5);
        expect(service.sfxVolume, 1.0);
      });

      test('accepts 0.0 volume', () {
        service.setSfxVolume(0.0);
        expect(service.sfxVolume, 0.0);
      });

      test('accepts 1.0 volume', () {
        service.setSfxVolume(1.0);
        expect(service.sfxVolume, 1.0);
      });

      test('accepts mid-range volume', () {
        service.setSfxVolume(0.7);
        expect(service.sfxVolume, 0.7);
      });
    });

    group('setMusicEnabled', () {
      test('can disable music', () {
        service.setMusicEnabled(false);
        expect(service.musicEnabled, isFalse);
      });

      test('can enable music', () {
        service.setMusicEnabled(false);
        service.setMusicEnabled(true);
        expect(service.musicEnabled, isTrue);
      });

      test('setting to same value is idempotent', () {
        service.setMusicEnabled(true);
        service.setMusicEnabled(true);
        expect(service.musicEnabled, isTrue);
      });
    });

    group('setMusicVolume', () {
      test('sets volume to specified value', () {
        service.setMusicVolume(0.3);
        expect(service.musicVolume, 0.3);
      });

      test('clamps volume to minimum 0.0', () {
        service.setMusicVolume(-1.0);
        expect(service.musicVolume, 0.0);
      });

      test('clamps volume to maximum 1.0', () {
        service.setMusicVolume(2.0);
        expect(service.musicVolume, 1.0);
      });

      test('accepts 0.0 volume', () {
        service.setMusicVolume(0.0);
        expect(service.musicVolume, 0.0);
      });

      test('accepts 1.0 volume', () {
        service.setMusicVolume(1.0);
        expect(service.musicVolume, 1.0);
      });

      test('accepts mid-range volume', () {
        service.setMusicVolume(0.75);
        expect(service.musicVolume, 0.75);
      });
    });

    group('playSfx when not initialized', () {
      test('does not throw when sfx is enabled but not initialized', () async {
        expect(service.sfxEnabled, isTrue);
        expect(service.isInitialized, isFalse);

        // Should not throw, just return early
        await expectLater(service.playSfx(SfxType.buttonClick), completes);
      });
    });

    group('playSfx when disabled', () {
      test('does not throw when sfx is disabled', () async {
        service.setSfxEnabled(false);

        // Should not throw, just return early
        await expectLater(service.playSfx(SfxType.buttonClick), completes);
      });
    });

    group('playBackgroundMusic when not initialized', () {
      test(
        'does not throw when music is enabled but not initialized',
        () async {
          expect(service.musicEnabled, isTrue);
          expect(service.isInitialized, isFalse);

          // Should not throw, just return early
          await expectLater(
            service.playBackgroundMusic('music.ogg'),
            completes,
          );
        },
      );
    });

    group('playBackgroundMusic when disabled', () {
      test('does not throw when music is disabled', () async {
        service.setMusicEnabled(false);

        // Should not throw, just return early
        await expectLater(service.playBackgroundMusic('music.ogg'), completes);
      });
    });

    group('volume edge cases', () {
      test('sfx volume handles very small values', () {
        service.setSfxVolume(0.001);
        expect(service.sfxVolume, 0.001);
      });

      test('sfx volume handles values very close to 1', () {
        service.setSfxVolume(0.999);
        expect(service.sfxVolume, 0.999);
      });

      test('music volume handles very small values', () {
        service.setMusicVolume(0.001);
        expect(service.musicVolume, 0.001);
      });

      test('music volume handles values very close to 1', () {
        service.setMusicVolume(0.999);
        expect(service.musicVolume, 0.999);
      });

      test('sfx volume clamps negative values to 0', () {
        service.setSfxVolume(-100);
        expect(service.sfxVolume, 0.0);
      });

      test('music volume clamps large positive values to 1', () {
        service.setMusicVolume(100);
        expect(service.musicVolume, 1.0);
      });
    });
  });
}
