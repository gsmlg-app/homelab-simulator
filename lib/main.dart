/// Homelab Simulator - A Flutter/Flame game for simulating homelab infrastructure.
///
/// Entry point for the application, configuring global error handling
/// before launching the main [App] widget.
library;

import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'app.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, configures global error handling via
/// [ErrorReportingService], and runs the app within a guarded zone to
/// capture any unhandled async errors.
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
