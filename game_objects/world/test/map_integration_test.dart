import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  final states = StreamController<GameState>.broadcast();
  final accepted = <GridPosition>[];
  late GameModel model;
  late HomelabGame game;
  late MapCatalog catalog;

  _Harness() {
    catalog = MapCatalog.fromJson(
      jsonDecode(File('../../assets/maps/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    model = catalog.createGame();
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
    game = HomelabGame(gameBloc: bloc, worldBloc: worldBloc)
      ..images.bundle = _Bundle();
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

void main() {
  setUpAll(
    () => registerFallbackValue(const GameMovePlayerTo(GridPosition(0, 0))),
  );
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
    'same-ID device/service updates replace visual models and remove complete owned components',
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
      final changed = device.copyWith(
        position: const GridPosition(5, 8),
        isRunning: true,
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
}
