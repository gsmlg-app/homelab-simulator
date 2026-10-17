import 'dart:ui' as ui;

import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

ui.Rect _sourceRect(MapAtlasFrame frame) => ui.Rect.fromLTWH(
  frame.x.toDouble(),
  frame.y.toDouble(),
  frame.width.toDouble(),
  frame.height.toDouble(),
);

/// Atlas terrain and owned sibling props, foreground and placement feedback.
///
/// Use [attachToWorld] under the same scene container as actors. Actor priority
/// must use the same `groundAnchor.y * 100` convention as [MapPropComponent].
/// [removeFromWorld] removes the entire owned set, including pending image loads.
class MapEnvironmentComponent extends MapTileLayerComponent
    with HasGameReference<FlameGame> {
  final MapCatalog catalog;
  final Future<ui.Image> Function()? atlasLoader;
  late final MapTileLayerComponent foreground;
  late final MapPlacementOverlayComponent placementOverlay;
  late final List<MapPropComponent> groundAnchoredProps;
  bool _disposed = false;
  Component? _sceneParent;

  MapEnvironmentComponent({
    required this.catalog,
    required super.definition,
    this.atlasLoader,
  }) : super(foreground: false, priority: -100000) {
    foreground = MapTileLayerComponent(
      definition: definition,
      foreground: true,
      priority: 100000,
    );
    placementOverlay = MapPlacementOverlayComponent(
      width: definition.width,
      height: definition.height,
      tileSize: definition.tileSize,
    );
    groundAnchoredProps = List.unmodifiable([
      for (final object in definition.objects)
        MapPropComponent(
          objectDefinition: object,
          prefab: definition.prefabs[object.prefabId]!,
          tileSize: definition.tileSize,
        ),
    ]);
  }

  /// Bounds include tall artwork extending beyond the occupied map cells.
  ui.Rect get visualBounds {
    var bounds = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    for (final prop in groundAnchoredProps) {
      bounds = bounds.expandToInclude(prop.visualBounds);
    }
    return bounds;
  }

  /// Mount all owned components as siblings so actor/prop sorting is shared.
  Future<void> attachToWorld(Component sceneParent) async {
    if (_sceneParent != null || _disposed) {
      throw StateError('A map environment can only be attached once.');
    }
    _sceneParent = sceneParent;
    await sceneParent.addAll([
      this,
      ...groundAnchoredProps,
      foreground,
      placementOverlay,
    ]);
  }

  @override
  Future<void> onLoad() async {
    if (_disposed) return;
    final owner = game;
    await super.onLoad();
    final image =
        await (atlasLoader?.call() ?? owner.images.load(catalog.atlasAsset));
    if (_disposed || isRemoved || isRemoving || owner.isRemoved) return;
    atlasImage = image;
    foreground.atlasImage = image;
    for (final prop in groundAnchoredProps) {
      prop.atlasImage = image;
    }
  }

  void setPlacementMode(bool enabled) {
    placementOverlay.placementMode = enabled;
    if (!enabled) placementOverlay.setPreview(null);
  }

  void setPlacementPreview(
    GridPosition? cell, {
    bool valid = true,
    int width = 1,
    int height = 1,
  }) => placementOverlay.setPreview(
    cell,
    valid: valid,
    width: width,
    height: height,
  );

  /// Fade only props between the camera and this actor's grounded feet.
  /// Call with the interpolated actor anchor, or null when changing rooms.
  void setActorGroundPosition(Vector2? anchor) {
    for (final prop in groundAnchoredProps) {
      prop.setActorGroundPosition(anchor);
    }
  }

  void _removeSiblings() {
    _disposed = true;
    for (final component in [
      ...groundAnchoredProps,
      foreground,
      placementOverlay,
    ]) {
      component.removeFromParent();
    }
  }

  void removeFromWorld() {
    _removeSiblings();
    removeFromParent();
  }

  @override
  void onRemove() {
    _removeSiblings();
    super.onRemove();
  }
}

/// Draws all terrain layers of one band without exposing a placement grid.
class MapTileLayerComponent extends PositionComponent {
  final MapDefinition definition;
  final bool isForeground;
  ui.Image? atlasImage;
  final ui.Paint _paint = ui.Paint()..filterQuality = ui.FilterQuality.low;

  MapTileLayerComponent({
    required this.definition,
    required bool foreground,
    this.atlasImage,
    super.priority,
  }) : isForeground = foreground,
       super(
         size: Vector2(
           definition.width * definition.tileSize,
           definition.height * definition.tileSize,
         ),
       );

  @override
  void render(ui.Canvas canvas) {
    final image = atlasImage;
    if (image == null) return;
    final tileSize = definition.tileSize;
    for (final layer in definition.layers) {
      if (layer.foreground != isForeground) continue;
      for (var y = 0; y < definition.height; y++) {
        for (var x = 0; x < definition.width; x++) {
          final tile = definition.tiles[layer.cells[y][x]];
          if (tile == null) continue;
          canvas.drawImageRect(
            image,
            _sourceRect(tile.frame),
            ui.Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
            _paint,
          );
        }
      }
    }
  }
}

/// Static art anchored at the bottom center of its independent cell footprint.
class MapPropComponent extends PositionComponent {
  final MapObjectDefinition objectDefinition;
  final MapPrefabDefinition prefab;
  final double tileSize;
  ui.Image? atlasImage;
  double visualOpacity = 1;
  final ui.Paint _paint = ui.Paint()..filterQuality = ui.FilterQuality.low;

  MapPropComponent({
    required this.objectDefinition,
    required this.prefab,
    required this.tileSize,
    this.atlasImage,
  }) : super(
         size: Vector2(prefab.drawWidth, prefab.drawHeight),
         position: Vector2(
           (objectDefinition.position.x + prefab.width / 2) * tileSize,
           (objectDefinition.position.y + prefab.height) * tileSize,
         ),
         anchor: Anchor.bottomCenter,
         priority:
             ((objectDefinition.position.y + prefab.height) * tileSize * 100)
                 .round(),
       );

  Vector2 get groundAnchor => position.clone();
  ui.Rect get visualBounds => ui.Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y,
    size.x,
    size.y,
  );

  void setActorGroundPosition(Vector2? actorAnchor) {
    final bounds = visualBounds;
    // Include a small shoulder margin so a player crossing an edge stays legible.
    final covered =
        actorAnchor != null &&
        actorAnchor.y < position.y &&
        actorAnchor.y > bounds.top &&
        actorAnchor.x > bounds.left - 10 &&
        actorAnchor.x < bounds.right + 10;
    visualOpacity = covered ? 0.48 : 1;
  }

  @override
  void render(ui.Canvas canvas) {
    final image = atlasImage;
    if (image == null) return;
    _paint.color = ui.Color.fromRGBO(255, 255, 255, visualOpacity);
    canvas.drawImageRect(
      image,
      _sourceRect(prefab.frame),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
}

/// Explicit placement feedback; normal exploration never draws this grid.
class MapPlacementOverlayComponent extends PositionComponent {
  final double tileSize;
  bool placementMode = false;
  ui.Rect? previewBounds;
  bool _valid = true;
  final ui.Path _grid = ui.Path();
  final ui.Paint _gridPaint = ui.Paint()
    ..color = const ui.Color(0x557dbdc5)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.5;
  final ui.Paint _previewPaint = ui.Paint();

  MapPlacementOverlayComponent({
    required int width,
    required int height,
    required this.tileSize,
  }) : super(
         size: Vector2(width * tileSize, height * tileSize),
         priority: 100001,
       ) {
    for (var x = 0; x <= width; x++) {
      _grid.moveTo(x * tileSize, 0);
      _grid.lineTo(x * tileSize, size.y);
    }
    for (var y = 0; y <= height; y++) {
      _grid.moveTo(0, y * tileSize);
      _grid.lineTo(size.x, y * tileSize);
    }
  }

  void setPreview(
    GridPosition? cell, {
    bool valid = true,
    int width = 1,
    int height = 1,
  }) {
    _valid = valid;
    previewBounds = cell == null
        ? null
        : ui.Rect.fromLTWH(
            cell.x * tileSize,
            cell.y * tileSize,
            width * tileSize,
            height * tileSize,
          );
  }

  @override
  void render(ui.Canvas canvas) {
    if (!placementMode) return;
    canvas.drawPath(_grid, _gridPaint);
    final bounds = previewBounds;
    if (bounds == null) return;
    final color = _valid
        ? const ui.Color(0xff79d5c6)
        : const ui.Color(0xffe58b79);
    _previewPaint
      ..color = color.withValues(alpha: 0.24)
      ..style = ui.PaintingStyle.fill;
    canvas.drawRect(bounds, _previewPaint);
    _previewPaint
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(bounds.deflate(1), _previewPaint);
  }
}
