import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final errorService = ErrorReportingService();
  errorService.setupGlobalErrorHandler();

  runZonedGuarded(
    () => runApp(const App()),
    (error, stackTrace) {
      errorService.reportError(
        error: error,
        stackTrace: stackTrace,
        context: 'Unhandled error in root zone',
        level: LogLevel.fatal,
      );
    },
  );
}
