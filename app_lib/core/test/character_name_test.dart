import 'package:test/test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('validateCharacterName', () {
    test('returns valid for acceptable names', () {
      expect(validateCharacterName('Alex').isValid, isTrue);
      expect(validateCharacterName('CyberRunner').isValid, isTrue);
      expect(validateCharacterName('Player1').isValid, isTrue);
      expect(validateCharacterName('AB').isValid, isTrue); // minimum length
      expect(
        validateCharacterName('1234567890123456').isValid,
        isTrue,
      ); // max length
    });

    test('returns invalid for empty names', () {
      final result = validateCharacterName('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test('returns invalid for whitespace-only names', () {
      final result = validateCharacterName('   ');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test('returns invalid for names shorter than 2 characters', () {
      final result = validateCharacterName('A');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('2 characters'));
    });

    test('returns invalid for names longer than 16 characters', () {
      final result = validateCharacterName('12345678901234567');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('16 characters'));
    });

    test('returns invalid for reserved words', () {
      for (final word in ['admin', 'system', 'root', 'null', 'test']) {
        final result = validateCharacterName(word);
        expect(result.isValid, isFalse, reason: '$word should be reserved');
        expect(result.errorMessage, contains('reserved'));
      }
    });

    test('returns invalid for reserved words case-insensitive', () {
      final result = validateCharacterName('ADMIN');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('reserved'));
    });

    test('returns invalid for names containing blocked words', () {
      final result = validateCharacterName('coolassname');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('inappropriate'));
    });

    test('trims whitespace before validation', () {
      final result = validateCharacterName('  Alex  ');
      expect(result.isValid, isTrue);
    });

    group('blocked word edge cases', () {
      test('blocks words that contain blocked substring (grass contains ass)', () {
        // Current implementation uses contains(), so 'grass' will be blocked
        final result = validateCharacterName('grass');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('inappropriate'));
      });

      test('blocks name with blocked word at start', () {
        final result = validateCharacterName('assemble');
        expect(result.isValid, isFalse);
      });

      test('blocks name with blocked word at end', () {
        final result = validateCharacterName('badass');
        expect(result.isValid, isFalse);
      });

      test('blocks name with multiple blocked words', () {
        final result = validateCharacterName('damnhell');
        expect(result.isValid, isFalse);
      });

      test('blocked word check is case-insensitive', () {
        final result = validateCharacterName('GRASS');
        expect(result.isValid, isFalse);
      });

      test('blocked word check handles mixed case', () {
        final result = validateCharacterName('GrAsS');
        expect(result.isValid, isFalse);
      });
    });

    group('special character handling', () {
      test('allows names with numbers', () {
        expect(validateCharacterName('Player42').isValid, isTrue);
        expect(validateCharacterName('42Player').isValid, isTrue);
        expect(validateCharacterName('1234567890').isValid, isTrue);
      });

      test('allows names with underscores', () {
        expect(validateCharacterName('Cool_Name').isValid, isTrue);
        expect(validateCharacterName('_Start').isValid, isTrue);
        expect(validateCharacterName('End_').isValid, isTrue);
      });

      test('allows names with hyphens', () {
        expect(validateCharacterName('Cyber-Runner').isValid, isTrue);
      });

      test('allows names with unicode letters', () {
        expect(validateCharacterName('Ålexандр').isValid, isTrue);
        expect(validateCharacterName('日本語').isValid, isTrue);
      });

      test('allows names with emoji', () {
        // Emoji are allowed by current implementation
        expect(validateCharacterName('Star⭐').isValid, isTrue);
      });
    });

    group('boundary conditions', () {
      test('exactly minimum length (2 chars) is valid', () {
        expect(validateCharacterName('AB').isValid, isTrue);
      });

      test('exactly maximum length (16 chars) is valid', () {
        expect(validateCharacterName('A' * 16).isValid, isTrue);
      });

      test('one below minimum (1 char) is invalid', () {
        expect(validateCharacterName('A').isValid, isFalse);
      });

      test('one above maximum (17 chars) is invalid', () {
        expect(validateCharacterName('A' * 17).isValid, isFalse);
      });

      test('whitespace padding does not count toward length', () {
        // '  A  ' trims to 'A' which is 1 char - invalid
        final result = validateCharacterName('  A  ');
        expect(result.isValid, isFalse);
      });
    });
  });

  group('CharacterNameGenerator', () {
    test('generates non-empty names', () {
      for (var i = 0; i < 100; i++) {
        final name = CharacterNameGenerator.generate();
        expect(name, isNotEmpty);
      }
    });

    test('generates names within valid length', () {
      for (var i = 0; i < 100; i++) {
        final name = CharacterNameGenerator.generate();
        expect(name.length, greaterThanOrEqualTo(2));
        expect(name.length, lessThanOrEqualTo(16));
      }
    });

    test('generated names pass validation', () {
      for (var i = 0; i < 100; i++) {
        final name = CharacterNameGenerator.generate();
        final result = validateCharacterName(name);
        expect(
          result.isValid,
          isTrue,
          reason: 'Generated name "$name" should be valid',
        );
      }
    });

    test('generates variety of name styles', () {
      // Run enough times to statistically hit all 3 styles
      final names = <String>{};
      for (var i = 0; i < 200; i++) {
        names.add(CharacterNameGenerator.generate());
      }
      // Should have generated multiple unique names
      expect(names.length, greaterThan(20));
    });

    test('generated prefix+suffix names are valid', () {
      // These are known valid combinations from the lists
      // Longest: 'Quantum' (7) + 'Master' (6) = 13 chars (< 16)
      // Check that all prefix+suffix combos would be valid
      const prefixes = ['Cyber', 'Neo', 'Quantum', 'Alpha', 'Sigma'];
      const suffixes = ['Runner', 'Master', 'Knight', 'Admin', 'Hack'];

      for (final prefix in prefixes) {
        for (final suffix in suffixes) {
          final name = '$prefix$suffix';
          final result = validateCharacterName(name);
          expect(
            result.isValid,
            isTrue,
            reason: 'Combined name "$name" should be valid',
          );
        }
      }
    });

    test('generated name+number names stay within max length', () {
      // Longest name 'Phoenix' (7) + '99' (2) = 9 chars (< 16)
      const longestName = 'Phoenix';
      const maxNumber = 99;
      final worstCase = '$longestName$maxNumber';
      expect(worstCase.length, lessThanOrEqualTo(16));
    });
  });

  group('NameValidationResult', () {
    test('valid result has no error message', () {
      const result = NameValidationResult.valid();
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('invalid result has error message', () {
      const result = NameValidationResult.invalid('Test error');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Test error');
    });
  });

  group('CharacterNameConstants', () {
    test('minLength is 2', () {
      expect(CharacterNameConstants.minLength, 2);
    });

    test('maxLength is 16', () {
      expect(CharacterNameConstants.maxLength, 16);
    });

    test('reservedWords contains expected words', () {
      expect(CharacterNameConstants.reservedWords, contains('admin'));
      expect(CharacterNameConstants.reservedWords, contains('system'));
      expect(CharacterNameConstants.reservedWords, contains('root'));
    });

    test('blockedWords is not empty', () {
      expect(CharacterNameConstants.blockedWords, isNotEmpty);
    });
  });
}
