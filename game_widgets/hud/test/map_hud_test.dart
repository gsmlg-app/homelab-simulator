import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_widgets_hud/game_widgets_hud.dart';
import 'package:mocktail/mocktail.dart';

class _GameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  testWidgets('connected-room menu and touch interaction dispatch callbacks', (
    tester,
  ) async {
    final bloc = _GameBloc();
    const model = GameModel(
      currentRoomId: 'lab',
      rooms: [
        RoomModel(
          id: 'lab',
          name: 'Laboratory',
          doors: [
            DoorModel(
              id: 'exit',
              targetRoomId: 'ops',
              wallSide: WallSide.right,
              wallPosition: 3,
            ),
          ],
        ),
        RoomModel(id: 'ops', name: 'Operations'),
        RoomModel(id: 'unconnected', name: 'Unconnected'),
      ],
    );
    when(() => bloc.state).thenReturn(const GameReady(model));
    String? destination;
    var interactions = 0;
    var panelOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GameBloc>.value(
          value: bloc,
          child: Scaffold(
            body: HudOverlay(
              currentInteraction: InteractionType.terminal,
              onNavigate: (id) => destination = id,
              onInteract: () => interactions++,
              onPanelOpened: () => panelOpens++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open shop'));
    expect(interactions, 1);
    await tester.tap(find.byTooltip('Connected rooms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(panelOpens, 1);
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Unconnected'), findsNothing);
    await tester.tap(find.text('Operations'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(destination, 'ops');
    await tester.pumpWidget(const SizedBox.shrink());
    await bloc.close();
  });
  for (final size in [
    const Size(1280, 800),
    const Size(800, 600),
    const Size(390, 640),
    const Size(480, 400),
  ]) {
    testWidgets(
      'map controls and details work at $size without blocking scene',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bloc = _GameBloc();
        when(() => bloc.state).thenReturn(GameReady(GameModel.initial()));
        var sceneTaps = 0;
        var zooms = 0;
        var panelOpens = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<GameBloc>.value(
                value: bloc,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => sceneTaps++,
                      ),
                    ),
                    Positioned.fill(
                      child: HudOverlay(
                        onZoomIn: () => zooms++,
                        onPanelOpened: () => panelOpens++,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tapAt(Offset(size.width / 2, size.height / 2));
        expect(sceneTaps, 1);
        await tester.tap(find.byTooltip('Zoom in'));
        expect(zooms, 1);
        expect(sceneTaps, 1);
        await tester.tap(find.byTooltip('Room details'));
        await tester.pump();
        expect(find.text('Room details'), findsOneWidget);
        expect(panelOpens, 1);
        await tester.tap(find.byTooltip('Close details'));
        await tester.pump();
        expect(find.text('Room details'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await bloc.close();
      },
    );
  }
}
