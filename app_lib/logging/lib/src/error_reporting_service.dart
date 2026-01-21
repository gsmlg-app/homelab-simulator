import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';
import 'log_level.dart';

class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  final AppLogger _logger = AppLogger();
  final logging.Logger _systemLogger = logging.Logger('ErrorReporting');

  static const String _errorLogKey = 'error_logs';
  static const int _maxStoredErrors = 100;

  Future<void> reportError({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    LogLevel level = LogLevel.error,
    Map<String, dynamic>? additionalData,
    bool sendToBackend = false,
  }) async {
    final errorRecord = _createErrorRecord(
      error: error,
      stackTrace: stackTrace,
      context: context,
      level: level,
      additionalData: additionalData,
    );

    _logger.e('Error: ${errorRecord['message']}', error, stackTrace);

    await _storeError(errorRecord);

    if (sendToBackend) {
      await _sendToBackend(errorRecord);
    }
  }

  Future<void> reportException({
    required Exception exception,
    StackTrace? stackTrace,
    String? context,
    LogLevel level = LogLevel.error,
    Map<String, dynamic>? additionalData,
  }) async {
    await reportError(
      error: exception,
      stackTrace: stackTrace,
      context: context,
      level: level,
      additionalData: additionalData,
    );
  }

  Future<void> reportFlutterError({
    required FlutterErrorDetails details,
    String? context,
    LogLevel level = LogLevel.error,
  }) async {
    await reportError(
      error: details.exception,
      stackTrace: details.stack,
      context: context ?? 'Flutter Error',
      level: level,
      additionalData: {
        'library': details.library,
        'context': details.context?.toString(),
        'silent': details.silent,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecentErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorData = prefs.getStringList(_errorLogKey) ?? [];

      return errorData
          .map((json) => _decodeErrorRecord(json))
          .where((error) => error != null)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      _systemLogger.warning('Failed to load error logs: $e');
      return [];
    }
  }

  Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
      _systemLogger.info('Error logs cleared');
    } catch (e) {
      _systemLogger.warning('Failed to clear error logs: $e');
    }
  }

  Map<String, dynamic> _createErrorRecord({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    required LogLevel level,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'message': error.toString(),
      'error_type': error.runtimeType.toString(),
      'context': context,
      'stack_trace': stackTrace?.toString() ?? StackTrace.current.toString(),
      'additional_data': additionalData ?? {},
      'app_version': appVersion,
      'platform': platformName,
    };
  }

  /// App version - can be overridden via [setAppVersion] for testing or
  /// after reading from package_info_plus.
  static String appVersion = '1.0.0';

  /// Sets the app version (typically called after reading package_info).
  static void setAppVersion(String version) {
    appVersion = version;
  }

  /// Platform name derived from runtime.
  static String get platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
      if (Platform.isFuchsia) return 'fuchsia';
    } catch (_) {
      // Platform not available (e.g., in tests)
    }
    return 'unknown';
  }

  Future<void> _storeError(Map<String, dynamic> errorRecord) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingErrors = prefs.getStringList(_errorLogKey) ?? [];

      final json = _encodeErrorRecord(errorRecord);
      existingErrors.add(json);

      // Keep only the most recent errors
      if (existingErrors.length > _maxStoredErrors) {
        existingErrors.removeRange(0, existingErrors.length - _maxStoredErrors);
      }

      await prefs.setStringList(_errorLogKey, existingErrors);
    } catch (e) {
      _systemLogger.warning('Failed to store error: $e');
    }
  }

  /// Backend error reporting handler. Set this to implement actual backend
  /// integration (e.g., Sentry, Crashlytics, custom endpoint).
  ///
  /// Example:
  /// ```dart
  /// ErrorReportingService.backendHandler = (record) async {
  ///   await http.post(Uri.parse('https://api.example.com/errors'),
  ///     body: jsonEncode(record));
  /// };
  /// ```
  static Future<void> Function(Map<String, dynamic> errorRecord)?
  backendHandler;

  Future<void> _sendToBackend(Map<String, dynamic> errorRecord) async {
    try {
      _systemLogger.info('Sending error to backend: ${errorRecord['message']}');

      if (backendHandler != null) {
        await backendHandler!(errorRecord);
        _systemLogger.info('Error sent to backend successfully');
      } else {
        _systemLogger.info(
          'No backend handler configured, error logged locally only',
        );
      }
    } catch (e) {
      _systemLogger.warning('Failed to send error to backend: $e');
    }
  }

  String _encodeErrorRecord(Map<String, dynamic> record) {
    // Convert additional_data values to JSON-safe types
    final safeRecord = Map<String, dynamic>.from(record);
    if (safeRecord['additional_data'] is Map) {
      safeRecord['additional_data'] = _sanitizeForJson(
        safeRecord['additional_data'] as Map<String, dynamic>,
      );
    }
    return jsonEncode(safeRecord);
  }

  Map<String, dynamic> _sanitizeForJson(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == null || value is String || value is num || value is bool) {
        return MapEntry(key, value);
      } else if (value is Map) {
        return MapEntry(
          key,
          _sanitizeForJson(Map<String, dynamic>.from(value)),
        );
      } else if (value is List) {
        return MapEntry(key, value.map((e) => e?.toString()).toList());
      } else {
        return MapEntry(key, value.toString());
      }
    });
  }

  Map<String, dynamic>? _decodeErrorRecord(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      // Handle legacy format (pre-JSON records)
      return {'raw': jsonStr, 'legacy': true};
    }
  }

  /// Export handler for error logs. Set this to implement actual export
  /// functionality (e.g., file sharing, email, clipboard).
  ///
  /// Example:
  /// ```dart
  /// ErrorReportingService.exportHandler = (errors) async {
  ///   final file = File('errors.json');
  ///   await file.writeAsString(jsonEncode(errors));
  ///   await Share.shareFile(file.path);
  /// };
  /// ```
  static Future<void> Function(List<Map<String, dynamic>> errors)?
  exportHandler;

  Future<void> exportErrorLogs() async {
    final errors = await getRecentErrors();
    _systemLogger.info('Exporting error logs: ${errors.length} errors');

    if (exportHandler != null) {
      await exportHandler!(errors);
      _systemLogger.info('Error logs exported successfully');
    } else {
      _systemLogger.info('No export handler configured');
    }
  }

  void setupGlobalErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      reportFlutterError(details: details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        error: error,
        stackTrace: stack,
        context: 'Unhandled platform error',
        level: LogLevel.fatal,
      );
      return true;
    };
  }
}
