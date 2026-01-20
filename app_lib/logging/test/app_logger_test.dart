import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_logging/app_logging.dart';

void main() {
  group('AppLogger', () {
    late AppLogger logger;

    setUp(() {
      logger = AppLogger();
    });

    test('is a singleton', () {
      final logger1 = AppLogger();
      final logger2 = AppLogger();
      expect(identical(logger1, logger2), isTrue);
    });

    test('provides logStream as broadcast stream', () {
      expect(logger.logStream, isA<Stream<LogRecord>>());
      // Can subscribe multiple times
      final sub1 = logger.logStream.listen((_) {});
      final sub2 = logger.logStream.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    group('initialize', () {
      test('can initialize with default parameters', () {
        // Should not throw
        logger.initialize();
      });

      test('can initialize with custom level', () {
        logger.initialize(level: LogLevel.debug);
      });

      test('can initialize with stack trace disabled', () {
        logger.initialize(includeStackTrace: false);
      });

      test('can initialize with all parameters', () {
        logger.initialize(level: LogLevel.warning, includeStackTrace: false);
      });
    });

    group('log methods emit to stream', () {
      test('v() emits verbose log', () async {
        logger.initialize(level: LogLevel.verbose);

        const testMarker = 'TEST_V_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.v('$testMarker verbose message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.verbose);

        await subscription.cancel();
      });

      test('d() emits debug log', () async {
        logger.initialize(level: LogLevel.debug);

        const testMarker = 'TEST_D_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.d('$testMarker debug message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.debug);

        await subscription.cancel();
      });

      test('i() emits info log', () async {
        logger.initialize(level: LogLevel.info);

        const testMarker = 'TEST_I_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.i('$testMarker info message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.info);

        await subscription.cancel();
      });

      test('w() emits warning log', () async {
        logger.initialize(level: LogLevel.warning);

        const testMarker = 'TEST_W_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.w('$testMarker warning message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.warning);

        await subscription.cancel();
      });

      test('e() emits error log', () async {
        logger.initialize(level: LogLevel.error);

        const testMarker = 'TEST_E_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.e('$testMarker error message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.error);

        await subscription.cancel();
      });

      test('f() emits fatal log', () async {
        logger.initialize(level: LogLevel.fatal);

        const testMarker = 'TEST_F_UNIQUE_12345';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        logger.f('$testMarker fatal message');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.message, contains(testMarker));
        expect(receivedRecord!.level, LogLevel.fatal);

        await subscription.cancel();
      });
    });

    group('log level filtering', () {
      test('does not emit verbose log when level is warning', () async {
        logger.initialize(level: LogLevel.warning);

        const testMarker = 'FILTER_VERBOSE_TEST_999';
        bool receivedVerboseLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedVerboseLog = true;
          }
        });

        logger.v('$testMarker should be filtered');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedVerboseLog, isFalse);

        await subscription.cancel();
      });

      test('does not emit debug log when level is error', () async {
        logger.initialize(level: LogLevel.error);

        const testMarker = 'FILTER_DEBUG_TEST_999';
        bool receivedDebugLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedDebugLog = true;
          }
        });

        logger.d('$testMarker should be filtered');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedDebugLog, isFalse);

        await subscription.cancel();
      });

      test('does not emit info log when level is fatal', () async {
        logger.initialize(level: LogLevel.fatal);

        const testMarker = 'FILTER_INFO_TEST_999';
        bool receivedInfoLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedInfoLog = true;
          }
        });

        logger.i('$testMarker should be filtered');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedInfoLog, isFalse);

        await subscription.cancel();
      });

      test('emits warning log when level is warning', () async {
        logger.initialize(level: LogLevel.warning);

        const testMarker = 'EMIT_WARNING_TEST_999';
        bool receivedWarningLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedWarningLog = true;
          }
        });

        logger.w('$testMarker should pass');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedWarningLog, isTrue);

        await subscription.cancel();
      });

      test('emits error log when level is warning', () async {
        logger.initialize(level: LogLevel.warning);

        const testMarker = 'EMIT_ERROR_TEST_999';
        bool receivedErrorLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedErrorLog = true;
          }
        });

        logger.e('$testMarker should pass');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedErrorLog, isTrue);

        await subscription.cancel();
      });

      test('emits fatal log at any level', () async {
        logger.initialize(level: LogLevel.fatal);

        const testMarker = 'EMIT_FATAL_TEST_999';
        bool receivedFatalLog = false;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedFatalLog = true;
          }
        });

        logger.f('$testMarker should pass');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedFatalLog, isTrue);

        await subscription.cancel();
      });
    });

    group('error and stack trace', () {
      test('can log with error object', () async {
        logger.initialize(level: LogLevel.error);

        const testMarker = 'ERROR_OBJ_TEST_999';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        final error = Exception('test error');
        logger.e('$testMarker error with exception', error);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.error, error);

        await subscription.cancel();
      });

      test('can log with error and stack trace', () async {
        logger.initialize(level: LogLevel.error);

        const testMarker = 'ERROR_STACK_TEST_999';
        LogRecord? receivedRecord;
        final subscription = logger.logStream.listen((record) {
          if (record.message.contains(testMarker)) {
            receivedRecord = record;
          }
        });

        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        logger.e('$testMarker error with stack trace', error, stackTrace);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedRecord, isNotNull);
        expect(receivedRecord!.error, error);
        expect(receivedRecord!.stackTrace, isNotNull);

        await subscription.cancel();
      });
    });

    test('dispose closes the stream controller', () {
      // The singleton logger's dispose method should be callable
      // Note: In production, dispose should only be called once at app shutdown
      expect(() => logger.dispose(), returnsNormally);
    });
  });
}
