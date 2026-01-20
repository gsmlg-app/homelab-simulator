import 'package:flutter_test/flutter_test.dart';
import 'package:app_logging/app_logging.dart';

void main() {
  group('LogLevel', () {
    test('has correct value ordering', () {
      expect(LogLevel.verbose.value, 0);
      expect(LogLevel.debug.value, 1);
      expect(LogLevel.info.value, 2);
      expect(LogLevel.warning.value, 3);
      expect(LogLevel.error.value, 4);
      expect(LogLevel.fatal.value, 5);
    });

    test('has correct name values', () {
      expect(LogLevel.verbose.name, 'VERBOSE');
      expect(LogLevel.debug.name, 'DEBUG');
      expect(LogLevel.info.name, 'INFO');
      expect(LogLevel.warning.name, 'WARNING');
      expect(LogLevel.error.name, 'ERROR');
      expect(LogLevel.fatal.name, 'FATAL');
    });

    group('comparison operators', () {
      test('greater than or equal works correctly', () {
        expect(LogLevel.error >= LogLevel.warning, isTrue);
        expect(LogLevel.error >= LogLevel.error, isTrue);
        expect(LogLevel.warning >= LogLevel.error, isFalse);
      });

      test('greater than works correctly', () {
        expect(LogLevel.error > LogLevel.warning, isTrue);
        expect(LogLevel.error > LogLevel.error, isFalse);
        expect(LogLevel.warning > LogLevel.error, isFalse);
      });

      test('less than or equal works correctly', () {
        expect(LogLevel.warning <= LogLevel.error, isTrue);
        expect(LogLevel.warning <= LogLevel.warning, isTrue);
        expect(LogLevel.error <= LogLevel.warning, isFalse);
      });

      test('less than works correctly', () {
        expect(LogLevel.warning < LogLevel.error, isTrue);
        expect(LogLevel.warning < LogLevel.warning, isFalse);
        expect(LogLevel.error < LogLevel.warning, isFalse);
      });
    });

    test('verbose is lowest level', () {
      for (final level in LogLevel.values) {
        if (level != LogLevel.verbose) {
          expect(LogLevel.verbose < level, isTrue);
        }
      }
    });

    test('fatal is highest level', () {
      for (final level in LogLevel.values) {
        if (level != LogLevel.fatal) {
          expect(LogLevel.fatal > level, isTrue);
        }
      }
    });
  });
}
