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

    group('edge cases', () {
      test('all levels have unique values', () {
        final values = LogLevel.values.map((l) => l.value).toSet();
        expect(values.length, LogLevel.values.length);
      });

      test('all levels have unique names', () {
        final names = LogLevel.values.map((l) => l.name).toSet();
        expect(names.length, LogLevel.values.length);
      });

      test('values are sequential from 0', () {
        for (int i = 0; i < LogLevel.values.length; i++) {
          expect(LogLevel.values[i].value, i);
        }
      });

      test('adjacent levels differ by 1', () {
        for (int i = 1; i < LogLevel.values.length; i++) {
          expect(LogLevel.values[i].value - LogLevel.values[i - 1].value, 1);
        }
      });
    });

    group('level count', () {
      test('has exactly 6 levels', () {
        expect(LogLevel.values.length, 6);
      });
    });

    group('level transitions', () {
      test('each level is strictly greater than previous', () {
        LogLevel previous = LogLevel.verbose;
        for (final level in LogLevel.values.skip(1)) {
          expect(level > previous, isTrue);
          previous = level;
        }
      });

      test('each level is strictly less than next', () {
        for (int i = 0; i < LogLevel.values.length - 1; i++) {
          expect(LogLevel.values[i] < LogLevel.values[i + 1], isTrue);
        }
      });
    });

    group('equality comparison', () {
      test('level equals itself', () {
        for (final level in LogLevel.values) {
          expect(level >= level, isTrue);
          expect(level <= level, isTrue);
        }
      });

      test('level is not less than itself', () {
        for (final level in LogLevel.values) {
          expect(level < level, isFalse);
        }
      });

      test('level is not greater than itself', () {
        for (final level in LogLevel.values) {
          expect(level > level, isFalse);
        }
      });
    });

    group('boundary comparisons', () {
      test('verbose is less than or equal to all levels', () {
        for (final level in LogLevel.values) {
          expect(LogLevel.verbose <= level, isTrue);
        }
      });

      test('fatal is greater than or equal to all levels', () {
        for (final level in LogLevel.values) {
          expect(LogLevel.fatal >= level, isTrue);
        }
      });

      test('verbose not greater than any level except itself', () {
        for (final level in LogLevel.values) {
          if (level != LogLevel.verbose) {
            expect(LogLevel.verbose > level, isFalse);
          }
        }
      });

      test('fatal not less than any level except itself', () {
        for (final level in LogLevel.values) {
          if (level != LogLevel.fatal) {
            expect(LogLevel.fatal < level, isFalse);
          }
        }
      });
    });
  });
}
