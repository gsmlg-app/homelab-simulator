import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_cloud/app_cloud.dart';
import 'package:gamepads/gamepads.dart' as pads;
import 'package:game_objects_cloud_center/game_objects_cloud_center.dart';

import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_character/game_objects_character.dart';
import 'package:game_objects_devices/game_objects_devices.dart';
import 'package:game_objects_room/game_objects_room.dart';
import 'package:game_objects_world/game_objects_world.dart';
import 'package:mocktail/mocktail.dart';

class _GameBloc extends Mock implements GameBloc {}

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/maps/')) {
      final bytes = await File('../../$key').readAsBytes();
      return ByteData.sublistView(bytes);
    }
    return rootBundle.load(key);
  }
}

Future<void> _pump(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 40));
  }
}

class _Harness {
  final bloc = _GameBloc();
  final worldBloc = WorldBloc();
  int subscriptions = 0;
  int cancellations = 0;
  late final states = StreamController<GameState>.broadcast(
    onListen: () => subscriptions++,
    onCancel: () => cancellations++,
  );
  final accepted = <GridPosition>[];
  late GameModel model;
  late HomelabGame game;
  late MapCatalog catalog;

  _Harness({
    void Function(CloudConsoleModel)? onCloudConsoleOpened,
    void Function()? onCloudPanelCloseRequested,
  }) {
    catalog = MapCatalog.fromJson(
      jsonDecode(File('../../assets/maps/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    model = catalog.createGame();
    when(() => bloc.isClosed).thenReturn(false);
    when(() => bloc.state).thenAnswer((_) => GameReady(model));
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    when(() => bloc.mapCatalog).thenReturn(catalog);
    when(() => bloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.single as GameEvent;
      GameModel next = model;
      if (event is GameMovePlayerTo) {
        next = reduce(model, PlayerMoved(event.position));
      }
      if (event is GameMovePlayer) {
        final delta = switch (event.direction) {
          Direction.up => const GridPosition(0, -1),
          Direction.down => const GridPosition(0, 1),
          Direction.left => const GridPosition(-1, 0),
          Direction.right => const GridPosition(1, 0),
          Direction.none => const GridPosition(0, 0),
        };
        next = reduce(model, PlayerMoved(model.playerPosition + delta));
      }
      if (event is GameEnterRoom) {
        next = reduce(
          model,
          RoomEntered(roomId: event.roomId, spawnPosition: event.spawnPosition),
        );
      }
      if (event is GameToggleShop) {
        next = reduce(model, ShopToggled(event.isOpen ?? !model.shopOpen));
      }
      if (next != model) {
        if (next.currentRoomId == model.currentRoomId &&
            next.playerPosition != model.playerPosition) {
          accepted.add(next.playerPosition);
        }
        publish(next);
      }
    });
    game = HomelabGame(
      gameBloc: bloc,
      worldBloc: worldBloc,
      onCloudConsoleOpened: onCloudConsoleOpened,
      onCloudPanelCloseRequested: onCloudPanelCloseRequested,
    )..images.bundle = _Bundle();
  }
  void publish(GameModel value) {
    model = value;
    states.add(GameReady(model));
  }

  PlayerComponent get player =>
      game.world.descendants().whereType<PlayerComponent>().single;
  Future<void> mount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    await _pump(tester);
    expect(game.isLoaded, isTrue);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, 2);
    await worldBloc.close();
    await states.close();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  Future<void> tap(WidgetTester tester, GridPosition cell) async {
    final point = game.camera.localToGlobal(
      Vector2((cell.x + .5) * 32, (cell.y + .5) * 32),
    );
    await tester.tapAt(Offset(point.x, point.y));
    await tester.pump();
  }
}

void _key(
  HomelabGame game,
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical, {
  bool repeat = false,
}) {
  final event = repeat
      ? KeyRepeatEvent(
          timeStamp: Duration.zero,
          physicalKey: physical,
          logicalKey: logical,
        )
      : KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: physical,
          logicalKey: logical,
        );
  game.onKeyEvent(event, {});
}

Future<void> _button(
  WidgetTester tester,
  String key, {
  String type = 'button',
  double value = 1.0,
}) async {
  await tester.runAsync(() async {
    final reply = Completer<void>();
    tester.binding.channelBuffers.push(
      'xyz.luan/gamepads',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('onGamepadEvent', {
          'gamepadId': 'test',
          'time': 1,
          'type': type,
          'key': key,
          'value': value,
        }),
      ),
      (data) {
        if (data != null) const StandardMethodCodec().decodeEnvelope(data);
        reply.complete();
      },
    );
    await reply.future.timeout(const Duration(seconds: 5));
  });
  await tester.pump();
}

Future<List<int>> _consolePixels(CloudConsoleComponent component) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(
    component.width.ceil(),
    component.height.ceil(),
  );
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final bytes = data.buffer.asUint8List().toList();
  image.dispose();
  picture.dispose();
  return bytes;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const GameMovePlayerTo(GridPosition(0, 0)));
    // Register the process-wide native channel outside a per-test fake-async zone.
    expect(pads.Gamepads.events.isBroadcast, isTrue);
  });
  testWidgets(
    'scene shares World/provider, camera picking routes around furniture and rejects blocked clicks',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      expect(
        h.game.world.descendants().whereType<MapEnvironmentComponent>(),
        hasLength(1),
      );
      expect(h.player.findParent<World>(), same(h.game.world));
      expect(
        h.game.world
            .descendants()
            .whereType<FlameBlocProvider<WorldBloc, WorldState>>(),
        hasLength(1),
      );
      final start = h.model.playerPosition;
      final blocked = h.model.currentRoom.definition!.objects
          .firstWhere(
            (o) => h
                .model
                .currentRoom
                .definition!
                .prefabs[o.prefabId]!
                .blocksMovement,
          )
          .position;
      await h.tap(tester, blocked);
      await _pump(tester, 4);
      expect(h.model.playerPosition, start);
      expect(h.player.gridPosition, start);
      h.game.zoomIn();
      const target = GridPosition(3, 3);
      await h.tap(tester, target);
      for (var frame = 0; frame < 180; frame++) {
        await _pump(tester, 1);
        final occupiedCell = pixelToGrid(
          h.player.position.x + 16,
          h.player.position.y + 16,
        );
        expect(
          h.model.currentRoom.canWalk(occupiedCell),
          isTrue,
          reason: 'interpolated feet must stay in walkable cells',
        );
      }
      expect(h.model.playerPosition, target);
      var previous = start;
      for (final cell in h.accepted) {
        expect((cell.x - previous.x).abs() + (cell.y - previous.y).abs(), 1);
        expect(h.model.currentRoom.canWalk(cell), isTrue);
        previous = cell;
      }
      expect(h.player.position, Vector2(target.x * 32, target.y * 32));
      h.game.resetCamera();
      expect(h.game.camera.viewfinder.position, Vector2(320, 192));
    },
  );
  testWidgets(
    'cancel stops route, reachable portal changes room and named spawn, repeated room changes own one scene',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      await h.tap(tester, const GridPosition(3, 8));
      h.game.cancelRoute();
      await _pump(tester, 50);
      expect(h.model.playerPosition, isNot(const GridPosition(3, 8)));
      h.game.navigateToRoom('operations');
      await _pump(tester, 150);
      expect(h.model.currentRoomId, 'operations');
      expect(
        h.model.playerPosition,
        h.catalog.maps['operations']!.spawns['entry'],
      );
      expect(
        h.player.position,
        Vector2(h.model.playerPosition.x * 32, h.model.playerPosition.y * 32),
      );
      expect(h.worldBloc.state.playerPosition, h.model.playerPosition);
      expect(
        h.game.world
            .descendants()
            .whereType<MapEnvironmentComponent>()
            .single
            .definition
            .width,
        16,
      );
      h.game.navigateToRoom('server-lab');
      await _pump(tester, 150);
      expect(h.model.currentRoomId, 'server-lab');
      expect(
        h.game.world.descendants().whereType<MapEnvironmentComponent>(),
        hasLength(1),
      );
      expect(
        h.game.world
            .descendants()
            .whereType<FlameBlocProvider<WorldBloc, WorldState>>(),
        hasLength(1),
      );
      final before = h.model;
      h.game.navigateToRoom('missing');
      await _pump(tester, 2);
      expect(h.model, before);
    },
  );
  testWidgets(
    'same-ID device/service updates preserve mounted components and refresh visuals',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      const device = DeviceModel(
        id: 'dev',
        templateId: 'server_basic',
        name: 'Server',
        type: DeviceType.server,
        position: GridPosition(3, 8),
      );
      const service = CloudServiceModel(
        id: 'svc',
        name: 'Cloud',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        position: GridPosition(4, 8),
      );
      h.publish(
        h.model.updateRoom(
          h.model.currentRoom.copyWith(
            devices: [device],
            cloudServices: [service],
          ),
        ),
      );
      await _pump(tester, 4);
      final originalDevice = h.game.world
          .descendants()
          .whereType<DeviceComponent>()
          .single;
      final originalService = h.game.world
          .descendants()
          .whereType<CloudServiceComponent>()
          .single;
      final changed = device.copyWith(
        position: const GridPosition(5, 8),
        isRunning: true,
        type: DeviceType.computer,
        width: 2,
        height: 2,
      );
      final changedService = service.copyWith(
        position: const GridPosition(6, 8),
      );
      h.publish(
        h.model.updateRoom(
          h.model.currentRoom.copyWith(
            devices: [changed],
            cloudServices: [changedService],
          ),
        ),
      );
      await _pump(tester, 4);
      expect(
        h.game.world.descendants().whereType<DeviceComponent>().single.device,
        changed,
      );
      expect(
        h.game.world
            .descendants()
            .whereType<CloudServiceComponent>()
            .single
            .service,
        changedService,
      );
      expect(
        h.game.world.descendants().whereType<DeviceComponent>().single,
        same(originalDevice),
      );
      expect(
        h.game.world.descendants().whereType<CloudServiceComponent>().single,
        same(originalService),
      );
      expect(originalDevice.position, Vector2(160, 256));
      expect(originalDevice.size, Vector2(64, 64));
      expect(originalDevice.priority, 32000);
      h.publish(
        h.model.updateRoom(
          h.model.currentRoom.copyWith(devices: [], cloudServices: []),
        ),
      );
      await _pump(tester, 4);
      expect(h.game.world.descendants().whereType<DeviceComponent>(), isEmpty);
      expect(
        h.game.world.descendants().whereType<CloudServiceComponent>(),
        isEmpty,
      );
      expect(
        h.game.world
            .descendants()
            .whereType<FlameBlocProvider<WorldBloc, WorldState>>(),
        hasLength(1),
      );
    },
  );
  testWidgets(
    'rejected keyboard movement leaves visual position unchanged and rapid accepted corners stay cardinal',
    (tester) async {
      final h = _Harness();
      h.model = h.model.copyWith(playerPosition: const GridPosition(1, 1));
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      h.game.onKeyEvent(
        const KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: PhysicalKeyboardKey.arrowLeft,
          logicalKey: LogicalKeyboardKey.arrowLeft,
        ),
        {},
      );
      await _pump(tester, 3);
      expect(h.model.playerPosition, const GridPosition(1, 1));
      expect(h.player.position, Vector2(32, 32));
      for (final cell in [
        const GridPosition(1, 2),
        const GridPosition(1, 3),
        const GridPosition(2, 3),
      ]) {
        h.publish(reduce(h.model, PlayerMoved(cell)));
      }
      for (var frame = 0; frame < 30; frame++) {
        await _pump(tester, 1);
        final point = h.player.position;
        expect(
          (point.x - 32).abs() < 0.01 || (point.y - 96).abs() < 0.01,
          isTrue,
          reason: 'accepted corner steps must never interpolate diagonally',
        );
      }
      expect(h.player.position, Vector2(64, 96));
      expect(h.player.priority, ((96 + 32) * 100).round());
    },
  );
  testWidgets(
    'current legacy room geometry, terminal and doors track accepted room edits',
    (tester) async {
      final h = _Harness();
      const door = DoorModel(
        id: 'exit',
        wallSide: WallSide.right,
        wallPosition: 3,
        targetRoomId: 'other',
      );
      h.model = const GameModel(
        rooms: [
          RoomModel(
            id: 'legacy',
            name: 'Legacy',
            type: RoomType.serverRoom,
            width: 10,
            height: 8,
            doors: [door],
            terminalPosition: GridPosition(2, 2),
          ),
        ],
        currentRoomId: 'legacy',
        playerPosition: GridPosition(1, 1),
      );
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      final originalDoor = h.game.world
          .descendants()
          .whereType<DoorComponent>()
          .single;
      expect(
        h.game.world
            .descendants()
            .whereType<TerminalComponent>()
            .single
            .gridPosition,
        const GridPosition(2, 2),
      );
      final changedDoor = door.copyWith(
        wallSide: WallSide.bottom,
        wallPosition: 4,
      );
      h.publish(
        h.model.updateRoom(
          h.model.currentRoom.copyWith(
            width: 14,
            height: 10,
            terminalPosition: const GridPosition(3, 3),
            doors: [changedDoor],
          ),
        ),
      );
      await _pump(tester, 4);
      expect(
        h.game.world.descendants().whereType<RoomComponent>().single.size,
        Vector2(448, 320),
      );
      expect(h.game.camera.viewfinder.position, Vector2(224, 160));
      expect(
        h.game.world
            .descendants()
            .whereType<TerminalComponent>()
            .single
            .gridPosition,
        const GridPosition(3, 3),
      );
      final updatedDoor = h.game.world
          .descendants()
          .whereType<DoorComponent>()
          .single;
      expect(updatedDoor, same(originalDoor));
      expect(updatedDoor.door, changedDoor);
      expect(updatedDoor.position, Vector2(128, 288));
      h.publish(h.model.updateRoom(h.model.currentRoom.copyWith(doors: [])));
      await _pump(tester, 2);
      expect(h.game.world.descendants().whereType<DoorComponent>(), isEmpty);
      h.publish(
        h.model.updateRoom(h.model.currentRoom.copyWith(doors: [door])),
      );
      await _pump(tester, 2);
      expect(
        h.game.world.descendants().whereType<DoorComponent>().single.position,
        Vector2(416, 96),
      );
    },
  );

  testWidgets(
    'map portal projections synchronize without rebuilding the map scene',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      final environment = h.game.world
          .descendants()
          .whereType<MapEnvironmentComponent>()
          .single;
      final portal = h.game.world
          .descendants()
          .whereType<DoorComponent>()
          .single;
      final changed = portal.door.copyWith(wallPosition: 7);
      const added = DoorModel(
        id: 'new-map-door',
        wallSide: WallSide.left,
        wallPosition: 3,
        targetRoomId: 'operations',
      );
      h.publish(
        h.model.updateRoom(
          h.model.currentRoom.copyWith(doors: [changed, added]),
        ),
      );
      await _pump(tester, 2);
      final doors = h.game.world
          .descendants()
          .whereType<DoorComponent>()
          .toList();
      expect(doors, hasLength(2));
      expect(
        doors.singleWhere((component) => component.door.id == changed.id),
        same(portal),
      );
      expect(portal.gridPosition, const GridPosition(19, 7));
      expect(
        h.game.world.descendants().whereType<MapEnvironmentComponent>().single,
        same(environment),
      );
      h.publish(h.model.updateRoom(h.model.currentRoom.copyWith(doors: [])));
      await _pump(tester, 2);
      expect(h.game.world.descendants().whereType<DoorComponent>(), isEmpty);
      expect(
        h.game.world.descendants().whereType<MapEnvironmentComponent>().single,
        same(environment),
      );
    },
  );

  testWidgets(
    '100 room cycles and 1000 same-ID updates keep mounted nodes and subscriptions bounded',
    (tester) async {
      final h = _Harness();
      const device = DeviceModel(
        id: 'stable',
        templateId: 'server_basic',
        name: 'Server',
        type: DeviceType.server,
        position: GridPosition(3, 3),
      );
      const service = CloudServiceModel(
        id: 'stable-service',
        name: 'Cloud',
        provider: CloudProvider.aws,
        category: ServiceCategory.compute,
        serviceType: 'EC2',
        position: GridPosition(5, 3),
      );
      const first = RoomModel(
        id: 'first',
        name: 'First',
        type: RoomType.serverRoom,
        devices: [device],
        cloudServices: [service],
      );
      const second = RoomModel(
        id: 'second',
        name: 'Second',
        type: RoomType.aws,
      );
      h.model = const GameModel(rooms: [first, second], currentRoomId: 'first');
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      final baselineNodes = h.game.world.descendants().length;
      for (var cycle = 0; cycle < 100; cycle++) {
        h.publish(h.model.copyWith(currentRoomId: 'second'));
        await _pump(tester, 1);
        expect(
          h.game.world.descendants().whereType<DeviceComponent>(),
          isEmpty,
        );
        expect(
          h.game.world.descendants().whereType<CloudServiceComponent>(),
          isEmpty,
        );
        h.publish(h.model.copyWith(currentRoomId: 'first'));
        await _pump(tester, 1);
        expect(h.game.world.descendants().length, baselineNodes);
      }
      final stableDevice = h.game.world
          .descendants()
          .whereType<DeviceComponent>()
          .single;
      final stableService = h.game.world
          .descendants()
          .whereType<CloudServiceComponent>()
          .single;
      for (var index = 0; index < 1000; index++) {
        h.publish(
          h.model.updateRoom(
            h.model.currentRoom.copyWith(
              devices: [
                device.copyWith(isRunning: index.isOdd, name: 'Server $index'),
              ],
              cloudServices: [service.copyWith(name: 'Cloud $index')],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(h.game.world.descendants().length, baselineNodes);
        expect(
          h.game.world.descendants().whereType<DeviceComponent>().single,
          same(stableDevice),
        );
        expect(
          h.game.world.descendants().whereType<CloudServiceComponent>().single,
          same(stableService),
        );
      }
      expect(stableDevice.device.name, 'Server 999');
      expect(stableService.service.name, 'Cloud 999');
      expect(
        h.game.world
            .descendants()
            .whereType<FlameBlocProvider<WorldBloc, WorldState>>(),
        hasLength(1),
      );
      expect(h.subscriptions, 1);
      expect(h.cancellations, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, 2);
      expect(h.states.hasListener, isFalse);
      expect(h.cancellations, 1);
      expect(h.game.children, isEmpty);
    },
  );
  testWidgets(
    'cloud consoles open only on keyboard, gamepad or nearby tap and block scene input until the host closes',
    (tester) async {
      final opened = <CloudConsoleModel>[];
      var closeRequests = 0;
      final h = _Harness(
        onCloudConsoleOpened: opened.add,
        onCloudPanelCloseRequested: () => closeRequests++,
      );
      h.model = installCloudCenter(h.model);
      final center = h.model.getRoomById(CloudCenterIds.room)!;
      final console = center.cloudConsoles.first;
      h.model = h.model.copyWith(
        currentRoomId: center.id,
        playerPosition: console.position + const GridPosition(-1, 0),
      );
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      expect(opened, isEmpty);
      expect(h.worldBloc.state.interactableEntityId, console.id);
      expect(
        h.game.world.descendants().whereType<TerminalComponent>(),
        isEmpty,
      );
      _key(h.game, PhysicalKeyboardKey.keyE, LogicalKeyboardKey.keyE);
      expect(opened, [console]);
      expect(h.game.cloudPanelOpen, isTrue);
      final position = h.model.playerPosition;
      _key(h.game, PhysicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown);
      await _button(tester, 'start');
      await h.tap(tester, position + const GridPosition(0, 1));
      await _pump(tester, 4);
      expect(h.model.playerPosition, position);
      expect(h.model.shopOpen, isFalse);
      _key(h.game, PhysicalKeyboardKey.keyE, LogicalKeyboardKey.keyE);
      expect(opened, hasLength(1));
      _key(h.game, PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape);
      await _button(tester, 'b');
      expect(closeRequests, 2);
      h.game.setCloudPanelOpen(false);
      await _button(tester, 'left x', type: 'analog', value: 1);
      expect(
        h.model.playerPosition,
        position,
        reason: 'held stick remains blocked until neutral',
      );
      await _button(tester, 'left x', type: 'analog', value: 0);
      _key(
        h.game,
        PhysicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        repeat: true,
      );
      await _pump(tester, 2);
      expect(
        h.model.playerPosition,
        position,
        reason: 'held keyboard repeat is discarded across modal close',
      );
      await _button(tester, 'a');
      expect(opened, hasLength(2));
      h.game.setCloudPanelOpen(false);
      await h.tap(tester, console.position);
      expect(opened, hasLength(3));
      h.game.setCloudPanelOpen(false);
      h.publish(h.model.copyWith(playerPosition: const GridPosition(18, 10)));
      await _pump(tester, 2);
      await h.tap(tester, console.position);
      expect(
        opened,
        hasLength(3),
        reason: 'remote taps never auto-route or open a cloud console',
      );
      _key(h.game, PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp);
      await _pump(tester, 2);
      expect(h.model.playerPosition, const GridPosition(18, 9));
      await _button(tester, 'left x', type: 'analog', value: 0);
      await _button(tester, 'left x', type: 'analog', value: 1);
      await _pump(tester, 2);
      expect(h.model.playerPosition, const GridPosition(19, 9));
    },
  );

  testWidgets(
    '100 cloud panel and room cycles plus 1000 summaries keep four console projections and one subscription',
    (tester) async {
      var opened = 0;
      var closed = 0;
      final h = _Harness(
        onCloudConsoleOpened: (_) => opened++,
        onCloudPanelCloseRequested: () => closed++,
      );
      h.model = installCloudCenter(h.model);
      final source = h.model.currentRoom;
      final center = h.model.getRoomById(CloudCenterIds.room)!;
      final adjacent =
          center.cloudConsoles.first.position + const GridPosition(-1, 0);
      h.model = h.model.copyWith(
        currentRoomId: center.id,
        playerPosition: adjacent,
      );
      await h.mount(tester);
      addTearDown(() => h.close(tester));
      final centerNodes = h.game.world.descendants().length;
      for (var cycle = 0; cycle < 100; cycle++) {
        h.game.interact();
        expect(h.game.cloudPanelOpen, isTrue);
        h.publish(
          h.model.copyWith(
            currentRoomId: source.id,
            playerPosition: source.definition!.spawn,
          ),
        );
        await _pump(tester, 1);
        expect(h.game.cloudPanelOpen, isFalse);
        expect(
          h.game.world.descendants().whereType<CloudConsoleComponent>(),
          isEmpty,
        );
        h.publish(
          h.model.copyWith(currentRoomId: center.id, playerPosition: adjacent),
        );
        await _pump(tester, 1);
        expect(h.game.world.descendants().length, centerNodes);
      }
      expect(opened, 100);
      expect(closed, 100);
      final stable = {
        for (final component
            in h.game.world.descendants().whereType<CloudConsoleComponent>())
          component.console.id: component,
      };
      h.game.updateCloudSummaries({
        CloudCenterIds.aws: ConsoleSummary(
          connectionId: 'connection',
          provider: CloudProvider.aws,
          amountLabel: '1',
          budgetState: BudgetState.unknown,
          dataState: DatasetState.waiting,
        ),
      });
      final before = await tester.runAsync(
        () => _consolePixels(stable[CloudCenterIds.aws]!),
      );
      for (var update = 0; update < 1000; update++) {
        h.game.updateCloudSummaries({
          for (final console in center.cloudConsoles)
            console.id: ConsoleSummary(
              connectionId: 'connection',
              provider: console.target is ProviderConsoleTarget
                  ? (console.target as ProviderConsoleTarget).provider
                  : CloudProvider.none,
              amountLabel: '$update.00',
              currency: 'USD',
              start: DateTime.utc(2026, 10, 1),
              end: DateTime.utc(2026, 11, 1),
              budgetState: update == 999
                  ? BudgetState.exceeded
                  : BudgetState.withinBudget,
              dataState: DatasetState.available,
            ),
        });
        await tester.pump(const Duration(milliseconds: 16));
        expect(h.game.world.descendants().length, centerNodes);
        for (final component
            in h.game.world.descendants().whereType<CloudConsoleComponent>()) {
          expect(component, same(stable[component.console.id]));
        }
      }
      final aws = stable[CloudCenterIds.aws]!;
      expect(aws.summary!.amountLabel, '999.00');
      expect(aws.summary!.budgetState, BudgetState.exceeded);
      expect(aws.summary!.dataState, DatasetState.available);
      final after = await tester.runAsync(() => _consolePixels(aws));
      expect(after, isNot(orderedEquals(before!)));
      expect(stable, hasLength(4));
      expect(h.subscriptions, 1);
      expect(h.cancellations, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, 2);
      expect(h.game.children, isEmpty);
      expect(h.cancellations, 1);
      expect(closed, 100);
      h.game.interact();
      h.game.setCloudPanelOpen(true);
      h.game.updateCloudSummaries({});
      expect(opened, 100, reason: 'disposed games never call host callbacks');
    },
  );
}
