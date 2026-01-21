import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CrashReportingWidget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CrashReportingWidget(child: Text('Child Widget')),
        ),
      );

      expect(find.text('Child Widget'), findsOneWidget);
    });

    testWidgets('renders with showErrorScreen true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CrashReportingWidget(
            showErrorScreen: true,
            child: Text('Child'),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('renders with showErrorScreen false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CrashReportingWidget(
            showErrorScreen: false,
            child: Text('Child'),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('renders with custom errorScreenBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CrashReportingWidget(
            errorScreenBuilder: (details) => const Text('Custom Error'),
            child: const Text('Child'),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });
  });

  group('ErrorScreen', () {
    testWidgets('renders error icon', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders error title', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      expect(find.text('Oops! Something went wrong'), findsOneWidget);
    });

    testWidgets('renders error description', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      expect(
        find.text("We're sorry, but an unexpected error occurred."),
        findsOneWidget,
      );
    });

    testWidgets('renders retry button', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders report button', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      expect(find.text('Report Error'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button pressed', (tester) async {
      bool retryCalled = false;
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(
            errorDetails: details,
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('calls onReport when report button pressed', (tester) async {
      bool reportCalled = false;
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(
            errorDetails: details,
            onReport: () => reportCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pump();

      expect(reportCalled, isTrue);
    });

    testWidgets('shows report dialog when no onReport provided', (
      tester,
    ) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      expect(find.text('Report Error'), findsWidgets);
      expect(find.text('Error details:'), findsOneWidget);
    });

    testWidgets('can cancel report dialog', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Error details:'), findsNothing);
    });

    testWidgets('can send report from dialog', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ErrorScreen(errorDetails: details)),
        ),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Report'));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.text('Error report submitted'), findsOneWidget);
    });

    testWidgets('shows exception string in dialog', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('Detailed error message'),
      );

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Detailed error message'), findsOneWidget);
    });
  });

  group('ErrorBoundary', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: Text('Bounded Child'))),
      );

      expect(find.text('Bounded Child'), findsOneWidget);
    });

    testWidgets('renders with custom errorBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            errorBuilder: (details) => const Text('Custom Boundary Error'),
            child: const Text('Bounded Child'),
          ),
        ),
      );

      expect(find.text('Bounded Child'), findsOneWidget);
    });

    testWidgets('renders nested ErrorBoundary widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: ErrorBoundary(child: Text('Nested Child')),
          ),
        ),
      );

      expect(find.text('Nested Child'), findsOneWidget);
    });
  });

  group('CrashReportingWidget widget properties', () {
    test('is a StatefulWidget', () {
      const widget = CrashReportingWidget(child: Text('Child'));
      expect(widget, isA<StatefulWidget>());
    });

    test('key can be provided', () {
      const key = Key('test-crash-widget');
      const widget = CrashReportingWidget(key: key, child: Text('Child'));
      expect(widget.key, key);
    });

    test('child property is accessible', () {
      const child = Text('TestChild');
      const widget = CrashReportingWidget(child: child);
      expect(widget.child, child);
    });

    test('showErrorScreen default is true', () {
      const widget = CrashReportingWidget(child: Text('Child'));
      expect(widget.showErrorScreen, isTrue);
    });
  });

  group('ErrorScreen widget properties', () {
    test('is a StatelessWidget', () {
      final details = FlutterErrorDetails(exception: Exception('Test'));
      final screen = ErrorScreen(errorDetails: details);
      expect(screen, isA<StatelessWidget>());
    });

    test('key can be provided', () {
      const key = Key('test-error-screen');
      final details = FlutterErrorDetails(exception: Exception('Test'));
      final screen = ErrorScreen(key: key, errorDetails: details);
      expect(screen.key, key);
    });

    test('errorDetails property is accessible', () {
      final details = FlutterErrorDetails(exception: Exception('TestError'));
      final screen = ErrorScreen(errorDetails: details);
      expect(screen.errorDetails, details);
    });
  });

  group('ErrorBoundary widget properties', () {
    test('is a StatelessWidget', () {
      const widget = ErrorBoundary(child: Text('Child'));
      expect(widget, isA<StatelessWidget>());
    });

    test('key can be provided', () {
      const key = Key('test-error-boundary');
      const widget = ErrorBoundary(key: key, child: Text('Child'));
      expect(widget.key, key);
    });

    test('child property is accessible', () {
      const child = Text('TestChild');
      const widget = ErrorBoundary(child: child);
      expect(widget.child, child);
    });
  });

  group('ErrorScreen styling', () {
    testWidgets('error icon is red shade', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red[700]);
    });

    testWidgets('error icon is size 64', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('Test error'));

      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: details)),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 64);
    });
  });
}
