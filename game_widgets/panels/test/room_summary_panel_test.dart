import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_widgets_panels/game_widgets_panels.dart';

void main() {
  group('RoomSummaryPanel', () {
    late RoomModel serverRoom;
    late RoomModel awsRoom;
    late RoomModel roomWithDevices;
    late RoomModel roomWithCloudServices;

    setUp(() {
      serverRoom = const RoomModel(
        id: 'room-1',
        name: 'Server Room',
        type: RoomType.serverRoom,
        width: 20,
        height: 15,
      );

      awsRoom = const RoomModel(
        id: 'room-2',
        name: 'us-east-1',
        type: RoomType.aws,
        width: 20,
        height: 15,
        regionCode: 'us-east-1',
      );

      roomWithDevices = serverRoom.copyWith(
        devices: const [
          DeviceModel(
            id: 'dev-1',
            templateId: 'server_basic',
            name: 'Server 1',
            type: DeviceType.server,
            position: GridPosition(5, 5),
          ),
          DeviceModel(
            id: 'dev-2',
            templateId: 'server_basic',
            name: 'Server 2',
            type: DeviceType.server,
            position: GridPosition(6, 5),
          ),
          DeviceModel(
            id: 'dev-3',
            templateId: 'router_basic',
            name: 'Router',
            type: DeviceType.router,
            position: GridPosition(7, 5),
          ),
        ],
      );

      roomWithCloudServices = awsRoom.copyWith(
        cloudServices: const [
          CloudServiceModel(
            id: 'svc-1',
            name: 'EC2 Instance',
            provider: CloudProvider.aws,
            category: ServiceCategory.compute,
            serviceType: 'EC2',
            position: GridPosition(5, 5),
          ),
          CloudServiceModel(
            id: 'svc-2',
            name: 'S3 Bucket',
            provider: CloudProvider.aws,
            category: ServiceCategory.storage,
            serviceType: 'S3',
            position: GridPosition(6, 5),
          ),
        ],
      );
    });

    testWidgets('displays room name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: serverRoom)),
        ),
      );

      expect(find.text('SERVER ROOM'), findsOneWidget);
    });

    testWidgets('displays room type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: serverRoom)),
        ),
      );

      expect(find.text('Server Room'), findsOneWidget);
    });

    testWidgets('displays room size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: serverRoom)),
        ),
      );

      expect(find.text('20 × 15'), findsOneWidget);
    });

    testWidgets('displays region code when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: awsRoom)),
        ),
      );

      expect(find.text('us-east-1'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state for room without objects', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: serverRoom)),
        ),
      );

      expect(find.text('No objects placed'), findsOneWidget);
    });

    testWidgets('displays total object count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: roomWithDevices)),
        ),
      );

      // Total count badge should show 3
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('displays device section when devices present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: roomWithDevices)),
        ),
      );

      expect(find.text('Devices'), findsOneWidget);
    });

    testWidgets('displays cloud services section when services present', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: roomWithCloudServices)),
        ),
      );

      expect(find.text('Cloud Services'), findsOneWidget);
    });

    testWidgets('shows expand button when objects present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomSummaryPanel(
              room: roomWithDevices,
              onToggleExpand: () {},
            ),
          ),
        ),
      );

      expect(find.text('Show details'), findsOneWidget);
    });

    testWidgets('shows collapse button when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomSummaryPanel(
              room: roomWithDevices,
              expanded: true,
              onToggleExpand: () {},
            ),
          ),
        ),
      );

      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('calls onToggleExpand when tapped', (tester) async {
      var toggleCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomSummaryPanel(
              room: roomWithDevices,
              onToggleExpand: () => toggleCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show details'));
      expect(toggleCalled, isTrue);
    });

    testWidgets('does not show expand button without onToggleExpand callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: roomWithDevices)),
        ),
      );

      expect(find.text('Show details'), findsNothing);
    });

    testWidgets('displays correct icon for server room', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: serverRoom)),
        ),
      );

      expect(find.byIcon(Icons.dns), findsOneWidget);
    });

    testWidgets('displays correct icon for AWS room', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: awsRoom)),
        ),
      );

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('displays door count when doors present', (tester) async {
      final roomWithDoors = serverRoom.copyWith(
        doors: const [
          DoorModel(
            id: 'door-1',
            targetRoomId: 'room-2',
            wallSide: WallSide.right,
            wallPosition: 5,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomSummaryPanel(room: roomWithDoors)),
        ),
      );

      expect(find.text('Doors'), findsOneWidget);
    });

    group('expanded mode', () {
      testWidgets('shows device type breakdown when expanded', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoomSummaryPanel(
                room: roomWithDevices,
                expanded: true,
                onToggleExpand: () {},
              ),
            ),
          ),
        );

        expect(find.text('Server'), findsOneWidget);
        expect(find.text('Router'), findsOneWidget);
      });

      testWidgets('shows cloud service provider breakdown when expanded', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoomSummaryPanel(
                room: roomWithCloudServices,
                expanded: true,
                onToggleExpand: () {},
              ),
            ),
          ),
        );

        // AWS appears in both type display and provider breakdown
        expect(find.text('AWS'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows category breakdown under provider when expanded', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoomSummaryPanel(
                room: roomWithCloudServices,
                expanded: true,
                onToggleExpand: () {},
              ),
            ),
          ),
        );

        expect(find.text('Compute'), findsOneWidget);
        expect(find.text('Storage'), findsOneWidget);
      });
    });
  });
}
