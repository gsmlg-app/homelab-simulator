import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_shop/game_widgets_shop.dart';

void main() {
  group('DeviceCard', () {
    const serverTemplate = DeviceTemplate(
      id: 'server_basic',
      name: 'Basic Server',
      description: 'A simple rack server',
      type: DeviceType.server,
      cost: 500,
    );

    const routerTemplate = DeviceTemplate(
      id: 'router_basic',
      name: 'Basic Router',
      description: 'Network router',
      type: DeviceType.router,
      cost: 200,
    );

    testWidgets('displays template name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Basic Server'), findsOneWidget);
    });

    testWidgets('displays template description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('A simple rack server'), findsOneWidget);
    });

    testWidgets('displays template cost', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('\$500'), findsOneWidget);
    });

    testWidgets('displays device type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('SERVER'), findsOneWidget);
    });

    testWidgets('displays correct icon for server', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dns), findsOneWidget);
    });

    testWidgets('displays correct icon for router', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: routerTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.router), findsOneWidget);
    });

    testWidgets('is tappable when can afford', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DeviceCard));
      expect(tapped, isTrue);
    });

    testWidgets('is not tappable when cannot afford', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 100, // Not enough
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DeviceCard));
      expect(tapped, isFalse);
    });

    testWidgets('shows green price when can afford', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      final priceContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('\$500'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = priceContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.green.shade800);
    });

    testWidgets('shows red price when cannot afford', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 100, // Not enough
              onTap: () {},
            ),
          ),
        ),
      );

      final priceContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('\$500'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = priceContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.red.shade800);
    });

    testWidgets('has reduced opacity when cannot afford', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 100, // Not enough
              onTap: () {},
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.5);
    });

    testWidgets('has full opacity when can afford', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1.0);
    });
  });
}
