import 'package:app_lib_core/app_lib_core.dart';
import 'door_model.dart';
import 'game_model.dart';
import 'map_definition.dart';
import 'room_model.dart';

/// Validated schema-v1 developer-authored maps. No I/O is performed here.
class MapCatalog {
  final String atlasAsset;
  final String initialMapId;
  final Map<String, MapDefinition> maps;
  final Map<String, MapTileDefinition> tiles;
  final Map<String, MapPrefabDefinition> prefabs;

  MapCatalog._({
    required this.atlasAsset,
    required this.initialMapId,
    required Map<String, MapDefinition> maps,
    required Map<String, MapTileDefinition> tiles,
    required Map<String, MapPrefabDefinition> prefabs,
  }) : maps = Map.unmodifiable(maps),
       tiles = Map.unmodifiable(tiles),
       prefabs = Map.unmodifiable(prefabs);

  factory MapCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      _invalid('schemaVersion', 'expected supported version 1');
    }
    final atlas = _string(json['atlasAsset'], 'atlasAsset');
    if (atlas.startsWith('/') ||
        atlas.contains(':') ||
        atlas.contains('\\') ||
        atlas.split('/').contains('..')) {
      _invalid('atlasAsset', 'expected a local relative asset path');
    }
    final tiles = <String, MapTileDefinition>{};
    for (final (index, raw) in _list(json['tiles'], 'tiles').indexed) {
      final path = 'tiles[$index]';
      final tile = _object(raw, path);
      final id = _string(tile['id'], '$path.id');
      _unique(tiles, id, path);
      tiles[id] = MapTileDefinition(
        id: id,
        frame: _frame(tile['frame'], '$path.frame'),
        blocksMovement: _bool(tile['blocksMovement'], '$path.blocksMovement'),
        blocksPlacement: _bool(
          tile['blocksPlacement'],
          '$path.blocksPlacement',
        ),
      );
    }
    final prefabs = <String, MapPrefabDefinition>{};
    for (final (index, raw) in _list(json['prefabs'], 'prefabs').indexed) {
      final path = 'prefabs[$index]';
      final prefab = _object(raw, path);
      final id = _string(prefab['id'], '$path.id');
      _unique(prefabs, id, path);
      prefabs[id] = MapPrefabDefinition(
        id: id,
        frame: _frame(prefab['frame'], '$path.frame'),
        width: _positiveInt(prefab['width'], '$path.width'),
        height: _positiveInt(prefab['height'], '$path.height'),
        drawWidth: _positiveNumber(prefab['drawWidth'], '$path.drawWidth'),
        drawHeight: _positiveNumber(prefab['drawHeight'], '$path.drawHeight'),
        blocksMovement: _bool(prefab['blocksMovement'], '$path.blocksMovement'),
        blocksPlacement: _bool(
          prefab['blocksPlacement'],
          '$path.blocksPlacement',
        ),
      );
    }
    final maps = <String, MapDefinition>{};
    for (final (index, raw) in _list(json['maps'], 'maps').indexed) {
      final path = 'maps[$index]';
      final map = _object(raw, path);
      final id = _string(map['id'], '$path.id');
      _unique(maps, id, path);
      final width = _positiveInt(map['width'], '$path.width');
      final height = _positiveInt(map['height'], '$path.height');
      final spawns = _object(map['spawns'], '$path.spawns').map(
        (key, value) => MapEntry(key, _position(value, '$path.spawns.$key')),
      );
      if (!spawns.containsKey('entry')) {
        _invalid('$path.spawns', 'missing entry spawn');
      }
      final layers = <MapTileLayer>[];
      final layerIds = <String>{};
      for (final (li, rawLayer) in _list(
        map['layers'],
        '$path.layers',
      ).indexed) {
        final lp = '$path.layers[$li]';
        final layer = _object(rawLayer, lp);
        final layerId = _string(layer['id'], '$lp.id');
        if (!layerIds.add(layerId)) {
          _invalid(lp, 'duplicate layer ID "$layerId"');
        }
        final rows = _list(layer['cells'], '$lp.cells');
        if (rows.length != height) {
          _invalid('$lp.cells', 'expected $height rows, got ${rows.length}');
        }
        final cells = <List<String?>>[];
        for (final (y, row) in rows.indexed) {
          final values = _list(row, '$lp.cells[$y]');
          if (values.length != width) {
            _invalid(
              '$lp.cells[$y]',
              'expected $width cells, got ${values.length}',
            );
          }
          cells.add(
            values.indexed.map((entry) {
              final (x, value) = entry;
              if (value == null) return null;
              final tileId = _string(value, '$lp.cells[$y][$x]');
              if (!tiles.containsKey(tileId)) {
                _invalid('$lp.cells[$y][$x]', 'unknown tile "$tileId"');
              }
              return tileId;
            }).toList(),
          );
        }
        layers.add(
          MapTileLayer(
            id: layerId,
            foreground: _bool(layer['foreground'], '$lp.foreground'),
            cells: cells,
          ),
        );
      }
      final objects = <MapObjectDefinition>[];
      final objectIds = <String>{};
      final slots = <String>{};
      for (final (oi, rawObject) in _list(
        map['objects'],
        '$path.objects',
      ).indexed) {
        final op = '$path.objects[$oi]';
        final object = _object(rawObject, op);
        final objectId = _string(object['id'], '$op.id');
        if (!objectIds.add(objectId)) {
          _invalid(op, 'duplicate object ID "$objectId"');
        }
        final prefabId = _string(object['prefabId'], '$op.prefabId');
        final prefab = prefabs[prefabId];
        if (prefab == null) {
          _invalid('$op.prefabId', 'unknown prefab "$prefabId"');
        }
        final position = _position(object['position'], '$op.position');
        if (position.x < 0 ||
            position.y < 0 ||
            position.x + prefab.width > width ||
            position.y + prefab.height > height) {
          _invalid(
            op,
            'prefab footprint is outside map "$id" (${width}x$height)',
          );
        }
        final slot = object['bindingSlot'] == null
            ? null
            : _string(object['bindingSlot'], '$op.bindingSlot');
        if (slot != null && !slots.add(slot)) {
          _invalid(op, 'duplicate bindingSlot "$slot"');
        }
        final interaction = object['interaction'] == null
            ? null
            : _string(object['interaction'], '$op.interaction');
        if (interaction != null && interaction != 'shop') {
          _invalid(
            '$op.interaction',
            'unsupported interaction "$interaction"; expected shop',
          );
        }
        objects.add(
          MapObjectDefinition(
            id: objectId,
            prefabId: prefabId,
            position: position,
            bindingSlot: slot,
            interaction: interaction,
          ),
        );
      }
      final portals = <MapPortalDefinition>[];
      final portalIds = <String>{};
      for (final (pi, rawPortal) in _list(
        map['portals'],
        '$path.portals',
      ).indexed) {
        final pp = '$path.portals[$pi]';
        final portal = _object(rawPortal, pp);
        final portalId = _string(portal['id'], '$pp.id');
        if (!portalIds.add(portalId)) {
          _invalid(pp, 'duplicate portal ID "$portalId"');
        }
        final sideName = _string(portal['wallSide'], '$pp.wallSide');
        final sides = WallSide.values.where((s) => s.name == sideName);
        if (sides.isEmpty) _invalid('$pp.wallSide', 'unknown side "$sideName"');
        final side = sides.single;
        final position = _int(portal['wallPosition'], '$pp.wallPosition');
        final limit = side == WallSide.top || side == WallSide.bottom
            ? width
            : height;
        if (position < 0 || position >= limit) {
          _invalid('$pp.wallPosition', 'expected 0..${limit - 1}');
        }
        portals.add(
          MapPortalDefinition(
            id: portalId,
            targetMapId: _string(portal['targetMapId'], '$pp.targetMapId'),
            wallSide: side,
            wallPosition: position,
            targetSpawnId: _string(
              portal['targetSpawnId'],
              '$pp.targetSpawnId',
            ),
          ),
        );
      }
      final definition = MapDefinition(
        id: id,
        name: _string(map['name'], '$path.name'),
        width: width,
        height: height,
        spawns: spawns,
        terminalPosition: _position(
          map['terminalPosition'],
          '$path.terminalPosition',
        ),
        layers: layers,
        objects: objects,
        portals: portals,
        tiles: tiles,
        prefabs: prefabs,
      );
      if (!definition.containsCell(definition.terminalPosition)) {
        _invalid('$path.terminalPosition', 'outside map bounds');
      }
      maps[id] = definition;
    }
    final initialMapId = _string(json['initialMapId'], 'initialMapId');
    if (!maps.containsKey(initialMapId)) {
      _invalid('initialMapId', 'unknown map "$initialMapId"');
    }
    final catalog = MapCatalog._(
      atlasAsset: atlas,
      initialMapId: initialMapId,
      maps: maps,
      tiles: tiles,
      prefabs: prefabs,
    );
    catalog._validateAccess();
    return catalog;
  }

  RoomModel _room(MapDefinition map) => RoomModel(
    id: map.id,
    name: map.name,
    width: map.width,
    height: map.height,
    terminalPosition: map.terminalPosition,
    definitionId: map.id,
    definition: map,
    doors: List.unmodifiable(
      map.portals.map(
        (portal) => DoorModel(
          id: '${map.id}:${portal.id}',
          targetRoomId: portal.targetMapId,
          wallSide: portal.wallSide,
          wallPosition: portal.wallPosition,
          targetSpawnId: portal.targetSpawnId,
        ),
      ),
    ),
  );

  void _validateAccess() {
    for (final map in maps.values) {
      final room = _room(map);
      for (final entry in map.spawns.entries) {
        if (!room.canWalk(entry.value)) {
          _invalid(
            'maps.${map.id}.spawns.${entry.key}',
            'spawn is blocked or outside map bounds',
          );
        }
      }
      const neighbors = [
        GridPosition(0, -1),
        GridPosition(1, 0),
        GridPosition(0, 1),
        GridPosition(-1, 0),
      ];
      final terminalAccessible = neighbors
          .map((delta) => map.terminalPosition + delta)
          .any(
            (cell) =>
                room.canWalk(cell) &&
                (cell == map.spawn ||
                    room.findPath(map.spawn, cell).isNotEmpty),
          );
      if (!terminalAccessible) {
        _invalid(
          'maps.${map.id}.terminalPosition',
          'terminal has no walkable adjacent interaction cell reachable from entry spawn',
        );
      }
      for (final portal in map.portals) {
        final path = 'maps.${map.id}.portals.${portal.id}';
        final destination = maps[portal.targetMapId];
        if (destination == null) {
          _invalid('$path.targetMapId', 'unknown map "${portal.targetMapId}"');
        }
        if (!destination.spawns.containsKey(portal.targetSpawnId)) {
          _invalid(
            '$path.targetSpawnId',
            'unknown spawn "${portal.targetSpawnId}" in map "${destination.id}"',
          );
        }
        final door = room.doors.firstWhere(
          (d) => d.id == '${map.id}:${portal.id}',
        );
        final interaction = door.getSpawnPosition(map.width, map.height);
        if (!room.canWalk(interaction) ||
            (interaction != map.spawn &&
                room.findPath(map.spawn, interaction).isEmpty)) {
          _invalid(
            path,
            'portal interaction cell $interaction is blocked or unreachable from entry spawn',
          );
        }
      }
    }
  }

  GameModel createGame() => GameModel(
    currentRoomId: initialMapId,
    rooms: List.unmodifiable(maps.values.map(_room)),
    playerPosition: maps[initialMapId]!.spawn,
  );

  /// Reattach transient definitions; incompatible worlds start from catalog data.
  GameModel resolveGame(GameModel game) {
    if (game.rooms.isEmpty ||
        game.rooms.any((room) => !maps.containsKey(room.definitionId))) {
      return createGame();
    }
    final rooms = game.rooms.map((room) {
      final definition = maps[room.definitionId]!;
      return room.copyWith(
        definition: definition,
        width: definition.width,
        height: definition.height,
        terminalPosition: definition.terminalPosition,
        doors: [
          ..._room(definition).doors.map(
            (door) => door.copyWith(
              targetRoomId: game.rooms
                  .firstWhere(
                    (candidate) => candidate.definitionId == door.targetRoomId,
                    orElse: () => _room(maps[door.targetRoomId]!),
                  )
                  .id,
            ),
          ),
          ...room.doors.where(
            (door) => !door.id.startsWith('${definition.id}:'),
          ),
        ],
      );
    }).toList();
    for (final definition in maps.values) {
      if (!rooms.any((room) => room.definitionId == definition.id)) {
        rooms.add(_room(definition));
      }
    }
    var resolved = game.copyWith(rooms: rooms);
    if (resolved.getRoomById(resolved.currentRoomId) == null) {
      return createGame();
    }
    if (!resolved.currentRoom.canWalk(resolved.playerPosition)) {
      resolved = resolved.copyWith(
        playerPosition: resolved.currentRoom.definition!.spawn,
      );
    }
    return resolved;
  }
}

Never _invalid(String path, String message) =>
    throw FormatException('$path: $message');
Map<String, dynamic> _object(dynamic value, String path) {
  if (value is! Map<String, dynamic>) _invalid(path, 'expected an object');
  return value;
}

List<dynamic> _list(dynamic value, String path) {
  if (value is! List) _invalid(path, 'expected a list');
  return value;
}

String _string(dynamic value, String path) {
  if (value is! String || value.trim().isEmpty) {
    _invalid(path, 'expected a non-empty string');
  }
  return value;
}

int _int(dynamic value, String path) {
  if (value is! int) _invalid(path, 'expected an integer');
  return value;
}

int _positiveInt(dynamic value, String path) {
  final number = _int(value, path);
  if (number <= 0) _invalid(path, 'expected a positive integer');
  return number;
}

double _positiveNumber(dynamic value, String path) {
  if (value is! num || !value.isFinite || value <= 0) {
    _invalid(path, 'expected a finite positive number');
  }
  return value.toDouble();
}

bool _bool(dynamic value, String path) {
  if (value is! bool) _invalid(path, 'expected a boolean');
  return value;
}

GridPosition _position(dynamic value, String path) {
  final pair = _list(value, path);
  if (pair.length != 2) _invalid(path, 'expected [x,y]');
  return GridPosition(_int(pair[0], '$path[0]'), _int(pair[1], '$path[1]'));
}

MapAtlasFrame _frame(dynamic value, String path) {
  final values = _list(value, path);
  if (values.length != 4) _invalid(path, 'expected [x,y,width,height]');
  final x = _int(values[0], '$path.x');
  final y = _int(values[1], '$path.y');
  if (x < 0 || y < 0) _invalid(path, 'source coordinates must be non-negative');
  return MapAtlasFrame(
    x: x,
    y: y,
    width: _positiveInt(values[2], '$path.width'),
    height: _positiveInt(values[3], '$path.height'),
  );
}

void _unique(Map<String, Object> values, String id, String path) {
  if (values.containsKey(id)) _invalid(path, 'duplicate ID "$id"');
}
