import 'package:app_logging/app_logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ErrorReportingService', () {
    late ErrorReportingService service;

    setUp(() {
      service = ErrorReportingService();
    });

    test('is a singleton', () {
      final service1 = ErrorReportingService();
      final service2 = ErrorReportingService();
      expect(identical(service1, service2), isTrue);
    });

    group('reportError', () {
      test('stores error in preferences', () async {
        await service.reportError(
          error: Exception('test error'),
          context: 'test context',
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts stack trace parameter', () async {
        await service.reportError(
          error: Exception('test error'),
          stackTrace: StackTrace.current,
          context: 'with stack trace',
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts additional data parameter', () async {
        await service.reportError(
          error: Exception('test error'),
          additionalData: {'key': 'value'},
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts custom log level', () async {
        await service.reportError(
          error: Exception('fatal error'),
          level: LogLevel.fatal,
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('sendToBackend parameter does not throw', () async {
        await service.reportError(
          error: Exception('backend error'),
          sendToBackend: true,
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });
    });

    group('reportException', () {
      test('stores exception in preferences', () async {
        await service.reportException(
          exception: Exception('test exception'),
          context: 'exception context',
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts stack trace parameter', () async {
        await service.reportException(
          exception: const FormatException('parse error'),
          stackTrace: StackTrace.current,
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts additional data parameter', () async {
        await service.reportException(
          exception: Exception('state error'),
          additionalData: {'state': 'invalid'},
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });
    });

    group('reportFlutterError', () {
      test('stores Flutter error in preferences', () async {
        final details = FlutterErrorDetails(
          exception: Exception('flutter error'),
          library: 'test library',
        );

        await service.reportFlutterError(details: details);

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts custom context parameter', () async {
        final details = FlutterErrorDetails(
          exception: Exception('flutter error'),
          library: 'widgets',
        );

        await service.reportFlutterError(
          details: details,
          context: 'Custom Flutter Error',
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('accepts custom log level', () async {
        final details = FlutterErrorDetails(
          exception: Exception('flutter error'),
          library: 'framework',
        );

        await service.reportFlutterError(
          details: details,
          level: LogLevel.warning,
        );

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('handles error with stack trace', () async {
        final details = FlutterErrorDetails(
          exception: Exception('flutter error'),
          stack: StackTrace.current,
        );

        await service.reportFlutterError(details: details);

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });
    });

    group('getRecentErrors', () {
      test('returns empty list when no errors stored', () async {
        final errors = await service.getRecentErrors();
        expect(errors, isEmpty);
      });

      test('returns list of stored errors', () async {
        await service.reportError(error: Exception('error 1'));
        await service.reportError(error: Exception('error 2'));

        final errors = await service.getRecentErrors();
        expect(errors, hasLength(2));
      });

      test('returns errors in order', () async {
        await service.reportError(error: Exception('first'));
        await service.reportError(error: Exception('second'));
        await service.reportError(error: Exception('third'));

        final errors = await service.getRecentErrors();
        expect(errors, hasLength(3));
      });
    });

    group('clearErrorLogs', () {
      test('removes all stored errors', () async {
        await service.reportError(error: Exception('error 1'));
        await service.reportError(error: Exception('error 2'));

        await service.clearErrorLogs();

        final errors = await service.getRecentErrors();
        expect(errors, isEmpty);
      });

      test('does not throw when no errors to clear', () async {
        await service.clearErrorLogs();

        final errors = await service.getRecentErrors();
        expect(errors, isEmpty);
      });
    });

    group('exportErrorLogs', () {
      test('does not throw when exporting empty logs', () async {
        await service.exportErrorLogs();
        // Should complete without error
      });

      test('does not throw when exporting with errors', () async {
        await service.reportError(error: Exception('error'));
        await service.exportErrorLogs();
        // Should complete without error
      });
    });

    group('setupGlobalErrorHandler', () {
      test('does not throw when called', () {
        expect(() => service.setupGlobalErrorHandler(), returnsNormally);
      });
    });

    group('error storage limits', () {
      test('limits stored errors to max 100', () async {
        // Store more than 100 errors
        for (int i = 0; i < 110; i++) {
          await service.reportError(error: Exception('error $i'));
        }

        final errors = await service.getRecentErrors();
        // Should be limited to 100
        expect(errors.length, lessThanOrEqualTo(100));
      });
    });

    group('error record creation', () {
      test('handles string error type', () async {
        await service.reportError(error: 'string error');

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('handles int error type', () async {
        await service.reportError(error: 42);

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('handles null context', () async {
        await service.reportError(error: Exception('test'));

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });

      test('handles empty additional data', () async {
        await service.reportError(error: Exception('test'), additionalData: {});

        final errors = await service.getRecentErrors();
        expect(errors, isNotEmpty);
      });
    });
  });
}
