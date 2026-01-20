import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/src/type_converter.dart';

void main() {
  group('StringListConverter', () {
    const converter = StringListConverter();

    group('toSql', () {
      test('converts empty list to JSON', () {
        final result = converter.toSql([]);
        expect(result, '[]');
      });

      test('converts single item list to JSON', () {
        final result = converter.toSql(['apple']);
        expect(result, '["apple"]');
      });

      test('converts multiple items list to JSON', () {
        final result = converter.toSql(['apple', 'banana', 'cherry']);
        expect(result, '["apple","banana","cherry"]');
      });

      test('handles special characters in strings', () {
        final result = converter.toSql(['hello "world"', "it's", 'back\\slash']);
        expect(result, contains('hello'));
        expect(result, contains('world'));
      });

      test('handles unicode characters', () {
        final result = converter.toSql(['日本語', '한국어', 'emoji 🎮']);
        expect(result, contains('日本語'));
        expect(result, contains('한국어'));
        expect(result, contains('🎮'));
      });
    });

    group('fromSql', () {
      test('converts empty JSON array to list', () {
        final result = converter.fromSql('[]');
        expect(result, isEmpty);
        expect(result, isA<List<String>>());
      });

      test('converts single item JSON to list', () {
        final result = converter.fromSql('["apple"]');
        expect(result, ['apple']);
      });

      test('converts multiple items JSON to list', () {
        final result = converter.fromSql('["apple","banana","cherry"]');
        expect(result, ['apple', 'banana', 'cherry']);
      });

      test('handles special characters', () {
        final result = converter.fromSql('["hello \\"world\\"","it\'s"]');
        expect(result.length, 2);
        expect(result[0], 'hello "world"');
        expect(result[1], "it's");
      });

      test('handles unicode characters', () {
        final result = converter.fromSql('["日本語","한국어","emoji 🎮"]');
        expect(result, ['日本語', '한국어', 'emoji 🎮']);
      });

      test('converts numbers in JSON array to strings', () {
        final result = converter.fromSql('[1, 2, 3]');
        expect(result, ['1', '2', '3']);
      });

      test('converts booleans in JSON array to strings', () {
        final result = converter.fromSql('[true, false]');
        expect(result, ['true', 'false']);
      });
    });

    group('round-trip', () {
      test('preserves empty list', () {
        final original = <String>[];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('preserves simple strings', () {
        final original = ['apple', 'banana', 'cherry'];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('preserves strings with whitespace', () {
        final original = ['hello world', '  spaces  ', '\ttab\t'];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('preserves unicode strings', () {
        final original = ['日本語', '한국어', 'emoji 🎮'];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('preserves large list', () {
        final original = List.generate(100, (i) => 'item_$i');
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });
    });
  });
}
