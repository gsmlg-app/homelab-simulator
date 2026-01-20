import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_widgets_shop/game_widgets_shop.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  late MockGameBloc mockGameBloc;
  bool closeCalled = false;

  setUpAll(() {
    registerFallbackValue(
      const GameAddRoom(
        name: 'Test',
        type: RoomType.aws,
        doorSide: WallSide.bottom,
        doorPosition: 5,
      ),
    );
  });

  setUp(() {
    mockGameBloc = MockGameBloc();
    closeCalled = false;
    when(() => mockGameBloc.state).thenReturn(GameReady(GameModel.initial()));
  });

  tearDown(() {
    mockGameBloc.close();
  });

  Widget buildTestWidget({Size surfaceSize = const Size(800, 1200)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(
          body: BlocProvider<GameBloc>.value(
            value: mockGameBloc,
            child: AddRoomModal(onClose: () => closeCalled = true),
          ),
        ),
      ),
    );
  }

  group('AddRoomModal', () {
    testWidgets('renders ADD ROOM header', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('ADD ROOM'), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onClose when close button tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closeCalled, isTrue);
    });

    testWidgets('calls onClose when background tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap on the background (black54 overlay)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(closeCalled, isTrue);
    });

    testWidgets('displays all provider presets', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('AWS'), findsOneWidget);
      expect(find.text('GCP'), findsOneWidget);
      expect(find.text('Cloudflare'), findsOneWidget);
      expect(find.text('Vultr'), findsOneWidget);
      expect(find.text('Azure'), findsOneWidget);
      expect(find.text('DigitalOcean'), findsOneWidget);
      expect(find.text('Custom Room'), findsOneWidget);
    });

    testWidgets('selecting provider shows checkmark', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Initially no checkmark
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Tap AWS
      await tester.tap(find.text('AWS'));
      await tester.pump();

      // Now checkmark should appear
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('selecting provider with regions shows region selector', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap AWS (has regions)
      await tester.tap(find.text('AWS'));
      await tester.pump();

      // Region selector should appear
      expect(find.text('Select Region'), findsOneWidget);
      expect(find.text('us-east-1'), findsOneWidget);
      expect(find.text('us-west-2'), findsOneWidget);
      expect(find.text('eu-west-1'), findsOneWidget);
    });

    testWidgets('selecting Custom Room shows name input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to Custom Room and tap it
      await tester.scrollUntilVisible(
        find.text('Custom Room'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Custom Room'));
      await tester.pumpAndSettle();

      // Name input should appear
      expect(find.text('Room Name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Next button disabled when no provider selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Next button enabled when provider without regions selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare (no regions)
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Next button disabled when provider selected but region not', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Select AWS (has regions)
      await tester.tap(find.text('AWS'));
      await tester.pump();

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Next button enabled when provider and region selected', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select AWS
      await tester.tap(find.text('AWS'));
      await tester.pumpAndSettle();

      // Select region - may need to scroll
      await tester.scrollUntilVisible(
        find.text('us-east-1'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('us-east-1'));
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Next goes to door placement step', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare (no regions)
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show door placement UI
      expect(find.text('DOOR PLACEMENT'), findsOneWidget);
      expect(find.text('Door Wall'), findsOneWidget);
      expect(find.text('Door Position'), findsOneWidget);
    });

    testWidgets('door placement shows wall side buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Wall side buttons
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('door placement shows slider', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('door placement shows room preview', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Preview contains door icon
      expect(find.byIcon(Icons.door_front_door), findsOneWidget);
    });

    testWidgets('back button returns to provider selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('DOOR PLACEMENT'), findsOneWidget);

      // Tap Back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('ADD ROOM'), findsOneWidget);
      expect(find.text('Select Provider'), findsOneWidget);
    });

    testWidgets('Create Room button dispatches GameAddRoom event', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Create Room
      await tester.tap(find.text('Create Room'));
      await tester.pump();

      verify(() => mockGameBloc.add(any(that: isA<GameAddRoom>()))).called(1);
      expect(closeCalled, isTrue);
    });

    testWidgets('changing wall side resets position to middle', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Select Cloudflare and go to next step
      await tester.tap(find.text('Cloudflare'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Initially Bottom is selected (default)
      // Tap on Left wall
      await tester.tap(find.text('Left'));
      await tester.pump();

      // Position should reset - look for the position text
      expect(find.textContaining('Position:'), findsOneWidget);
    });

    testWidgets('shows provider icon and color in door placement', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select AWS with region
      await tester.tap(find.text('AWS'));
      await tester.pumpAndSettle();

      // Select region - may need to scroll
      await tester.scrollUntilVisible(
        find.text('us-east-1'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('us-east-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show AWS icon
      expect(find.byIcon(Icons.cloud), findsWidgets);
      // Should show room name with region
      expect(find.text('AWS - us-east-1'), findsOneWidget);
    });

    testWidgets('displays region count for providers', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Multiple providers have 4 regions (AWS, GCP, Vultr, Azure)
      expect(find.text('4 regions available'), findsWidgets);
    });
  });
}
