import 'dart:async';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements GameStorage {}

MapCatalog _catalog() => MapCatalog.fromJson({
  'schemaVersion': 1,
  'atlasAsset': 'assets/maps/atlas.png',
  'initialMapId': 'lab',
  'tiles': [],
  'prefabs': [],
  'maps': [
    {
      'id': 'lab',
      'name': 'Lab',
      'width': 6,
      'height': 5,
      'spawns': {
        'entry': [1, 1],
      },
      'terminalPosition': [0, 0],
      'layers': [],
      'objects': [],
      'portals': [],
    },
  ],
});

void main() {
  test(
    'waits for catalog before ready and restores persisted room definitions',
    () async {
      final catalog = _catalog();
      final saved = GameModel.fromJson(
        catalog.createGame().copyWith(credits: 123).toJson(),
      );
      final storage = _Storage();
      when(() => storage.load()).thenAnswer((_) async => saved);
      final loader = Completer<MapCatalog>();
      final bloc = GameBloc(
        storage: storage,
        mapCatalogLoader: () => loader.future,
      );
      addTearDown(bloc.close);
      final ready = bloc.stream.firstWhere((state) => state is GameReady);
      bloc.add(const GameInitialize());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<GameLoading>());
      expect(bloc.mapCatalog, isNull);
      loader.complete(catalog);
      final model = ((await ready) as GameReady).model;
      expect(model.currentRoom.definition, same(catalog.maps['lab']));
      expect(model.currentRoom.id, saved.currentRoom.id);
      expect(model.credits, 123);
      expect(bloc.mapCatalog, same(catalog));
    },
  );

  test(
    'new map game uses catalog spawn and loader errors become GameError',
    () async {
      final storage = _Storage();
      when(() => storage.load()).thenAnswer((_) async => null);
      final bloc = GameBloc(
        storage: storage,
        mapCatalogLoader: () async => _catalog(),
      );
      addTearDown(bloc.close);
      final ready = bloc.stream.first;
      bloc.add(const GameInitialize());
      expect(
        ((await ready) as GameReady).model.playerPosition,
        const GridPosition(1, 1),
      );
      final failed = GameBloc(
        storage: storage,
        mapCatalogLoader: () async =>
            throw const FormatException('bad catalog'),
      );
      addTearDown(failed.close);
      final error = failed.stream.first;
      failed.add(const GameInitialize());
      expect(
        await error,
        isA<GameError>().having(
          (e) => e.message,
          'message',
          contains('bad catalog'),
        ),
      );
    },
  );
}
