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

  setUpAll(() {
    registerFallbackValue(const GameToggleShop(isOpen: false));
    registerFallbackValue(
      const GameSelectTemplate(
        DeviceTemplate(
          id: 'test',
          name: 'Test',
          description: 'Test',
          type: DeviceType.server,
          cost: 100,
        ),
      ),
    );
  });

  setUp(() {
    mockGameBloc = MockGameBloc();
  });

  tearDown(() {
    mockGameBloc.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<GameBloc>.value(
          value: mockGameBloc,
          child: const ShopModal(),
        ),
      ),
    );
  }

  group('ShopModal', () {
    testWidgets('renders nothing when state is GameLoading', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ShopModal), findsOneWidget);
      expect(find.text('TERMINAL'), findsNothing);
    });

    testWidgets('renders nothing when shop is closed', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: false);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('TERMINAL'), findsNothing);
    });

    testWidgets('renders shop content when shop is open', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('TERMINAL'), findsOneWidget);
    });

    testWidgets('displays credits in header', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true, credits: 1500);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('\$1500'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button dispatches GameToggleShop false', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      verify(() => mockGameBloc.add(const GameToggleShop(isOpen: false))).called(1);
    });

    testWidgets('tapping background closes shop', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Tap on the background overlay (outside modal)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      verify(() => mockGameBloc.add(const GameToggleShop(isOpen: false))).called(1);
    });

    testWidgets('displays three tabs', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Rooms'), findsOneWidget);
    });

    testWidgets('displays tab icons', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.devices), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byIcon(Icons.meeting_room), findsOneWidget);
    });

    testWidgets('Devices tab shows device templates', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Should show device cards from defaultDeviceTemplates
      expect(find.byType(DeviceCard), findsWidgets);
    });

    testWidgets('tapping device card dispatches GameSelectTemplate', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true, credits: 10000);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Find and tap the first device card
      final deviceCards = find.byType(DeviceCard);
      expect(deviceCards, findsWidgets);

      await tester.tap(deviceCards.first);
      await tester.pump();

      verify(() => mockGameBloc.add(any(that: isA<GameSelectTemplate>()))).called(1);
    });

    testWidgets('Rooms tab shows current room info', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      // Should show current room
      expect(find.textContaining('Current:'), findsOneWidget);
    });

    testWidgets('Rooms tab shows Add New Room button', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Room'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
    });

    testWidgets('tapping Add New Room opens AddRoomModal', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      // Tap Add New Room
      await tester.tap(find.text('Add New Room'));
      await tester.pumpAndSettle();

      // AddRoomModal should appear
      expect(find.text('ADD ROOM'), findsOneWidget);
      expect(find.text('Select Provider'), findsOneWidget);
    });

    testWidgets('shows child rooms when available', (tester) async {
      // Create a model with a child room
      const parentRoom = RoomModel(
        id: 'parent',
        name: 'Parent Room',
        type: RoomType.serverRoom,
      );
      const childRoom = RoomModel(
        id: 'child',
        name: 'Child Room',
        type: RoomType.aws,
        parentId: 'parent',
      );
      final model = GameModel.initial().copyWith(
        shopOpen: true,
        rooms: [parentRoom, childRoom],
        currentRoomId: parentRoom.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      // Should show child rooms section
      expect(find.text('Child Rooms (1)'), findsOneWidget);
      expect(find.text('Child Room'), findsOneWidget);
    });

    testWidgets('shows parent room link when in child room', (tester) async {
      // Create a model where current room has a parent
      const parentRoom = RoomModel(
        id: 'parent',
        name: 'Parent Room',
        type: RoomType.serverRoom,
      );
      const childRoom = RoomModel(
        id: 'child',
        name: 'Child Room',
        type: RoomType.aws,
        parentId: 'parent',
      );
      final model = GameModel.initial().copyWith(
        shopOpen: true,
        rooms: [parentRoom, childRoom],
        currentRoomId: childRoom.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      // Should show parent room section
      expect(find.text('Parent Room'), findsWidgets); // Both label and name
    });

    testWidgets('shows store icon in header', (tester) async {
      final model = GameModel.initial().copyWith(shopOpen: true);
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.store), findsOneWidget);
    });

    testWidgets('displays room type icon correctly', (tester) async {
      const room = RoomModel(
        id: 'aws-room',
        name: 'AWS Room',
        type: RoomType.aws,
      );
      final model = GameModel.initial().copyWith(
        shopOpen: true,
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Switch to Rooms tab
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();

      // AWS icon
      expect(find.byIcon(Icons.cloud), findsWidgets);
    });
  });
}
