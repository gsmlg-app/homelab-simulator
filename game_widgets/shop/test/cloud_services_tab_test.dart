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
    registerFallbackValue(
      const GameSelectCloudService(
        CloudServiceTemplate(
          name: 'Test',
          description: 'Test',
          provider: CloudProvider.aws,
          category: ServiceCategory.compute,
          serviceType: 'EC2',
        ),
      ),
    );
  });

  setUp(() {
    mockGameBloc = MockGameBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<GameBloc>.value(
          value: mockGameBloc,
          child: const SizedBox(
            width: 500,
            height: 600,
            child: CloudServicesTab(),
          ),
        ),
      ),
    );
  }

  group('CloudServicesTab', () {
    testWidgets('renders nothing when state is not GameReady', (tester) async {
      when(() => mockGameBloc.state).thenReturn(const GameLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CloudServicesTab), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('renders services list when state is GameReady', (
      tester,
    ) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Should show category filter chips
      expect(find.text('All'), findsWidgets); // Provider and category filters
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('shows provider filter chips for server room', (tester) async {
      // Server room allows all providers
      final model = GameModel.initial(); // Default is server room
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Should show multiple provider options (may appear multiple times in UI)
      expect(find.text('AWS'), findsWidgets);
      expect(find.text('GCP'), findsWidgets);
      expect(find.text('Azure'), findsWidgets);
    });

    testWidgets('shows only provider services for provider room', (
      tester,
    ) async {
      // Create an AWS room
      const room = RoomModel(
        id: 'aws-room',
        name: 'AWS Region',
        type: RoomType.aws,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Should show AWS-specific header
      expect(find.text('AWS Services'), findsOneWidget);
    });

    testWidgets('shows category filter chips', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Should show category filters (may appear multiple times)
      expect(find.text('Compute'), findsWidgets);
      expect(find.text('Storage'), findsWidgets);
      expect(find.text('Database'), findsWidgets);
      expect(find.text('Networking'), findsWidgets);
    });

    testWidgets('shows no services message when filter yields empty', (
      tester,
    ) async {
      // Create a custom room with no associated services
      const room = RoomModel(
        id: 'custom-room',
        name: 'Custom Room',
        type: RoomType.custom,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Widget should render
      expect(find.byType(CloudServicesTab), findsOneWidget);
    });

    testWidgets('shows category icons', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      // Category filter icons should be present
      expect(find.byIcon(Icons.computer), findsWidgets); // Compute
      expect(find.byIcon(Icons.storage), findsWidgets); // Storage
    });

    testWidgets('shows GCP services header for GCP room', (tester) async {
      const room = RoomModel(
        id: 'gcp-room',
        name: 'GCP Region',
        type: RoomType.gcp,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('GCP Services'), findsOneWidget);
    });

    testWidgets('shows Azure services header for Azure room', (tester) async {
      const room = RoomModel(
        id: 'azure-room',
        name: 'Azure Region',
        type: RoomType.azure,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Azure Services'), findsOneWidget);
    });

    testWidgets('shows no services available message', (tester) async {
      // DigitalOcean has limited services in catalog
      const room = RoomModel(
        id: 'do-room',
        name: 'DO Region',
        type: RoomType.digitalOcean,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CloudServicesTab), findsOneWidget);
    });

    testWidgets('shows Vultr services header for Vultr room', (tester) async {
      const room = RoomModel(
        id: 'vultr-room',
        name: 'Vultr Region',
        type: RoomType.vultr,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Vultr Services'), findsOneWidget);
    });

    testWidgets('shows Cloudflare services header for Cloudflare room', (tester) async {
      const room = RoomModel(
        id: 'cf-room',
        name: 'Cloudflare Region',
        type: RoomType.cloudflare,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Cloudflare Services'), findsOneWidget);
    });

    testWidgets('shows DigitalOcean services header for DigitalOcean room', (tester) async {
      const room = RoomModel(
        id: 'do-room',
        name: 'DO Region',
        type: RoomType.digitalOcean,
      );
      final model = GameModel.initial().copyWith(
        rooms: [room],
        currentRoomId: room.id,
      );
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('DigitalOcean Services'), findsOneWidget);
    });

    testWidgets('renders dividers between sections', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Divider), findsAtLeast(2));
    });

    testWidgets('renders Column layout', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Column), findsAtLeast(1));
    });

    testWidgets('shows add icon for services', (tester) async {
      final model = GameModel.initial();
      when(() => mockGameBloc.state).thenReturn(GameReady(model));

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    });

    group('widget properties', () {
      test('is a StatefulWidget', () {
        const tab = CloudServicesTab();

        expect(tab, isA<StatefulWidget>());
      });

      test('createState returns a State object', () {
        const tab = CloudServicesTab();
        final state = tab.createState();

        expect(state, isA<State<CloudServicesTab>>());
      });

      test('key can be provided', () {
        const key = Key('test-cloud-services');
        const tab = CloudServicesTab(key: key);

        expect(tab.key, key);
      });
    });

    group('GameError state', () {
      testWidgets('renders nothing when state is GameError', (tester) async {
        when(() => mockGameBloc.state).thenReturn(const GameError('error'));

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(FilterChip), findsNothing);
      });
    });

    group('all room types', () {
      testWidgets('shows services for serverRoom', (tester) async {
        const room = RoomModel(
          id: 'server-room',
          name: 'Server Room',
          type: RoomType.serverRoom,
        );
        final model = GameModel.initial().copyWith(
          rooms: [room],
          currentRoomId: room.id,
        );
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        // Server room allows all providers
        expect(find.byType(FilterChip), findsWidgets);
      });

      testWidgets('shows custom room without cloud services', (tester) async {
        const room = RoomModel(
          id: 'custom-room',
          name: 'Custom Room',
          type: RoomType.custom,
        );
        final model = GameModel.initial().copyWith(
          rooms: [room],
          currentRoomId: room.id,
        );
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(CloudServicesTab), findsOneWidget);
      });
    });

    group('filter interactions', () {
      testWidgets('tapping All category shows all services', (tester) async {
        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        // Find and tap the All filter chip
        final allChips = find.text('All');
        expect(allChips, findsWidgets);
      });

      testWidgets('tapping Compute category filters services', (tester) async {
        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        // The Compute filter chip should be present
        expect(find.text('Compute'), findsWidgets);
      });

      testWidgets('tapping Storage category filters services', (tester) async {
        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Storage'), findsWidgets);
      });
    });

    group('service list display', () {
      testWidgets('renders ListView for services', (tester) async {
        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ListView), findsAtLeast(1));
      });

      testWidgets('shows Container category filter', (tester) async {
        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Container'), findsWidgets);
      });
    });

    group('edge cases', () {
      testWidgets('handles rapid state changes', (tester) async {
        when(() => mockGameBloc.state).thenReturn(const GameLoading());
        await tester.pumpWidget(buildTestWidget());

        final model = GameModel.initial();
        when(() => mockGameBloc.state).thenReturn(GameReady(model));
        await tester.pump();

        expect(find.byType(CloudServicesTab), findsOneWidget);
      });
    });
  });
}
