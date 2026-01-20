import 'package:bloc/bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_database/app_database.dart';

import 'game_event.dart';
import 'game_state.dart';

/// Flutter/UI-level BLoC managing global game state
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameStorage _storage;

  GameBloc({GameStorage? storage})
    : _storage = storage ?? GameStorage(),
      super(const GameLoading()) {
    on<GameInitialize>(_onInitialize);
    on<GameMovePlayer>(_onMovePlayer);
    on<GameMovePlayerTo>(_onMovePlayerTo);
    on<GameToggleShop>(_onToggleShop);
    on<GameSelectTemplate>(_onSelectTemplate);
    on<GameCancelPlacement>(_onCancelPlacement);
    on<GamePlaceDevice>(_onPlaceDevice);
    on<GameRemoveDevice>(_onRemoveDevice);
    on<GameChangeMode>(_onChangeMode);
    on<GameSave>(_onSave);
    on<GameEnterRoom>(_onEnterRoom);
    on<GameAddRoom>(_onAddRoom);
    on<GameRemoveRoom>(_onRemoveRoom);
    on<GameSelectCloudService>(_onSelectCloudService);
    on<GamePlaceCloudService>(_onPlaceCloudService);
    on<GameRemoveCloudService>(_onRemoveCloudService);
  }

  GameModel? get currentModel {
    final s = state;
    return s is GameReady ? s.model : null;
  }

  Future<void> _onInitialize(
    GameInitialize event,
    Emitter<GameState> emit,
  ) async {
    try {
      final saved = await _storage.load();
      final model = saved ?? GameModel.initial();
      emit(GameReady(model));
    } catch (e) {
      emit(GameError('Failed to initialize: $e'));
    }
  }

  void _onMovePlayer(GameMovePlayer event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final delta = switch (event.direction) {
      Direction.up => const GridPosition(0, -1),
      Direction.down => const GridPosition(0, 1),
      Direction.left => const GridPosition(-1, 0),
      Direction.right => const GridPosition(1, 0),
      Direction.none => const GridPosition(0, 0),
    };

    final newPos = model.playerPosition + delta;
    final newModel = reduce(model, PlayerMoved(newPos));
    emit(GameReady(newModel));
  }

  void _onMovePlayerTo(GameMovePlayerTo event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, PlayerMoved(event.position));
    emit(GameReady(newModel));
  }

  void _onToggleShop(GameToggleShop event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final isOpen = event.isOpen ?? !model.shopOpen;
    final newModel = reduce(model, ShopToggled(isOpen));
    emit(GameReady(newModel));
  }

  void _onSelectTemplate(GameSelectTemplate event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, TemplateSelected(event.template));
    emit(GameReady(newModel.copyWith(shopOpen: false)));
  }

  void _onCancelPlacement(GameCancelPlacement event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(
      model,
      const PlacementModeChanged(PlacementMode.none),
    );
    emit(GameReady(newModel));
  }

  Future<void> _onPlaceDevice(
    GamePlaceDevice event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;
    if (model.selectedTemplate == null) return;

    final newModel = reduce(
      model,
      DevicePlaced(
        templateId: model.selectedTemplate!.id,
        position: event.position,
      ),
    );

    emit(GameReady(newModel));

    // Auto-save after placement
    await _storage.save(newModel);
  }

  Future<void> _onRemoveDevice(
    GameRemoveDevice event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, DeviceRemoved(event.deviceId));
    emit(GameReady(newModel));

    // Auto-save after removal
    await _storage.save(newModel);
  }

  void _onChangeMode(GameChangeMode event, Emitter<GameState> emit) {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, GameModeChanged(event.mode));
    emit(GameReady(newModel));
  }

  Future<void> _onSave(GameSave event, Emitter<GameState> emit) async {
    final model = currentModel;
    if (model == null) return;

    await _storage.save(model);
  }

  Future<void> _onEnterRoom(
    GameEnterRoom event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;

    // Verify the target room exists
    if (model.getRoomById(event.roomId) == null) return;

    final newModel = reduce(
      model,
      RoomEntered(roomId: event.roomId, spawnPosition: event.spawnPosition),
    );

    emit(GameReady(newModel));

    // Auto-save after room transition
    await _storage.save(newModel);
  }

  Future<void> _onAddRoom(GameAddRoom event, Emitter<GameState> emit) async {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(
      model,
      RoomAdded(
        name: event.name,
        type: event.type,
        regionCode: event.regionCode,
        doorSide: event.doorSide,
        doorPosition: event.doorPosition,
      ),
    );

    emit(GameReady(newModel));

    // Auto-save after adding room
    await _storage.save(newModel);
  }

  Future<void> _onRemoveRoom(
    GameRemoveRoom event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, RoomRemoved(event.roomId));

    emit(GameReady(newModel));

    // Auto-save after removing room
    await _storage.save(newModel);
  }

  void _onSelectCloudService(
    GameSelectCloudService event,
    Emitter<GameState> emit,
  ) {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, CloudServiceSelected(event.template));
    emit(GameReady(newModel.copyWith(shopOpen: false)));
  }

  Future<void> _onPlaceCloudService(
    GamePlaceCloudService event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;
    if (model.selectedCloudService == null) return;

    final template = model.selectedCloudService!;
    final newModel = reduce(
      model,
      CloudServicePlaced(
        provider: template.provider,
        category: template.category,
        serviceType: template.serviceType,
        name: template.name,
        position: event.position,
      ),
    );

    emit(GameReady(newModel));

    // Auto-save after placement
    await _storage.save(newModel);
  }

  Future<void> _onRemoveCloudService(
    GameRemoveCloudService event,
    Emitter<GameState> emit,
  ) async {
    final model = currentModel;
    if (model == null) return;

    final newModel = reduce(model, CloudServiceRemoved(event.serviceId));
    emit(GameReady(newModel));

    // Auto-save after removal
    await _storage.save(newModel);
  }
}
