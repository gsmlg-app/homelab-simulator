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
            body: InfoPanel(title: 'title', icon: Icons.dns, children: []),
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
              children: [Text('child 1'), Text('child 2')],
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
            body: InfoPanel(title: 'title', icon: Icons.info, children: []),
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
            body: InfoPanel(title: 'title', icon: Icons.info, children: []),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with empty children list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'Empty Panel',
              icon: Icons.warning,
              children: [],
            ),
          ),
        ),
      );

      expect(find.text('EMPTY PANEL'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('renders multiple children in column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'Multi',
              icon: Icons.list,
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
                Text('Item 4'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);
    });

    testWidgets('renders icon with cyan color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(title: 'title', icon: Icons.home, children: []),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(icon.color, Colors.cyan.shade400);
      expect(icon.size, 20);
    });

    testWidgets('title text has correct style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(title: 'styled', icon: Icons.info, children: []),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('STYLED'));
      final style = text.style!;
      expect(style.color, Colors.cyan.shade400);
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.letterSpacing, 1);
    });

    testWidgets('container has border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(title: 'title', icon: Icons.info, children: []),
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
      expect(decoration.border, isNotNull);
    });

    testWidgets('container has correct padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(title: 'title', icon: Icons.info, children: []),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InfoPanel),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.padding, const EdgeInsets.all(16));
    });

    testWidgets('renders nested widget children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'Nested',
              icon: Icons.layers,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star),
                    Text('Nested content'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('NESTED'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Nested content'), findsOneWidget);
    });

    testWidgets('title handles special characters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'test & <panel>',
              icon: Icons.info,
              children: [],
            ),
          ),
        ),
      );

      expect(find.text('TEST & <PANEL>'), findsOneWidget);
    });

    testWidgets('header row contains icon and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoPanel(
              title: 'Header Test',
              icon: Icons.settings,
              children: [],
            ),
          ),
        ),
      );

      // Verify Row contains both icon and text
      final row = find.ancestor(
        of: find.byIcon(Icons.settings),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget);
    });
  });
}
