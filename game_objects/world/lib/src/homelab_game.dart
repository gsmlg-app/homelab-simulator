import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:app_cloud/app_cloud.dart';
import 'package:game_objects_cloud_center/game_objects_cloud_center.dart';

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
  final void Function(CloudConsoleModel)? onCloudConsoleOpened;
  final void Function()? onCloudPanelCloseRequested;
  bool _cloudPanelOpen = false;
  bool get cloudPanelOpen => _cloudPanelOpen;
  bool _ignoreKeyRepeats = false;
  GameMode? _currentGameMode;
  GamepadHandler? _gamepadHandler;
  final Map<String, CloudConsoleComponent> _consoles = {};
  Map<String, ConsoleSummary> _cloudSummaries = {};
  bool get _inputBlocked =>
      _cloudPanelOpen || (_model?.cloudPanelOpen ?? false);
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
    this.onCloudConsoleOpened,
    this.onCloudPanelCloseRequested,
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
    _gamepadHandler = GamepadHandler(
      onDirection: _moveDirection,
      onButtonPressed: _onGamepadButton,
    );
    await add(_gamepadHandler!);
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
    _cloudPanelOpen = false;
    if (!gameBloc.isClosed) gameBloc.add(const GameSetCloudPanelOpen(false));
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
      _closeCloudForSceneChange();
      cancelRoute();
      return;
    }
    final model = state.model;
    final room = model.currentRoom;
    if (_currentGameMode != null && _currentGameMode != model.gameMode) {
      _closeCloudForSceneChange();
    }
    _currentGameMode = model.gameMode;
    final changed =
        _currentRoomId != model.currentRoomId || _definition != room.definition;
    if (changed) {
      _closeCloudForSceneChange();
      cancelRoute();
      _currentRoomId = model.currentRoomId;
      _definition = room.definition;
      _environment?.removeFromWorld();
      _environment = null;
      _legacyRoom?.removeFromParent();
      _legacyRoom = null;
      _hideGhost();
      for (final component in [
        ..._devices,
        ..._services,
        ..._doors,
        ..._consoles.values,
      ]) {
        component.removeFromParent();
      }
      _devices.clear();
      _services.clear();
      _doors.clear();
      _consoles.clear();
      final catalog = gameBloc.mapCatalog;
      if (catalog != null && room.definition != null) {
        final environment = MapEnvironmentComponent(
          catalog: catalog,
          definition: room.definition!,
        );
        _environment = environment;
        unawaited(environment.attachToWorld(_scene));
        _bounds = environment.visualBounds;
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
    if (_inputBlocked ||
        model.shopOpen ||
        model.placementMode == PlacementMode.placing) {
      cancelRoute();
    }
    if (_pendingStep != null && model.playerPosition != _pendingStep) {
      cancelRoute();
    }
    _syncLegacyRoom(room, model.playerPosition);
    _syncObjects(room);
    _environment?.setPlacementMode(
      !_inputBlocked && model.placementMode == PlacementMode.placing,
    );
    if (!_inputBlocked &&
        model.placementMode == PlacementMode.placing &&
        _environment == null) {
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

  void _syncLegacyRoom(RoomModel room, GridPosition playerPosition) {
    if (_environment != null) return;
    final current = _legacyRoom;
    if (current != null &&
        current.gridWidth == room.width &&
        current.gridHeight == room.height &&
        current.terminalPosition == room.terminalPosition &&
        current.showTerminal == (room.type != RoomType.cloudCenter)) {
      return;
    }
    current?.removeFromParent();
    _legacyRoom = RoomComponent(
      gridWidth: room.width,
      gridHeight: room.height,
      terminalPosition: room.terminalPosition,
      showTerminal: room.type != RoomType.cloudCenter,
    )..priority = -100000;
    _scene.add(_legacyRoom!);
    _bounds = Rect.fromLTWH(
      0,
      0,
      room.width * GameConstants.tileSize,
      room.height * GameConstants.tileSize,
    );
    worldBloc.add(
      WorldRoomChanged(
        terminalPosition: room.terminalPosition,
        playerPosition: playerPosition,
      ),
    );
    _fitCamera();
  }

  void _syncObjects(RoomModel room) {
    final consoles = {
      for (final console in room.cloudConsoles) console.id: console,
    };
    for (final id
        in _consoles.keys.where((id) => !consoles.containsKey(id)).toList()) {
      _consoles.remove(id)!.removeFromParent();
    }
    for (final console in consoles.values) {
      final existing = _consoles[console.id];
      if (existing != null) {
        existing.updateConsole(console);
      } else {
        final component = CloudConsoleComponent(
          console: console,
          summary: _cloudSummaries[console.id],
        );
        _consoles[console.id] = component;
        _scene.add(component);
      }
    }
    final devices = {for (final device in room.devices) device.id: device};
    _devices.removeWhere((component) {
      final keep = devices.containsKey(component.device.id);
      if (!keep) component.removeFromParent();
      return !keep;
    });
    final mountedDevices = {
      for (final component in _devices) component.device.id: component,
    };
    for (final device in devices.values) {
      final existing = mountedDevices[device.id];
      if (existing != null) {
        existing.updateDevice(device);
      } else {
        final component = DeviceComponent(device: device);
        _devices.add(component);
        _scene.add(component);
      }
    }
    final services = {
      for (final service in room.cloudServices) service.id: service,
    };
    _services.removeWhere((component) {
      final keep = services.containsKey(component.service.id);
      if (!keep) component.removeFromParent();
      return !keep;
    });
    final mountedServices = {
      for (final component in _services) component.service.id: component,
    };
    for (final service in services.values) {
      final existing = mountedServices[service.id];
      if (existing != null) {
        existing.updateService(service);
      } else {
        final component = CloudServiceComponent(service: service);
        _services.add(component);
        _scene.add(component);
      }
    }
    final doors = {for (final door in room.doors) door.id: door};
    _doors.removeWhere((component) {
      final keep = doors.containsKey(component.door.id);
      if (!keep) component.removeFromParent();
      return !keep;
    });
    final mountedDoors = {
      for (final component in _doors) component.door.id: component,
    };
    for (final door in doors.values) {
      final existing = mountedDoors[door.id];
      if (existing != null) {
        existing.updateDoor(
          door,
          roomWidth: room.width,
          roomHeight: room.height,
        );
      } else {
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
    if (_inputBlocked ||
        model == null ||
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
    if (_inputBlocked ||
        model == null ||
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
    if (_removed || _inputBlocked || model == null || model.shopOpen) return;
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
    final spawn =
        door.targetSpawnPosition ??
        (door.targetSpawnId == null
            ? door.getSpawnPosition(target.width, target.height)
            : target.definition?.spawns[door.targetSpawnId]);
    if (spawn == null || !target.canWalk(spawn)) return;
    cancelRoute();
    gameBloc.add(GameEnterRoom(roomId: target.id, spawnPosition: spawn));
  }

  void _updateInteraction(GameModel model) {
    final target = _inputBlocked
        ? null
        : selectInteractionTarget(model.currentRoom, model.playerPosition);
    worldBloc.add(
      WorldInteractionProjected(
        playerPosition: model.playerPosition,
        entityId: target?.id,
        type: target?.type ?? InteractionType.none,
      ),
    );
  }

  void interact() {
    final model = _model;
    if (_removed ||
        _inputBlocked ||
        model == null ||
        model.shopOpen ||
        model.placementMode != PlacementMode.none) {
      return;
    }
    cancelRoute();
    final focus = selectInteractionTarget(
      model.currentRoom,
      model.playerPosition,
    );
    if (focus?.type == InteractionType.cloudConsole) {
      final console = model.currentRoom.cloudConsoles
          .where((console) => console.id == focus!.id)
          .firstOrNull;
      if (console != null && onCloudConsoleOpened != null) {
        setCloudPanelOpen(true);
        onCloudConsoleOpened!(console);
      }
    } else if (focus?.type == InteractionType.terminal) {
      gameBloc.add(const GameToggleShop(isOpen: true));
    } else if (focus?.type == InteractionType.door) {
      final door = model.findDoorById(focus!.id);
      if (door != null) _enterDoor(door, model);
    }
  }

  /// The host controls one Flutter panel; collectors are independent of it.
  void setCloudPanelOpen(bool isOpen) {
    if (_removed ||
        (_cloudPanelOpen == isOpen &&
            (_model?.cloudPanelOpen ?? false) == isOpen)) {
      return;
    }
    _cloudPanelOpen = isOpen;
    _ignoreKeyRepeats = true;
    cancelRoute();
    _gamepadHandler?.resetInput();
    _hideGhost();
    _environment?.setPlacementMode(false);
    if (!gameBloc.isClosed) gameBloc.add(GameSetCloudPanelOpen(isOpen));
    final model = _model;
    if (_sceneReady && model != null) _updateInteraction(model);
  }

  /// Keys are stable console IDs. No amount aggregation occurs in Flame.
  void updateCloudSummaries(Map<String, ConsoleSummary> summaries) {
    if (_removed) return;
    _cloudSummaries = Map.unmodifiable(summaries);
    for (final entry in _consoles.entries) {
      entry.value.updateSummary(_cloudSummaries[entry.key]);
    }
  }

  void _closeCloudForSceneChange() {
    if (!_cloudPanelOpen) return;
    setCloudPanelOpen(false);
    onCloudPanelCloseRequested?.call();
  }

  GridPosition _screenCell(Vector2 point) {
    final position = camera.globalToLocal(point);
    return pixelToGrid(position.x, position.y);
  }

  @override
  void onTapUp(TapUpEvent event) {
    final model = _model;
    if (_removed || _inputBlocked || model == null || model.shopOpen) return;
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
    for (final console in model.currentRoom.cloudConsoles) {
      if (console.occupiesCell(cell)) {
        final target = selectInteractionTarget(
          model.currentRoom,
          model.playerPosition,
        );
        if (target?.id == console.id) interact();
        return;
      }
    }
    if (model.currentRoom.type != RoomType.cloudCenter &&
        cell == model.currentRoom.terminalPosition) {
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
    if (_removed ||
        _inputBlocked ||
        !_sceneReady ||
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
    if (_removed) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final model = _model;
    if (model == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_inputBlocked) {
      if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
        onCloudPanelCloseRequested?.call();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent && _ignoreKeyRepeats) {
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent) _ignoreKeyRepeats = false;
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
    if (_removed || model == null) return;
    if (_inputBlocked) {
      if (button == GamepadButton.east) onCloudPanelCloseRequested?.call();
      return;
    }
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
    if (_removed || _inputBlocked || model == null || model.shopOpen) return;
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
    if (!_inputBlocked &&
        model != null &&
        model.placementMode == PlacementMode.placing) {
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
