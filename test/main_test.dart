import 'dart:async';
import 'dart:ui';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('main.dart error handling', () {
    group('ErrorReportingService', () {
      late ErrorReportingService errorService;

      setUp(() {
        // Initialize SharedPreferences mock for testing
        SharedPreferences.setMockInitialValues({});
        errorService = ErrorReportingService();
      });

      test('setupGlobalErrorHandler sets FlutterError.onError', () {
        // Store original handler
        final originalHandler = FlutterError.onError;

        try {
          // Setup global error handler
          errorService.setupGlobalErrorHandler();

          // FlutterError.onError should be set
          expect(FlutterError.onError, isNotNull);
        } finally {
          // Restore original handler
          FlutterError.onError = originalHandler;
        }
      });

      test('setupGlobalErrorHandler sets PlatformDispatcher.onError', () {
        // Store original handler
        final originalHandler = PlatformDispatcher.instance.onError;

        try {
          // Setup global error handler
          errorService.setupGlobalErrorHandler();

          // PlatformDispatcher.instance.onError should be set
          expect(PlatformDispatcher.instance.onError, isNotNull);
        } finally {
          // Restore original handler
          PlatformDispatcher.instance.onError = originalHandler;
        }
      });

      test('reportError creates error record with context', () async {
        // Report an error
        await errorService.reportError(
          error: Exception('Test error'),
          context: 'Unhandled error in root zone',
          level: LogLevel.fatal,
        );

        // Verify error was recorded
        final errors = await errorService.getRecentErrors();
        expect(errors.isNotEmpty, isTrue);
        expect(errors.last['context'], 'Unhandled error in root zone');
        expect(errors.last['level'].toString().toLowerCase(), 'fatal');
      });

      test('reportError includes stack trace when provided', () async {
        final stackTrace = StackTrace.current;

        await errorService.reportError(
          error: Exception('Test error'),
          stackTrace: stackTrace,
          context: 'Test context',
        );

        final errors = await errorService.getRecentErrors();
        expect(errors.isNotEmpty, isTrue);
        expect(errors.last['stack_trace'], contains('main_test.dart'));
      });
    });

    group('runZonedGuarded integration', () {
      test('runZonedGuarded captures errors in nested zones', () async {
        var errorCaptured = false;

        runZonedGuarded(
          () {
            // Simulate an async error
            Future.microtask(() => throw Exception('Async zone error'));
          },
          (error, stackTrace) {
            errorCaptured = true;
            expect(error, isA<Exception>());
          },
        );

        // Wait for microtask to execute
        await Future.delayed(const Duration(milliseconds: 100));
        expect(errorCaptured, isTrue);
      });

      test('runZonedGuarded passes stack trace to handler', () async {
        StackTrace? capturedStack;

        runZonedGuarded(
          () {
            Future.microtask(() => throw Exception('Stack trace test'));
          },
          (error, stackTrace) {
            capturedStack = stackTrace;
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(capturedStack, isNotNull);
      });
    });
  });
}
