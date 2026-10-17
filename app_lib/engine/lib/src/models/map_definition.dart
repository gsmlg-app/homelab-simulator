import 'package:app_lib_core/app_lib_core.dart';
import 'door_model.dart';

/// A source-pixel rectangle in the map atlas.
class MapAtlasFrame {
  final int x;
  final int y;
  final int width;
  final int height;

  const MapAtlasFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class MapTileDefinition {
  final String id;
  final MapAtlasFrame frame;
  final bool blocksMovement;
  final bool blocksPlacement;

  const MapTileDefinition({
    required this.id,
    required this.frame,
    required this.blocksMovement,
    required this.blocksPlacement,
  });
}

class MapPrefabDefinition {
  final String id;
  final MapAtlasFrame frame;
  final int width;
  final int height;
  final double drawWidth;
  final double drawHeight;
  final bool blocksMovement;
  final bool blocksPlacement;

  const MapPrefabDefinition({
    required this.id,
    required this.frame,
    required this.width,
    required this.height,
    required this.drawWidth,
    required this.drawHeight,
    required this.blocksMovement,
    required this.blocksPlacement,
  });
}

class MapTileLayer {
  final String id;
  final bool foreground;
  final List<List<String?>> cells;

  MapTileLayer({
    required this.id,
    required this.foreground,
    required List<List<String?>> cells,
  }) : cells = List.unmodifiable(
         cells.map((row) => List<String?>.unmodifiable(row)),
       );
}

class MapObjectDefinition {
  final String id;
  final String prefabId;
  final GridPosition position;
  final String? bindingSlot;
  final String? interaction;

  const MapObjectDefinition({
    required this.id,
    required this.prefabId,
    required this.position,
    this.bindingSlot,
    this.interaction,
  });
}

class MapPortalDefinition {
  final String id;
  final String targetMapId;
  final WallSide wallSide;
  final int wallPosition;
  final String targetSpawnId;

  const MapPortalDefinition({
    required this.id,
    required this.targetMapId,
    required this.wallSide,
    required this.wallPosition,
    required this.targetSpawnId,
  });
}

/// Immutable, resolved map data. Image size and occupied cells are independent.
class MapDefinition {
  final String id;
  final String name;
  final int width;
  final int height;
  final Map<String, GridPosition> spawns;
  final GridPosition terminalPosition;
  final List<MapTileLayer> layers;
  final List<MapObjectDefinition> objects;
  final List<MapPortalDefinition> portals;
  final Map<String, MapTileDefinition> tiles;
  final Map<String, MapPrefabDefinition> prefabs;

  MapDefinition({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required Map<String, GridPosition> spawns,
    required this.terminalPosition,
    required List<MapTileLayer> layers,
    required List<MapObjectDefinition> objects,
    required List<MapPortalDefinition> portals,
    required Map<String, MapTileDefinition> tiles,
    required Map<String, MapPrefabDefinition> prefabs,
  }) : spawns = Map.unmodifiable(spawns),
       layers = List.unmodifiable(layers),
       objects = List.unmodifiable(objects),
       portals = List.unmodifiable(portals),
       tiles = Map.unmodifiable(tiles),
       prefabs = Map.unmodifiable(prefabs);

  GridPosition get spawn => spawns['entry']!;
  double get tileSize => 32;

  bool containsCell(GridPosition cell) =>
      cell.x >= 0 && cell.y >= 0 && cell.x < width && cell.y < height;

  /// Static terrain/prop rules, shared by runtime collision and validation.
  bool blocksCell(GridPosition cell, {required bool placement}) {
    for (final layer in layers) {
      final tile = tiles[layer.cells[cell.y][cell.x]];
      if (tile != null &&
          (placement ? tile.blocksPlacement : tile.blocksMovement)) {
        return true;
      }
    }
    for (final object in objects) {
      final prefab = prefabs[object.prefabId]!;
      if (cell.x >= object.position.x &&
          cell.x < object.position.x + prefab.width &&
          cell.y >= object.position.y &&
          cell.y < object.position.y + prefab.height &&
          (placement ? prefab.blocksPlacement : prefab.blocksMovement)) {
        return true;
      }
    }
    return false;
  }
}
