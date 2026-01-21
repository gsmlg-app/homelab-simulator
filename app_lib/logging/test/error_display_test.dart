import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_logging/app_logging.dart';

void main() {
  group('ErrorSeverity', () {
    test('has 4 severity levels', () {
      expect(ErrorSeverity.values.length, 4);
    });

    test('has low severity', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.low));
    });

    test('has medium severity', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.medium));
    });

    test('has high severity', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.high));
    });

    test('has critical severity', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.critical));
    });
  });

  group('ErrorDisplay', () {
    group('showError with low severity', () {
      testWidgets('shows snackbar with message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Low severity error',
                    severity: ErrorSeverity.low,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('Low severity error'), findsOneWidget);
      });

      testWidgets('shows DISMISS action when no retry provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Test error',
                    severity: ErrorSeverity.low,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('DISMISS'), findsOneWidget);
      });

      testWidgets('shows RETRY action when callback provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Test error',
                    severity: ErrorSeverity.low,
                    onRetry: () {},
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('RETRY'), findsOneWidget);
      });
    });

    group('showError with medium severity', () {
      testWidgets('shows snackbar with message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Medium severity error',
                    severity: ErrorSeverity.medium,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('Medium severity error'), findsOneWidget);
      });
    });

    group('showError with high severity', () {
      testWidgets('shows dialog with Error title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'High severity error',
                    severity: ErrorSeverity.high,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);
        expect(find.text('High severity error'), findsOneWidget);
      });

      testWidgets('shows OK button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Test error',
                    severity: ErrorSeverity.high,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('shows RETRY button when callback provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Test error',
                    severity: ErrorSeverity.high,
                    onRetry: () {},
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('RETRY'), findsOneWidget);
      });

      testWidgets('closes dialog when OK is tapped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Test error',
                    severity: ErrorSeverity.high,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();
        expect(find.text('Test error'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Test error'), findsNothing);
      });
    });

    group('showError with critical severity', () {
      testWidgets('shows dialog with Critical Error title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Critical severity error',
                    severity: ErrorSeverity.critical,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Critical Error'), findsOneWidget);
        expect(find.text('Critical severity error'), findsOneWidget);
      });

      testWidgets('shows error icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Critical error',
                    severity: ErrorSeverity.critical,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('shows restart message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Critical error',
                    severity: ErrorSeverity.critical,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(
          find.text('The app needs to restart to recover.'),
          findsOneWidget,
        );
      });

      testWidgets('shows RESTART APP button when callback provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Critical error',
                    severity: ErrorSeverity.critical,
                    onRetry: () {},
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('RESTART APP'), findsOneWidget);
      });

      testWidgets('calls onRetry when RESTART APP is tapped', (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Critical error',
                    severity: ErrorSeverity.critical,
                    onRetry: () => retryCalled = true,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RESTART APP'));
        await tester.pump();

        expect(retryCalled, isTrue);
      });
    });

    group('default severity', () {
      testWidgets('uses medium severity by default', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () =>
                      ErrorDisplay.showError(context, 'Default severity error'),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        // Medium severity shows snackbar, not dialog
        expect(find.text('Default severity error'), findsOneWidget);
        expect(find.text('Error'), findsNothing); // No dialog title
      });
    });

    group('retry callback behavior', () {
      testWidgets('shows RETRY button when onRetry provided for low severity', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Error',
                    severity: ErrorSeverity.low,
                    onRetry: () {},
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('RETRY'), findsOneWidget);
      });

      testWidgets('calls onRetry when RETRY tapped in high severity', (
        tester,
      ) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    'Error',
                    severity: ErrorSeverity.high,
                    onRetry: () => retryCalled = true,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RETRY'));
        await tester.pump();

        expect(retryCalled, isTrue);
      });
    });

    group('error message edge cases', () {
      testWidgets('handles empty error message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    '',
                    severity: ErrorSeverity.low,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('handles long error message', (tester) async {
        final longMessage = 'x' * 200;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorDisplay.showError(
                    context,
                    longMessage,
                    severity: ErrorSeverity.low,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.textContaining('x' * 50), findsOneWidget);
      });
    });
  });

  group('ErrorSeverity ordering', () {
    test('severity indices are sequential', () {
      expect(ErrorSeverity.low.index, 0);
      expect(ErrorSeverity.medium.index, 1);
      expect(ErrorSeverity.high.index, 2);
      expect(ErrorSeverity.critical.index, 3);
    });
  });
}
