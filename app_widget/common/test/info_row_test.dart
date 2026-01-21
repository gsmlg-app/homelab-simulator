import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_widget_common/app_widget_common.dart';

void main() {
  group('InfoRow', () {
    Widget buildSubject({
      String label = 'Label',
      String value = 'Value',
      Color valueColor = Colors.white,
      Color? labelColor,
      double fontSize = 12,
      double verticalPadding = 4,
      bool boldValue = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: InfoRow(
            label: label,
            value: value,
            valueColor: valueColor,
            labelColor: labelColor,
            fontSize: fontSize,
            verticalPadding: verticalPadding,
            boldValue: boldValue,
          ),
        ),
      );
    }

    group('construction', () {
      testWidgets('renders with required parameters', (tester) async {
        await tester.pumpWidget(buildSubject());

        expect(find.text('Label'), findsOneWidget);
        expect(find.text('Value'), findsOneWidget);
      });

      testWidgets('has const constructor', (tester) async {
        const row = InfoRow(label: 'Test', value: 'Test');
        expect(row.label, 'Test');
        expect(row.value, 'Test');
      });
    });

    group('layout', () {
      testWidgets('uses Row with MainAxisAlignment.spaceBetween', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject());

        final row = tester.widget<Row>(find.byType(Row));
        expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      });

      testWidgets('wraps content in Padding', (tester) async {
        await tester.pumpWidget(buildSubject());

        expect(find.byType(Padding), findsOneWidget);
      });

      testWidgets('uses verticalPadding parameter', (tester) async {
        await tester.pumpWidget(buildSubject(verticalPadding: 8));

        final padding = tester.widget<Padding>(find.byType(Padding));
        expect(padding.padding, const EdgeInsets.symmetric(vertical: 8));
      });
    });

    group('label text', () {
      testWidgets('displays label text', (tester) async {
        await tester.pumpWidget(buildSubject(label: 'Custom Label'));

        expect(find.text('Custom Label'), findsOneWidget);
      });

      testWidgets('uses default grey color for label', (tester) async {
        await tester.pumpWidget(buildSubject());

        final labelText = tester.widget<Text>(find.text('Label'));
        expect(labelText.style?.color, Colors.grey.shade400);
      });

      testWidgets('uses custom labelColor when provided', (tester) async {
        await tester.pumpWidget(buildSubject(labelColor: Colors.red));

        final labelText = tester.widget<Text>(find.text('Label'));
        expect(labelText.style?.color, Colors.red);
      });

      testWidgets('uses fontSize parameter', (tester) async {
        await tester.pumpWidget(buildSubject(fontSize: 14));

        final labelText = tester.widget<Text>(find.text('Label'));
        expect(labelText.style?.fontSize, 14);
      });
    });

    group('value text', () {
      testWidgets('displays value text', (tester) async {
        await tester.pumpWidget(buildSubject(value: 'Custom Value'));

        expect(find.text('Custom Value'), findsOneWidget);
      });

      testWidgets('uses valueColor parameter', (tester) async {
        await tester.pumpWidget(buildSubject(valueColor: Colors.green));

        final valueText = tester.widget<Text>(find.text('Value'));
        expect(valueText.style?.color, Colors.green);
      });

      testWidgets('value is bold by default', (tester) async {
        await tester.pumpWidget(buildSubject());

        final valueText = tester.widget<Text>(find.text('Value'));
        expect(valueText.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('value is normal weight when boldValue is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(boldValue: false));

        final valueText = tester.widget<Text>(find.text('Value'));
        expect(valueText.style?.fontWeight, FontWeight.normal);
      });

      testWidgets('uses fontSize parameter', (tester) async {
        await tester.pumpWidget(buildSubject(fontSize: 16));

        final valueText = tester.widget<Text>(find.text('Value'));
        expect(valueText.style?.fontSize, 16);
      });
    });

    group('defaults', () {
      testWidgets('default valueColor is white', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRow(label: 'L', value: 'V'),
            ),
          ),
        );

        final valueText = tester.widget<Text>(find.text('V'));
        expect(valueText.style?.color, Colors.white);
      });

      testWidgets('default fontSize is 12', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRow(label: 'L', value: 'V'),
            ),
          ),
        );

        final labelText = tester.widget<Text>(find.text('L'));
        final valueText = tester.widget<Text>(find.text('V'));
        expect(labelText.style?.fontSize, 12);
        expect(valueText.style?.fontSize, 12);
      });

      testWidgets('default verticalPadding is 4', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRow(label: 'L', value: 'V'),
            ),
          ),
        );

        final padding = tester.widget<Padding>(find.byType(Padding));
        expect(padding.padding, const EdgeInsets.symmetric(vertical: 4));
      });

      testWidgets('default boldValue is true', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRow(label: 'L', value: 'V'),
            ),
          ),
        );

        final valueText = tester.widget<Text>(find.text('V'));
        expect(valueText.style?.fontWeight, FontWeight.bold);
      });
    });

    group('widget properties', () {
      test('is a StatelessWidget', () {
        const row = InfoRow(label: 'L', value: 'V');
        expect(row, isA<StatelessWidget>());
      });

      test('key can be provided', () {
        const key = Key('test-info-row');
        const row = InfoRow(key: key, label: 'L', value: 'V');
        expect(row.key, key);
      });

      test('label property is accessible', () {
        const row = InfoRow(label: 'MyLabel', value: 'V');
        expect(row.label, 'MyLabel');
      });

      test('value property is accessible', () {
        const row = InfoRow(label: 'L', value: 'MyValue');
        expect(row.value, 'MyValue');
      });
    });

    group('edge cases', () {
      testWidgets('handles empty label', (tester) async {
        await tester.pumpWidget(buildSubject(label: ''));

        expect(find.text(''), findsOneWidget);
      });

      testWidgets('handles empty value', (tester) async {
        await tester.pumpWidget(buildSubject(value: ''));

        expect(find.byType(InfoRow), findsOneWidget);
      });

      testWidgets('handles long label', (tester) async {
        await tester.pumpWidget(
          buildSubject(label: 'This is a very long label'),
        );

        expect(find.text('This is a very long label'), findsOneWidget);
      });

      testWidgets('handles long value', (tester) async {
        await tester.pumpWidget(
          buildSubject(value: 'This is a very long value that might wrap'),
        );

        expect(
          find.text('This is a very long value that might wrap'),
          findsOneWidget,
        );
      });

      testWidgets('handles zero verticalPadding', (tester) async {
        await tester.pumpWidget(buildSubject(verticalPadding: 0));

        final padding = tester.widget<Padding>(find.byType(Padding));
        expect(padding.padding, EdgeInsets.zero);
      });

      testWidgets('handles large verticalPadding', (tester) async {
        await tester.pumpWidget(buildSubject(verticalPadding: 100));

        final padding = tester.widget<Padding>(find.byType(Padding));
        expect(padding.padding, const EdgeInsets.symmetric(vertical: 100));
      });

      testWidgets('handles small fontSize', (tester) async {
        await tester.pumpWidget(buildSubject(fontSize: 8));

        final labelText = tester.widget<Text>(find.text('Label'));
        expect(labelText.style?.fontSize, 8);
      });

      testWidgets('handles large fontSize', (tester) async {
        await tester.pumpWidget(buildSubject(fontSize: 24));

        final labelText = tester.widget<Text>(find.text('Label'));
        expect(labelText.style?.fontSize, 24);
      });
    });

    group('color combinations', () {
      testWidgets('can set both label and value colors', (tester) async {
        await tester.pumpWidget(
          buildSubject(labelColor: Colors.blue, valueColor: Colors.green),
        );

        final labelText = tester.widget<Text>(find.text('Label'));
        final valueText = tester.widget<Text>(find.text('Value'));

        expect(labelText.style?.color, Colors.blue);
        expect(valueText.style?.color, Colors.green);
      });

      testWidgets('label and value can have same color', (tester) async {
        await tester.pumpWidget(
          buildSubject(labelColor: Colors.red, valueColor: Colors.red),
        );

        final labelText = tester.widget<Text>(find.text('Label'));
        final valueText = tester.widget<Text>(find.text('Value'));

        expect(labelText.style?.color, Colors.red);
        expect(valueText.style?.color, Colors.red);
      });
    });
  });
}
