import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements GameStorage {}

void main() {
  setUpAll(() => registerFallbackValue(GameModel.initial()));
  test(
    'authoritative modal lock rejects scene edits and does not save rejected actions',
    () async {
      final storage = _Storage();
      when(() => storage.load()).thenAnswer((_) async => GameModel.initial());
      when(() => storage.save(any())).thenAnswer((_) async {});
      final bloc = GameBloc(storage: storage);
      addTearDown(bloc.close);
      final ready = bloc.stream.first;
      bloc.add(const GameInitialize());
      await ready;
      final opened = bloc.stream.firstWhere(
        (state) => state is GameReady && state.model.cloudPanelOpen,
      );
      bloc.add(const GameSetCloudPanelOpen(true));
      await opened;
      final locked = bloc.currentModel!;
      final target = locked.playerPosition + const GridPosition(0, 1);
      for (final event in <GameEvent>[
        const GameMovePlayer(Direction.down),
        GameMovePlayerTo(target),
        const GameToggleShop(isOpen: true),
        GameSelectTemplate(defaultDeviceTemplates.first),
        GamePlaceDevice(target),
        const GameRemoveDevice('saved'),
        const GameSelectCloudService(
          CloudServiceTemplate(
            provider: CloudProvider.aws,
            category: ServiceCategory.compute,
            serviceType: 'EC2',
            name: 'EC2',
            description: 'Compute',
          ),
        ),
        GamePlaceCloudService(target),
        const GameRemoveCloudService('saved'),
        const GameAddRoom(
          name: 'Blocked',
          type: RoomType.custom,
          doorSide: WallSide.top,
          doorPosition: 2,
        ),
        const GameRemoveRoom(CloudCenterIds.room),
      ]) {
        bloc.add(event);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.currentModel, locked);
      verifyNever(() => storage.save(any()));
      final closed = bloc.stream.firstWhere(
        (state) => state is GameReady && !state.model.cloudPanelOpen,
      );
      bloc.add(const GameSetCloudPanelOpen(false));
      await closed;
      final moved = bloc.stream.firstWhere(
        (state) => state is GameReady && state.model.playerPosition == target,
      );
      bloc.add(GameMovePlayerTo(target));
      await moved;
      expect(bloc.currentModel!.playerPosition, target);
    },
  );
}
