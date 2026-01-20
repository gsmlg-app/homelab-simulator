import 'package:flutter_test/flutter_test.dart';
import 'package:app_logging/app_logging.dart';

void main() {
  group('LogRecord', () {
    final testTime = DateTime(2024, 1, 15, 12, 0, 0);

    test('creates with required fields', () {
      final record = LogRecord(
        level: LogLevel.info,
        message: 'Test message',
        loggerName: 'TestLogger',
        time: testTime,
      );

      expect(record.level, LogLevel.info);
      expect(record.message, 'Test message');
      expect(record.loggerName, 'TestLogger');
      expect(record.time, testTime);
      expect(record.error, isNull);
      expect(record.stackTrace, isNull);
      expect(record.zone, isNull);
    });

    test('creates with all fields', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      final record = LogRecord(
        level: LogLevel.error,
        message: 'Error message',
        loggerName: 'ErrorLogger',
        time: testTime,
        error: error,
        stackTrace: stackTrace,
      );

      expect(record.level, LogLevel.error);
      expect(record.message, 'Error message');
      expect(record.error, error);
      expect(record.stackTrace, stackTrace);
    });

    test('defaults time to now when not provided', () {
      final before = DateTime.now();
      final record = LogRecord(
        level: LogLevel.info,
        message: 'Test',
        loggerName: 'Test',
      );
      final after = DateTime.now();

      expect(record.time.isAfter(before) || record.time.isAtSameMomentAs(before), isTrue);
      expect(record.time.isBefore(after) || record.time.isAtSameMomentAs(after), isTrue);
    });

    group('copyWith', () {
      test('copies with changed level', () {
        final original = LogRecord(
          level: LogLevel.info,
          message: 'Original',
          loggerName: 'Test',
          time: testTime,
        );

        final copy = original.copyWith(level: LogLevel.error);

        expect(copy.level, LogLevel.error);
        expect(copy.message, 'Original');
        expect(copy.loggerName, 'Test');
        expect(copy.time, testTime);
      });

      test('copies with changed message', () {
        final original = LogRecord(
          level: LogLevel.info,
          message: 'Original',
          loggerName: 'Test',
          time: testTime,
        );

        final copy = original.copyWith(message: 'Changed');

        expect(copy.level, LogLevel.info);
        expect(copy.message, 'Changed');
      });

      test('copies with changed error', () {
        final original = LogRecord(
          level: LogLevel.error,
          message: 'Error',
          loggerName: 'Test',
          time: testTime,
        );

        final newError = Exception('New error');
        final copy = original.copyWith(error: newError);

        expect(copy.error, newError);
      });

      test('preserves all fields when no changes', () {
        final error = Exception('Test');
        final stackTrace = StackTrace.current;

        final original = LogRecord(
          level: LogLevel.warning,
          message: 'Warning',
          loggerName: 'WarningLogger',
          time: testTime,
          error: error,
          stackTrace: stackTrace,
        );

        final copy = original.copyWith();

        expect(copy.level, original.level);
        expect(copy.message, original.message);
        expect(copy.loggerName, original.loggerName);
        expect(copy.time, original.time);
        expect(copy.error, original.error);
        expect(copy.stackTrace, original.stackTrace);
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final record1 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        final record2 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        expect(record1, equals(record2));
      });

      test('not equal when level differs', () {
        final record1 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        final record2 = LogRecord(
          level: LogLevel.error,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        expect(record1, isNot(equals(record2)));
      });

      test('not equal when message differs', () {
        final record1 = LogRecord(
          level: LogLevel.info,
          message: 'Test 1',
          loggerName: 'Test',
          time: testTime,
        );

        final record2 = LogRecord(
          level: LogLevel.info,
          message: 'Test 2',
          loggerName: 'Test',
          time: testTime,
        );

        expect(record1, isNot(equals(record2)));
      });

      test('not equal when time differs', () {
        final record1 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        final record2 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime.add(const Duration(seconds: 1)),
        );

        expect(record1, isNot(equals(record2)));
      });
    });

    group('hashCode', () {
      test('same for equal records', () {
        final record1 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        final record2 = LogRecord(
          level: LogLevel.info,
          message: 'Test',
          loggerName: 'Test',
          time: testTime,
        );

        expect(record1.hashCode, equals(record2.hashCode));
      });
    });

    group('toString', () {
      test('includes all relevant fields', () {
        final record = LogRecord(
          level: LogLevel.error,
          message: 'Error occurred',
          loggerName: 'ErrorLogger',
          time: testTime,
          error: Exception('Test'),
        );

        final str = record.toString();

        expect(str, contains('ERROR'));
        expect(str, contains('Error occurred'));
        expect(str, contains('ErrorLogger'));
        expect(str, contains('Exception: Test'));
      });

      test('includes null error when not set', () {
        final record = LogRecord(
          level: LogLevel.info,
          message: 'Info message',
          loggerName: 'InfoLogger',
          time: testTime,
        );

        final str = record.toString();

        expect(str, contains('error: null'));
      });
    });
  });
}
