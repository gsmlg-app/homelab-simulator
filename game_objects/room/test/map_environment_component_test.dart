import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_objects_room/game_objects_room.dart';

void main() {
  late MapCatalog catalog;
  setUp(() {
    catalog = MapCatalog.fromJson(
      jsonDecode(File('../../assets/maps/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  });
  test(
    'shipped maps have different dimensions and valid catalog references',
    () {
      expect(catalog.maps['server-lab']!.width, 20);
      expect(catalog.maps['operations']!.width, 16);
      expect(catalog.createGame().rooms.length, 2);
      for (final room in catalog.createGame().rooms) {
        for (final door in room.doors) {
          final entry = door.getSpawnPosition(room.width, room.height);
          expect(room.canWalk(entry), isTrue);
          expect(
            entry == room.definition!.spawn ||
                room.findPath(room.definition!.spawn, entry).isNotEmpty,
            isTrue,
          );
        }
        expect(
          room.definition!.objects
              .singleWhere((object) => object.interaction == 'shop')
              .position,
          room.terminalPosition,
        );
      }
    },
  );
  test('attachment and removal own every layer and sortable prop', () async {
    final scene = Component();
    final environment = MapEnvironmentComponent(
      catalog: catalog,
      definition: catalog.maps['server-lab']!,
    );
    await environment.attachToWorld(scene);
    expect(scene.children.length, environment.groundAnchoredProps.length + 3);
    expect(
      environment.groundAnchoredProps.every((prop) => prop.parent == scene),
      isTrue,
    );
    environment.removeFromWorld();
    expect(scene.children, isEmpty);
  });
  test('a late atlas load cannot restore removed map visuals', () async {
    final game = FlameGame();
    final scene = Component();
    await game.add(scene);
    final pending = Completer<ui.Image>();
    final environment = MapEnvironmentComponent(
      catalog: catalog,
      definition: catalog.maps['server-lab']!,
      atlasLoader: () => pending.future,
    );
    await environment.attachToWorld(scene);
    final loading = environment.onLoad();
    environment.removeFromWorld();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    pending.complete(image);
    await loading;
    expect(environment.atlasImage, isNull);
    expect(
      environment.groundAnchoredProps.every((prop) => prop.atlasImage == null),
      isTrue,
    );
    expect(scene.children, isEmpty);
    image.dispose();
    picture.dispose();
  });
  test('layers and placement overlay use current room dimensions', () {
    for (final definition in catalog.maps.values) {
      final environment = MapEnvironmentComponent(
        catalog: catalog,
        definition: definition,
      );
      final expected = Vector2(definition.width * 32, definition.height * 32);
      expect(environment.size, expected);
      expect(environment.foreground.size, expected);
      expect(environment.placementOverlay.size, expected);
      expect(environment.placementOverlay.placementMode, isFalse);
      environment.setPlacementMode(true);
      expect(environment.placementOverlay.placementMode, isTrue);
      environment.setPlacementPreview(const GridPosition(4, 8), width: 2);
      expect(
        environment.placementOverlay.previewBounds,
        const ui.Rect.fromLTWH(128, 256, 64, 32),
      );
      environment.setPlacementMode(false);
      expect(environment.placementOverlay.previewBounds, isNull);
    }
  });
  test('tall art is grounded independently of its occupied cells', () {
    final environment = MapEnvironmentComponent(
      catalog: catalog,
      definition: catalog.maps['server-lab']!,
    );
    final rack = environment.groundAnchoredProps.firstWhere(
      (prop) => prop.objectDefinition.id == 'compute-a',
    );
    expect(rack.groundAnchor, Vector2(192, 128));
    expect(rack.visualBounds, const ui.Rect.fromLTWH(160, 32, 64, 96));
    expect(rack.priority, 12800);
    expect(environment.foreground.priority, greaterThan(rack.priority));
    expect(environment.priority, lessThan(rack.priority));
    expect(
      environment.visualBounds.contains(rack.visualBounds.topLeft),
      isTrue,
    );
    environment.setActorGroundPosition(Vector2(190, 100));
    expect(rack.visualOpacity, 0.48);
    environment.setActorGroundPosition(Vector2(190, 150));
    expect(rack.visualOpacity, 1);
  });
  test('atlas source frame renders at its independent logical size', () async {
    final recorder = ui.PictureRecorder();
    final sourceCanvas = ui.Canvas(recorder);
    sourceCanvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 4, 2),
      ui.Paint()..color = const ui.Color(0xffff0000),
    );
    sourceCanvas.drawRect(
      const ui.Rect.fromLTWH(2, 0, 2, 2),
      ui.Paint()..color = const ui.Color(0xff00ff00),
    );
    final picture = recorder.endRecording();
    final atlas = await picture.toImage(4, 2);
    picture.dispose();
    final prop = MapPropComponent(
      objectDefinition: const MapObjectDefinition(
        id: 'test',
        prefabId: 'green',
        position: GridPosition(0, 0),
      ),
      prefab: const MapPrefabDefinition(
        id: 'green',
        frame: MapAtlasFrame(x: 2, y: 0, width: 2, height: 2),
        width: 1,
        height: 1,
        drawWidth: 32,
        drawHeight: 64,
        blocksMovement: true,
        blocksPlacement: true,
      ),
      tileSize: 32,
      atlasImage: atlas,
    );
    final output = ui.PictureRecorder();
    prop.render(ui.Canvas(output));
    final outputPicture = output.endRecording();
    final image = await outputPicture.toImage(32, 64);
    final bytes = (await image.toByteData())!;
    expect(bytes.getUint32((32 * 32 + 16) * 4), 0x00ff00ff);
    image.dispose();
    outputPicture.dispose();
    atlas.dispose();
  });
  test('exploration grid is invisible and placement grid is visible', () async {
    final overlay = MapPlacementOverlayComponent(
      width: 2,
      height: 2,
      tileSize: 32,
    );
    Future<int> alphaAtCorner() async {
      final recorder = ui.PictureRecorder();
      overlay.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(64, 64);
      final bytes = (await image.toByteData())!;
      final alpha = bytes.getUint8(3);
      image.dispose();
      picture.dispose();
      return alpha;
    }

    expect(await alphaAtCorner(), 0);
    overlay.placementMode = true;
    expect(await alphaAtCorner(), greaterThan(0));
  });
}
