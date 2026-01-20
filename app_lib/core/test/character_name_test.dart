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
  });
}
