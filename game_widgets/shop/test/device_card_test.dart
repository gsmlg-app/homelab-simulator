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
        find
            .ancestor(of: find.text('\$500'), matching: find.byType(Container))
            .first,
      );

      final decoration = priceContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.green800);
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
        find
            .ancestor(of: find.text('\$500'), matching: find.byType(Container))
            .first,
      );

      final decoration = priceContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.red800);
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

    testWidgets('can afford with exact credits', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: serverTemplate,
              currentCredits: 500, // Exact cost
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DeviceCard));
      expect(tapped, isTrue);

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1.0);
    });

    testWidgets('uses Card widget with dark background', (tester) async {
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

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, AppColors.grey900);
    });

    testWidgets('uses InkWell for tap effect', (tester) async {
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

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('displays switch device icon', (tester) async {
      const switchTemplate = DeviceTemplate(
        id: 'switch_basic',
        name: 'Basic Switch',
        description: 'Network switch',
        type: DeviceType.switch_,
        cost: 300,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: switchTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.hub), findsOneWidget);
    });

    testWidgets('displays NAS device icon', (tester) async {
      const nasTemplate = DeviceTemplate(
        id: 'nas_basic',
        name: 'Basic NAS',
        description: 'Network attached storage',
        type: DeviceType.nas,
        cost: 400,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: nasTemplate,
              currentCredits: 1000,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('displays ROUTER type text for router', (tester) async {
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

      expect(find.text('ROUTER'), findsOneWidget);
    });

    testWidgets('contains Column layout', (tester) async {
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

      expect(find.byType(Column), findsAtLeast(1));
    });

    testWidgets('contains Row layout for header', (tester) async {
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

      expect(find.byType(Row), findsAtLeast(1));
    });

    testWidgets('displays zero cost device', (tester) async {
      const freeTemplate = DeviceTemplate(
        id: 'free_item',
        name: 'Free Item',
        description: 'A free device',
        type: DeviceType.server,
        cost: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(
              template: freeTemplate,
              currentCredits: 0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('\$0'), findsOneWidget);
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1.0); // Can afford $0 with $0 credits
    });
  });
}
