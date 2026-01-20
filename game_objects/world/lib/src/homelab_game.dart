import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';
import 'package:game_objects_room/game_objects_room.dart';
import 'package:game_objects_character/game_objects_character.dart';
import 'package:game_objects_devices/game_objects_devices.dart';

import 'gamepad_handler.dart';

/// Main Flame game for Homelab Simulator
class HomelabGame extends FlameGame
    with HasKeyboardHandlerComponents, TapCallbacks, MouseMovementDetector {
  final GameBloc gameBloc;
  final WorldBloc worldBloc;

  late final RoomComponent _room;
  late final PlayerComponent _player;
  late final GamepadHandler _gamepadHandler;
  PlacementGhostComponent? _placementGhost;

  final List<DeviceComponent> _deviceComponents = [];
  final List<CloudServiceComponent> _cloudServiceComponents = [];
  final List<DoorComponent> _doorComponents = [];
  String? _currentRoomId;

  HomelabGame({
    required this.gameBloc,
    required this.worldBloc,
  });

  @override
  Future<void> onLoad() async {
    // Add BLoC providers
    await add(
      FlameBlocProvider<WorldBloc, WorldState>.value(
        value: worldBloc,
        children: [
          _buildWorld(),
        ],
      ),
    );

    // Add gamepad handler
    _gamepadHandler = GamepadHandler(
      onDirection: _onGamepadDirection,
      onButtonPressed: _onGamepadButtonPressed,
    );
    await add(_gamepadHandler);

    // Listen to game state changes
    gameBloc.stream.listen(_onGameStateChanged);
  }

  void _onGamepadDirection(Direction direction) {
    final state = gameBloc.state;
    if (state is! GameReady) return;
    if (state.model.shopOpen) return; // Don't move when shop is open

    gameBloc.add(GameMovePlayer(direction));
    _player.moveInDirection(direction);
  }

  void _onGamepadButtonPressed(GamepadButton button) {
    final state = gameBloc.state;
    if (state is! GameReady) return;

    switch (button) {
      case GamepadButton.south: // A button - interact/confirm
        final worldState = worldBloc.state;
        if (worldState.canInteract) {
          switch (worldState.availableInteraction) {
            case InteractionType.terminal:
              gameBloc.add(const GameToggleShop(isOpen: true));
              return;
            case InteractionType.door:
              final doorId = worldState.interactableEntityId;
              if (doorId != null) {
                final door = state.model.currentRoom.doors.firstWhere(
                  (d) => d.id == doorId,
                  orElse: () => state.model.currentRoom.doors.first,
                );
                _enterDoor(door, state.model);
              }
              return;
            case InteractionType.device:
            case InteractionType.none:
              break;
          }
        }
        // Handle placement mode if no interaction available
        if (state.model.placementMode == PlacementMode.placing &&
            state.model.selectedTemplate != null) {
          // Place device at player position (or could use cursor)
          final pos = _player.gridPosition;
          if (state.model.currentRoom.canPlaceDevice(
            pos,
            state.model.selectedTemplate!.width,
            state.model.selectedTemplate!.height,
          )) {
            gameBloc.add(GamePlaceDevice(pos));
          }
        }
        break;

      case GamepadButton.east: // B button - cancel/back
        if (state.model.placementMode == PlacementMode.placing) {
          gameBloc.add(const GameCancelPlacement());
        } else if (state.model.shopOpen) {
          gameBloc.add(const GameToggleShop(isOpen: false));
        }
        break;

      case GamepadButton.start: // Start - toggle shop
        gameBloc.add(GameToggleShop(isOpen: !state.model.shopOpen));
        break;

      default:
        break;
    }
  }

  Component _buildWorld() {
    return Component(
      children: [
        _room = RoomComponent(),
        _player = PlayerComponent(
          initialPosition: _getInitialPlayerPosition(),
        ),
      ],
    );
  }

  GridPosition _getInitialPlayerPosition() {
    final state = gameBloc.state;
    if (state is GameReady) {
      return state.model.playerPosition;
    }
    return GameConstants.playerStartPosition;
  }

  void _onGameStateChanged(GameState state) {
    if (state is! GameReady) return;

    final model = state.model;

    // Check if room changed
    final roomChanged = _currentRoomId != model.currentRoomId;
    if (roomChanged) {
      _currentRoomId = model.currentRoomId;
      // Full resync needed when room changes
      _syncDoors(model.currentRoom.doors);
      _syncDevices(model.currentRoom.devices);
      _syncCloudServices(model.currentRoom.cloudServices);
    }

    // Update player position if changed externally
    if (_player.gridPosition != model.playerPosition) {
      _player.moveTo(model.playerPosition);
    }

    // Handle placement mode
    if (model.placementMode == PlacementMode.placing) {
      if (model.selectedTemplate != null) {
        _showPlacementGhost(model.selectedTemplate!);
      } else if (model.selectedCloudService != null) {
        _showCloudServicePlacementGhost(model.selectedCloudService!);
      }
    } else {
      _hidePlacementGhost();
    }

    // Sync devices and cloud services (incremental if room didn't change)
    if (!roomChanged) {
      _syncDevices(model.currentRoom.devices);
      _syncCloudServices(model.currentRoom.cloudServices);
    }

    // Update door interaction availability
    _updateDoorInteraction(model);
  }

  void _showPlacementGhost(DeviceTemplate template) {
    if (_placementGhost == null) {
      _placementGhost = PlacementGhostComponent();
      add(FlameBlocProvider<WorldBloc, WorldState>.value(
        value: worldBloc,
        children: [_placementGhost!],
      ));
    }
    _placementGhost!.setTemplate(template);
  }

  void _showCloudServicePlacementGhost(CloudServiceTemplate template) {
    if (_placementGhost == null) {
      _placementGhost = PlacementGhostComponent();
      add(FlameBlocProvider<WorldBloc, WorldState>.value(
        value: worldBloc,
        children: [_placementGhost!],
      ));
    }
    _placementGhost!.setCloudService(template);
  }

  void _hidePlacementGhost() {
    _placementGhost?.removeFromParent();
    _placementGhost = null;
  }

  void _syncDevices(List<DeviceModel> devices) {
    // Remove components for deleted devices
    final deviceIds = devices.map((d) => d.id).toSet();
    _deviceComponents.removeWhere((comp) {
      if (!deviceIds.contains(comp.device.id)) {
        comp.removeFromParent();
        return true;
      }
      return false;
    });

    // Add components for new devices
    final existingIds = _deviceComponents.map((c) => c.device.id).toSet();
    for (final device in devices) {
      if (!existingIds.contains(device.id)) {
        final comp = DeviceComponent(device: device);
        _deviceComponents.add(comp);
        add(FlameBlocProvider<WorldBloc, WorldState>.value(
          value: worldBloc,
          children: [comp],
        ));
      }
    }
  }

  void _syncCloudServices(List<CloudServiceModel> services) {
    // Remove components for deleted services
    final serviceIds = services.map((s) => s.id).toSet();
    _cloudServiceComponents.removeWhere((comp) {
      if (!serviceIds.contains(comp.service.id)) {
        comp.removeFromParent();
        return true;
      }
      return false;
    });

    // Add components for new services
    final existingIds = _cloudServiceComponents.map((c) => c.service.id).toSet();
    for (final service in services) {
      if (!existingIds.contains(service.id)) {
        final comp = CloudServiceComponent(service: service);
        _cloudServiceComponents.add(comp);
        add(FlameBlocProvider<WorldBloc, WorldState>.value(
          value: worldBloc,
          children: [comp],
        ));
      }
    }
  }

  void _syncDoors(List<DoorModel> doors) {
    // Remove all existing door components
    for (final comp in _doorComponents) {
      comp.removeFromParent();
    }
    _doorComponents.clear();

    // Add new door components
    for (final door in doors) {
      final comp = DoorComponent(door: door);
      _doorComponents.add(comp);
      add(FlameBlocProvider<WorldBloc, WorldState>.value(
        value: worldBloc,
        children: [comp],
      ));
    }
  }

  void _updateDoorInteraction(GameModel model) {
    final playerPos = model.playerPosition;
    final room = model.currentRoom;

    // Check if player is adjacent to any door
    for (final door in room.doors) {
      final doorPos = door.getPosition(room.width, room.height);
      if (playerPos.isAdjacentTo(doorPos) || playerPos == doorPos) {
        worldBloc.add(InteractionAvailable(door.id, InteractionType.door));
        return;
      }
    }

    // If player was interacting with a door but is no longer near it
    final worldState = worldBloc.state;
    if (worldState.availableInteraction == InteractionType.door) {
      worldBloc.add(const InteractionUnavailable());
    }
  }

  void _enterDoor(DoorModel door, GameModel model) {
    final targetRoom = model.getRoomById(door.targetRoomId);
    if (targetRoom == null) return;

    // Calculate spawn position in target room
    final spawnPos = door.getSpawnPosition(targetRoom.width, targetRoom.height);

    gameBloc.add(GameEnterRoom(
      roomId: door.targetRoomId,
      spawnPosition: spawnPos,
    ));
  }

  @override
  void onTapUp(TapUpEvent event) {
    final state = gameBloc.state;
    if (state is! GameReady) return;

    final model = state.model;
    final worldPos = event.localPosition;
    final gridPos = pixelToGrid(worldPos.x, worldPos.y);

    if (!isWithinBounds(gridPos)) return;

    // In placement mode, place device or cloud service
    if (model.placementMode == PlacementMode.placing) {
      if (model.selectedTemplate != null) {
        if (model.currentRoom.canPlaceDevice(
          gridPos,
          model.selectedTemplate!.width,
          model.selectedTemplate!.height,
        )) {
          gameBloc.add(GamePlaceDevice(gridPos));
        }
        return;
      } else if (model.selectedCloudService != null) {
        if (model.currentRoom.canPlaceDevice(
          gridPos,
          model.selectedCloudService!.width,
          model.selectedCloudService!.height,
        )) {
          gameBloc.add(GamePlaceCloudService(gridPos));
        }
        return;
      }
    }

    // Check if tapping terminal
    if (gridPos == model.currentRoom.terminalPosition &&
        _player.gridPosition.isAdjacentTo(gridPos)) {
      worldBloc.add(const InteractionRequested('terminal', InteractionType.terminal));
      gameBloc.add(const GameToggleShop(isOpen: true));
      return;
    }

    // Otherwise, move player
    if (!model.currentRoom.isCellOccupied(gridPos)) {
      gameBloc.add(GameMovePlayerTo(gridPos));
      _player.moveTo(gridPos);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final state = gameBloc.state;
    if (state is! GameReady) return KeyEventResult.ignored;

    // Escape to cancel placement
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (state.model.placementMode == PlacementMode.placing) {
        gameBloc.add(const GameCancelPlacement());
        return KeyEventResult.handled;
      }
      if (state.model.shopOpen) {
        gameBloc.add(const GameToggleShop(isOpen: false));
        return KeyEventResult.handled;
      }
    }

    // Movement keys
    Direction? direction;
    if (event.logicalKey == LogicalKeyboardKey.keyW ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      direction = Direction.up;
    } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      direction = Direction.down;
    } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      direction = Direction.left;
    } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      direction = Direction.right;
    }

    if (direction != null) {
      gameBloc.add(GameMovePlayer(direction));
      _player.moveInDirection(direction);
      return KeyEventResult.handled;
    }

    // E to interact
    if (event.logicalKey == LogicalKeyboardKey.keyE) {
      final worldState = worldBloc.state;
      if (worldState.canInteract) {
        switch (worldState.availableInteraction) {
          case InteractionType.terminal:
            gameBloc.add(const GameToggleShop(isOpen: true));
            return KeyEventResult.handled;
          case InteractionType.door:
            // Find the door by its ID and enter
            final doorId = worldState.interactableEntityId;
            if (doorId != null) {
              final door = state.model.currentRoom.doors.firstWhere(
                (d) => d.id == doorId,
                orElse: () => state.model.currentRoom.doors.first,
              );
              _enterDoor(door, state.model);
              return KeyEventResult.handled;
            }
            break;
          case InteractionType.device:
          case InteractionType.none:
            break;
        }
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _room.onHoverPosition(info.eventPosition.widget);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update placement ghost validity
    if (_placementGhost != null) {
      final state = gameBloc.state;
      if (state is GameReady) {
        final pos = _placementGhost!.currentPosition;
        if (pos != null) {
          int width = 1;
          int height = 1;

          if (state.model.selectedTemplate != null) {
            width = state.model.selectedTemplate!.width;
            height = state.model.selectedTemplate!.height;
          } else if (state.model.selectedCloudService != null) {
            width = state.model.selectedCloudService!.width;
            height = state.model.selectedCloudService!.height;
          }

          final valid = state.model.currentRoom.canPlaceDevice(pos, width, height);
          _placementGhost!.setValid(valid);
          _room.setPlacementValid(valid);
        }
      }
    }
  }
}
