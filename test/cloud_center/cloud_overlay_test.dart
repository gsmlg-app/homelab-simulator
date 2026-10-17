import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_widgets_cloud_center/game_widgets_cloud_center.dart';
import 'package:homelab_simulator/cloud_center/cloud_center_overlay.dart';
import 'package:homelab_simulator/cloud_center/cloud_center_session.dart';

void main() {
  testWidgets(
    '100 actual overlay cycles release panels and stop UI callbacks',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = jsonDecode(
        File('docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      var summaries = 0;
      var backgroundTaps = 0;
      final session = CloudCenterSession(
        database: AppDatabase.forTesting(),
        loadDemo: () async => fixture,
        onClose: () {},
        onSummaries: (_) => summaries++,
      );
      await tester.runAsync(() => session.configure(mode: CloudMode.demo));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => backgroundTaps++,
                    child: const ColoredBox(color: Colors.red),
                  ),
                ),
                Positioned.fill(child: CloudCenterOverlay(session: session)),
              ],
            ),
          ),
        ),
      );
      const target = CloudConsoleModel(
        id: 'aws',
        roomId: 'cloud',
        position: GridPosition(3, 3),
        target: ProviderConsoleTarget(CloudProvider.aws),
      );
      final cubit = session.cubit;
      for (var cycle = 0; cycle < 100; cycle++) {
        await tester.runAsync(() => session.open(target));
        await tester.pumpAndSettle();
        expect(identical(session.cubit, cubit), isTrue);
        expect(find.byType(CloudCenterPanel), findsOneWidget);
        expect(find.text('DEMO · Synthetic data'), findsOneWidget);
        await tester.tapAt(const Offset(5, 600));
        expect(backgroundTaps, cycle);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(session.isOpen, isFalse);
        expect(find.byType(CloudCenterPanel), findsNothing);
        await tester.tapAt(const Offset(5, 600));
        expect(backgroundTaps, cycle + 1);
      }
      final afterClose = summaries;
      await tester.pump(const Duration(minutes: 2));
      expect(summaries, afterClose);
      await tester.runAsync(session.signOut);
      expect(cubit!.isClosed, isTrue);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      final afterDispose = summaries;
      await tester.pump(const Duration(minutes: 2));
      expect(summaries, afterDispose);
      expect(tester.takeException(), isNull);
    },
  );
}
