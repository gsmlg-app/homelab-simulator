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
        final result = converter.toSql([
          'hello "world"',
          "it's",
          'back\\slash',
        ]);
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

    group('edge cases', () {
      test('handles list with empty strings', () {
        final original = ['', '', ''];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('handles list with newlines', () {
        final original = ['line1\nline2', 'a\nb\nc'];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('handles list with tabs', () {
        final original = ['col1\tcol2', 'a\tb'];
        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);
        expect(decoded, original);
      });

      test('handles mixed content types in JSON', () {
        // When JSON contains mixed types, they get converted to strings
        final result = converter.fromSql('["string", 123, true, null]');
        expect(result.length, 4);
        expect(result[0], 'string');
        expect(result[1], '123');
        expect(result[2], 'true');
        expect(result[3], 'null');
      });
    });

    group('consistency', () {
      test('toSql returns valid JSON', () {
        final list = ['a', 'b', 'c'];
        final json = converter.toSql(list);

        expect(json.startsWith('['), isTrue);
        expect(json.endsWith(']'), isTrue);
      });

      test('multiple round trips produce same result', () {
        final original = ['item1', 'item2', 'item3'];

        // First round trip
        final encoded1 = converter.toSql(original);
        final decoded1 = converter.fromSql(encoded1);

        // Second round trip
        final encoded2 = converter.toSql(decoded1);
        final decoded2 = converter.fromSql(encoded2);

        expect(decoded2, original);
        expect(encoded1, encoded2);
      });
    });

    group('type safety', () {
      test('toSql accepts List<String>', () {
        final List<String> list = ['a', 'b'];
        final result = converter.toSql(list);
        expect(result, isA<String>());
      });

      test('fromSql returns List<String>', () {
        final result = converter.fromSql('["a", "b"]');
        expect(result, isA<List<String>>());
      });
    });
  });
}
