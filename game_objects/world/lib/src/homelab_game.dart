import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:logging/logging.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_room/game_objects_room.dart';
import 'package:game_objects_character/game_objects_character.dart';
import 'package:game_objects_devices/game_objects_devices.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

import 'gamepad_handler.dart';

/// Projects accepted domain state into one camera-controlled scene.
class HomelabGame extends FlameGame
    with HasKeyboardHandlerComponents, TapCallbacks, MouseMovementDetector {
  static final _log = Logger('HomelabGame');
  final GameBloc gameBloc;
  final WorldBloc worldBloc;
  final CharacterSpriteSheet spriteSheet;
  late final Component _scene;
  late final PlayerComponent _player;

  /// Accepted-state projection, also available while its sprite is loading.
  PlayerComponent get player => _player;
  RoomComponent? _legacyRoom;
  MapEnvironmentComponent? _environment;
  PlacementGhostComponent? _placementGhost;
  final List<DeviceComponent> _devices = [];
  final List<CloudServiceComponent> _services = [];
  final List<DoorComponent> _doors = [];
  final Queue<GridPosition> _route = Queue();
  GridPosition? _pendingStep;
  void Function()? _afterRoute;
  String? _currentRoomId;
  MapDefinition? _definition;
  Rect _bounds = const Rect.fromLTWH(0, 0, 640, 384);
  double _zoomFactor = 1;
  StreamSubscription<GameState>? _subscription;
  bool _removed = false;
  bool _sceneReady = false;

  HomelabGame({
    required this.gameBloc,
    required this.worldBloc,
    this.spriteSheet = GameCharacters.mainMale,
  }) {
    images = Images(prefix: '');
  }

  @override
  Future<void> onLoad() async {
    if (_removed) return;
    await super.onLoad();
    final model = _model;
    _player = PlayerComponent(
      initialPosition:
          model?.playerPosition ?? GameConstants.playerStartPosition,
      spriteSheet: spriteSheet,
    );
    _scene = Component(children: [_player]);
    await world.add(
      FlameBlocProvider<WorldBloc, WorldState>.value(
        value: worldBloc,
        children: [_scene],
      ),
    );
    if (_removed) return;
    _sceneReady = true;
    await add(
      GamepadHandler(
        onDirection: _moveDirection,
        onButtonPressed: _onGamepadButton,
      ),
    );
    if (_removed) return;
    _subscription = gameBloc.stream.listen(
      _onGameStateChanged,
      onError: (Object error, StackTrace trace) {
        _log.severe('Error in game state stream', error, trace);
      },
    );
    _onGameStateChanged(gameBloc.state);
  }

  @override
  void onMount() {
    super.onMount();
    if (_removed) dispose();
  }

  @override
  void onRemove() {
    _removed = true;
    cancelRoute();
    _subscription?.cancel();
    _subscription = null;
    _environment?.removeFromWorld();
    dispose();
    if (!worldBloc.isClosed) worldBloc.add(const WorldReset());
    super.onRemove();
  }

  GameModel? get _model {
    final state = gameBloc.state;
    return state is GameReady ? state.model : null;
  }

  void _onGameStateChanged(GameState state) {
    if (_removed || !_sceneReady) return;
    if (state is! GameReady) {
      cancelRoute();
      return;
    }
    final model = state.model;
    final room = model.currentRoom;
    final changed =
        _currentRoomId != model.currentRoomId || _definition != room.definition;
    if (changed) {
      cancelRoute();
      _currentRoomId = model.currentRoomId;
      _definition = room.definition;
      _environment?.removeFromWorld();
      _environment = null;
      _legacyRoom?.removeFromParent();
      _legacyRoom = null;
      _hideGhost();
      for (final component in [..._devices, ..._services, ..._doors]) {
        component.removeFromParent();
      }
      _devices.clear();
      _services.clear();
      _doors.clear();
      final catalog = gameBloc.mapCatalog;
      if (catalog != null && room.definition != null) {
        final environment = MapEnvironmentComponent(
          catalog: catalog,
          definition: room.definition!,
        );
        _environment = environment;
        unawaited(environment.attachToWorld(_scene));
        _bounds = environment.visualBounds;
      } else {
        _legacyRoom = RoomComponent(
          gridWidth: room.width,
          gridHeight: room.height,
        )..priority = -100000;
        _scene.add(_legacyRoom!);
        _bounds = Rect.fromLTWH(0, 0, room.width * 32, room.height * 32);
      }
      _player.snapTo(model.playerPosition);
      worldBloc.add(
        WorldRoomChanged(
          terminalPosition: room.terminalPosition,
          playerPosition: model.playerPosition,
        ),
      );
      resetCamera();
    } else if (_player.gridPosition != model.playerPosition) {
      _player.moveTo(model.playerPosition);
    }
    if (model.shopOpen || model.placementMode == PlacementMode.placing) {
      cancelRoute();
    }
    if (_pendingStep != null && model.playerPosition != _pendingStep) {
      cancelRoute();
    }
    _syncObjects(room);
    _environment?.setPlacementMode(
      model.placementMode == PlacementMode.placing,
    );
    if (model.placementMode == PlacementMode.placing && _environment == null) {
      _placementGhost ??= PlacementGhostComponent()..priority = 100001;
      if (_placementGhost!.parent == null) _scene.add(_placementGhost!);
      if (model.selectedTemplate != null) {
        _placementGhost!.setTemplate(model.selectedTemplate);
      } else {
        _placementGhost!.setCloudService(model.selectedCloudService);
      }
    } else {
      _hideGhost();
    }
    _updateInteraction(model);
  }

  void _syncObjects(RoomModel room) {
    _devices.removeWhere((component) {
      final keep = room.devices.any((device) => device == component.device);
      if (!keep) component.removeFromParent();
      return !keep;
    });
    for (final device in room.devices) {
      if (!_devices.any((c) => c.device.id == device.id)) {
        final component = DeviceComponent(device: device)
          ..priority = ((device.position.y + device.height) * 32 * 100).round();
        _devices.add(component);
        _scene.add(component);
      }
    }
    _services.removeWhere((component) {
      final keep = room.cloudServices.any(
        (service) => service == component.service,
      );
      if (!keep) component.removeFromParent();
      return !keep;
    });
    for (final service in room.cloudServices) {
      if (!_services.any((c) => c.service.id == service.id)) {
        final component = CloudServiceComponent(service: service)
          ..priority = ((service.position.y + service.height) * 32 * 100)
              .round();
        _services.add(component);
        _scene.add(component);
      }
    }
    if (_environment == null) {
      for (final old in _doors) {
        old.removeFromParent();
      }
      _doors.clear();
      for (final door in room.doors) {
        final component = DoorComponent(
          door: door,
          roomWidth: room.width,
          roomHeight: room.height,
        );
        _doors.add(component);
        _scene.add(component);
      }
    }
  }

  void _hideGhost() {
    _placementGhost?.removeFromParent();
    _placementGhost = null;
  }

  void cancelRoute() {
    _route.clear();
    _pendingStep = null;
    _afterRoute = null;
  }

  void _routeTo(GridPosition target, {void Function()? then}) {
    cancelRoute();
    final model = _model;
    if (model == null ||
        model.shopOpen ||
        model.placementMode != PlacementMode.none) {
      return;
    }
    if (target != model.playerPosition) {
      final path = model.currentRoom.findPath(model.playerPosition, target);
      if (path.isEmpty) return;
      _route.addAll(path);
    }
    _afterRoute = then;
  }

  void _advanceRoute() {
    final model = _model;
    if (model == null ||
        model.shopOpen ||
        model.placementMode != PlacementMode.none ||
        _player.isMoving) {
      return;
    }
    if (_pendingStep != null) {
      if (model.playerPosition != _pendingStep) return;
      _pendingStep = null;
    }
    if (_route.isEmpty) {
      final action = _afterRoute;
      _afterRoute = null;
      action?.call();
      return;
    }
    final step = _route.removeFirst();
    if (!model.currentRoom.canWalk(step) ||
        (step.x - model.playerPosition.x).abs() +
                (step.y - model.playerPosition.y).abs() !=
            1) {
      cancelRoute();
      return;
    }
    _pendingStep = step;
    gameBloc.add(GameMovePlayerTo(step));
  }

  void navigateToRoom(String targetRoomId) {
    final model = _model;
    if (model == null || model.shopOpen) return;
    for (final door in model.currentRoom.doors.where(
      (d) => d.targetRoomId == targetRoomId,
    )) {
      final cell = door.getSpawnPosition(
        model.currentRoom.width,
        model.currentRoom.height,
      );
      if (cell == model.playerPosition ||
          model.currentRoom.findPath(model.playerPosition, cell).isNotEmpty) {
        _routeTo(
          cell,
          then: () {
            final current = _model;
            if (current != null &&
                current.currentRoomId == model.currentRoomId) {
              _enterDoor(door, current);
            }
          },
        );
        return;
      }
    }
  }

  void _enterDoor(DoorModel door, GameModel model) {
    final target = model.getRoomById(door.targetRoomId);
    if (target == null) return;
    final spawn = door.targetSpawnId == null
        ? door.getSpawnPosition(target.width, target.height)
        : target.definition?.spawns[door.targetSpawnId];
    if (spawn == null || !target.canWalk(spawn)) return;
    cancelRoute();
    gameBloc.add(GameEnterRoom(roomId: target.id, spawnPosition: spawn));
  }

  void _updateInteraction(GameModel model) {
    final cell = model.playerPosition;
    for (final door in model.currentRoom.doors) {
      final position = door.getPosition(
        model.currentRoom.width,
        model.currentRoom.height,
      );
      if (cell == position ||
          (cell.x - position.x).abs() + (cell.y - position.y).abs() == 1) {
        worldBloc.add(InteractionAvailable(door.id, InteractionType.door));
        return;
      }
    }
    if (cell == model.currentRoom.terminalPosition ||
        cell.isAdjacentTo(model.currentRoom.terminalPosition)) {
      worldBloc.add(
        const InteractionAvailable(
          GameConstants.terminalEntityId,
          InteractionType.terminal,
        ),
      );
    } else {
      worldBloc.add(const InteractionUnavailable());
    }
  }

  void interact() {
    final model = _model;
    if (model == null || model.shopOpen) return;
    cancelRoute();
    final focus = worldBloc.state;
    if (focus.availableInteraction == InteractionType.terminal) {
      gameBloc.add(const GameToggleShop(isOpen: true));
    }
    if (focus.availableInteraction == InteractionType.door) {
      final door = model.findDoorById(focus.interactableEntityId ?? '');
      if (door != null) _enterDoor(door, model);
    }
  }

  GridPosition _screenCell(Vector2 point) {
    final position = camera.globalToLocal(point);
    return pixelToGrid(position.x, position.y);
  }

  @override
  void onTapUp(TapUpEvent event) {
    final model = _model;
    if (model == null || model.shopOpen) return;
    final cell = _screenCell(event.localPosition);
    if (!model.currentRoom.containsCell(cell)) return;
    if (model.placementMode == PlacementMode.placing) {
      cancelRoute();
      final template = model.selectedTemplate;
      final service = model.selectedCloudService;
      if (template != null &&
          model.currentRoom.canPlaceDevice(
            cell,
            template.width,
            template.height,
          )) {
        gameBloc.add(GamePlaceDevice(cell));
      } else if (service != null &&
          model.currentRoom.canPlaceDevice(
            cell,
            service.width,
            service.height,
          )) {
        gameBloc.add(GamePlaceCloudService(cell));
      }
      return;
    }
    if (cell == model.currentRoom.terminalPosition) {
      if (model.playerPosition.isAdjacentTo(cell)) {
        cancelRoute();
        gameBloc.add(const GameToggleShop(isOpen: true));
      }
      return;
    }
    for (final door in model.currentRoom.doors) {
      if (cell ==
          door.getPosition(model.currentRoom.width, model.currentRoom.height)) {
        navigateToRoom(door.targetRoomId);
        return;
      }
    }
    final device = model.currentRoom.getDeviceAt(cell);
    final service = model.currentRoom.getCloudServiceAt(cell);
    if (device != null || service != null) {
      cancelRoute();
      worldBloc.add(EntitySelected(device?.id ?? service!.id));
      return;
    }
    _routeTo(cell);
  }

  void _moveDirection(Direction direction) {
    cancelRoute();
    final model = _model;
    if (!_sceneReady ||
        model == null ||
        model.shopOpen ||
        model.placementMode != PlacementMode.none) {
      return;
    }
    gameBloc.add(GameMovePlayer(direction));
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final model = _model;
    if (model == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      cancelRoute();
      if (model.placementMode == PlacementMode.placing) {
        gameBloc.add(const GameCancelPlacement());
      } else if (model.shopOpen) {
        gameBloc.add(const GameToggleShop(isOpen: false));
      }
      return KeyEventResult.handled;
    }
    final direction = switch (key) {
      LogicalKeyboardKey.keyW || LogicalKeyboardKey.arrowUp => Direction.up,
      LogicalKeyboardKey.keyS || LogicalKeyboardKey.arrowDown => Direction.down,
      LogicalKeyboardKey.keyA || LogicalKeyboardKey.arrowLeft => Direction.left,
      LogicalKeyboardKey.keyD ||
      LogicalKeyboardKey.arrowRight => Direction.right,
      _ => null,
    };
    if (direction != null) {
      _moveDirection(direction);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      interact();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void _onGamepadButton(GamepadButton button) {
    final model = _model;
    if (model == null) return;
    if (button == GamepadButton.south) interact();
    if (button == GamepadButton.start) {
      cancelRoute();
      gameBloc.add(GameToggleShop(isOpen: !model.shopOpen));
    }
    if (button == GamepadButton.east) {
      cancelRoute();
      if (model.placementMode == PlacementMode.placing) {
        gameBloc.add(const GameCancelPlacement());
      } else if (model.shopOpen) {
        gameBloc.add(const GameToggleShop(isOpen: false));
      }
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    final model = _model;
    if (model == null || model.shopOpen) return;
    final cell = _screenCell(info.eventPosition.widget);
    if (model.currentRoom.containsCell(cell)) {
      worldBloc.add(CellHovered(cell));
    } else {
      worldBloc.add(const CellHoverEnded());
    }
  }

  void zoomIn() {
    _zoomFactor = (_zoomFactor * 1.25).clamp(0.75, 2.5);
    _fitCamera();
  }

  void zoomOut() {
    _zoomFactor = (_zoomFactor / 1.25).clamp(0.75, 2.5);
    _fitCamera();
  }

  void resetCamera() {
    _zoomFactor = 1;
    _fitCamera();
  }

  void _fitCamera() {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(_bounds.center.dx, _bounds.center.dy);
    final fit = math.min(
      math.max(1, size.x - 48) / _bounds.width,
      math.max(1, size.y - 48) / _bounds.height,
    );
    camera.viewfinder.zoom = fit * _zoomFactor;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fitCamera();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_sceneReady || _removed) return;
    _environment?.setActorGroundPosition(_player.groundAnchor);
    final model = _model;
    if (model != null && model.placementMode == PlacementMode.placing) {
      final cell = worldBloc.state.hoveredCell;
      final width =
          model.selectedTemplate?.width ??
          model.selectedCloudService?.width ??
          1;
      final height =
          model.selectedTemplate?.height ??
          model.selectedCloudService?.height ??
          1;
      final valid =
          cell != null && model.currentRoom.canPlaceDevice(cell, width, height);
      _environment?.setPlacementPreview(
        cell,
        valid: valid,
        width: width,
        height: height,
      );
      _placementGhost?.setValid(valid);
      _legacyRoom?.setPlacementValid(valid);
    }
    _advanceRoute();
  }
}
