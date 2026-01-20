import 'package:flutter_test/flutter_test.dart';
import 'package:app_logging/app_logging.dart';

void main() {
  group('ApiLoggingInterceptor', () {
    late ApiLoggingInterceptor interceptor;

    setUp(() {
      interceptor = ApiLoggingInterceptor();
      // Initialize the underlying logger
      AppLogger().initialize(level: LogLevel.verbose);
    });

    group('logRequest', () {
      test('logs basic request', () {
        // Should not throw
        interceptor.logRequest(
          method: 'GET',
          url: 'https://api.example.com/users',
        );
      });

      test('logs request with headers', () {
        interceptor.logRequest(
          method: 'POST',
          url: 'https://api.example.com/users',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer token',
          },
        );
      });

      test('logs request with body', () {
        interceptor.logRequest(
          method: 'POST',
          url: 'https://api.example.com/users',
          body: {'name': 'Test User', 'email': 'test@example.com'},
        );
      });

      test('logs request with tag', () {
        interceptor.logRequest(
          method: 'GET',
          url: 'https://api.example.com/users',
          tag: 'UserService',
        );
      });

      test('logs request with all parameters', () {
        interceptor.logRequest(
          method: 'PUT',
          url: 'https://api.example.com/users/1',
          headers: {'Content-Type': 'application/json'},
          body: {'name': 'Updated Name'},
          tag: 'UserService',
        );
      });
    });

    group('logResponse', () {
      test('logs successful response', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
        );
      });

      test('logs response with body', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
          body: {'users': []},
        );
      });

      test('logs response with headers', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      test('logs response with response time', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
          responseTimeMs: 150,
        );
      });

      test('logs response with tag', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 200,
          tag: 'UserService',
        );
      });

      test('logs 201 created response', () {
        interceptor.logResponse(
          method: 'POST',
          url: 'https://api.example.com/users',
          statusCode: 201,
        );
      });

      test('logs 400 bad request as warning', () {
        interceptor.logResponse(
          method: 'POST',
          url: 'https://api.example.com/users',
          statusCode: 400,
        );
      });

      test('logs 404 not found as warning', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users/999',
          statusCode: 404,
        );
      });

      test('logs 500 server error as warning', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/users',
          statusCode: 500,
        );
      });

      test('logs 3xx response as info', () {
        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/redirect',
          statusCode: 301,
        );
      });
    });

    group('logError', () {
      test('logs basic error', () {
        interceptor.logError(
          method: 'GET',
          url: 'https://api.example.com/users',
          error: Exception('Connection timeout'),
        );
      });

      test('logs error with stack trace', () {
        interceptor.logError(
          method: 'GET',
          url: 'https://api.example.com/users',
          error: Exception('Network error'),
          stackTrace: StackTrace.current,
        );
      });

      test('logs error with request body', () {
        interceptor.logError(
          method: 'POST',
          url: 'https://api.example.com/users',
          error: Exception('Validation failed'),
          requestBody: {'name': 'Test'},
        );
      });

      test('logs error with tag', () {
        interceptor.logError(
          method: 'GET',
          url: 'https://api.example.com/users',
          error: Exception('Error'),
          tag: 'UserService',
        );
      });
    });

    group('logPerformance', () {
      test('logs normal performance', () {
        interceptor.logPerformance(
          method: 'GET',
          url: 'https://api.example.com/users',
          durationMs: 100,
        );
      });

      test('logs slow performance (>1000ms)', () {
        interceptor.logPerformance(
          method: 'GET',
          url: 'https://api.example.com/users',
          durationMs: 2000,
        );
      });

      test('logs very slow performance (>5000ms)', () {
        interceptor.logPerformance(
          method: 'GET',
          url: 'https://api.example.com/users',
          durationMs: 6000,
        );
      });

      test('logs performance with tag', () {
        interceptor.logPerformance(
          method: 'GET',
          url: 'https://api.example.com/users',
          durationMs: 100,
          tag: 'UserService',
        );
      });
    });

    group('logConnectivity', () {
      test('logs connected state', () {
        interceptor.logConnectivity(isConnected: true);
      });

      test('logs disconnected state', () {
        interceptor.logConnectivity(isConnected: false);
      });

      test('logs connected with network type', () {
        interceptor.logConnectivity(isConnected: true, networkType: 'wifi');
      });

      test('logs connected with mobile network type', () {
        interceptor.logConnectivity(isConnected: true, networkType: '4G');
      });
    });

    group('logRateLimit', () {
      test('logs rate limit', () {
        interceptor.logRateLimit(
          method: 'GET',
          url: 'https://api.example.com/users',
          retryAfter: 60,
        );
      });

      test('logs rate limit with different retry time', () {
        interceptor.logRateLimit(
          method: 'POST',
          url: 'https://api.example.com/messages',
          retryAfter: 300,
        );
      });
    });

    group('logAuth', () {
      test('logs successful login', () {
        interceptor.logAuth(action: 'login', success: true);
      });

      test('logs successful login with userId', () {
        interceptor.logAuth(action: 'login', success: true, userId: 'user123');
      });

      test('logs failed login', () {
        interceptor.logAuth(action: 'login', success: false);
      });

      test('logs failed login with error', () {
        interceptor.logAuth(
          action: 'login',
          success: false,
          error: 'Invalid credentials',
        );
      });

      test('logs logout', () {
        interceptor.logAuth(action: 'logout', success: true, userId: 'user123');
      });

      test('logs token refresh', () {
        interceptor.logAuth(action: 'token_refresh', success: true);
      });
    });

    group('logValidation', () {
      test('logs validation errors', () {
        interceptor.logValidation(
          endpoint: '/api/users',
          data: {'name': '', 'email': 'invalid'},
          errors: ['Name is required', 'Email format is invalid'],
        );
      });

      test('logs single validation error', () {
        interceptor.logValidation(
          endpoint: '/api/users',
          data: {'name': 'Test'},
          errors: ['Email is required'],
        );
      });
    });

    group('body truncation', () {
      test('handles large request body', () {
        final largeBody = <String, String>{};
        for (var i = 0; i < 100; i++) {
          largeBody['key$i'] = 'value' * 100;
        }

        interceptor.logRequest(
          method: 'POST',
          url: 'https://api.example.com/large',
          body: largeBody,
        );
      });

      test('handles large response body', () {
        final largeBody = <String, String>{};
        for (var i = 0; i < 100; i++) {
          largeBody['key$i'] = 'value' * 100;
        }

        interceptor.logResponse(
          method: 'GET',
          url: 'https://api.example.com/large',
          statusCode: 200,
          body: largeBody,
        );
      });
    });
  });
}
