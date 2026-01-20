import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_widgets_panels/game_widgets_panels.dart';

void main() {
  group('InfoPanel', () {
    testWidgets('renders title in uppercase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'test title',
              icon: Icons.info,
              children: [Text('child')],
            ),
          ),
        ),
      );

      expect(find.text('TEST TITLE'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'title',
              icon: Icons.dns,
              children: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dns), findsOneWidget);
    });

    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'title',
              icon: Icons.info,
              children: [
                Text('child 1'),
                Text('child 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('child 1'), findsOneWidget);
      expect(find.text('child 2'), findsOneWidget);
    });

    testWidgets('has dark background styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'title',
              icon: Icons.info,
              children: [],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InfoPanel),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.black87);
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('renders divider after header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'title',
              icon: Icons.info,
              children: [],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
