import 'package:app_lib_core/app_lib_core.dart';

import 'models/cloud_console_model.dart';
import 'models/door_model.dart';
import 'models/game_model.dart';
import 'models/room_model.dart';

abstract final class CloudCenterIds {
  static const room = 'cloud-center';
  static const entrance = 'cloud-center:entrance';
  static const exit = 'cloud-center:exit';
  static const cloudflare = 'cloud-center:cloudflare';
  static const aws = 'cloud-center:aws';
  static const gcp = 'cloud-center:gcp';
  static const overview = 'cloud-center:overview';
}

RoomModel createCloudCenterRoom({String? parentId}) {
  const width = 20;
  const height = 12;
  CloudConsoleModel console(
    String id,
    int x,
    int y,
    CloudConsoleTarget target,
  ) => CloudConsoleModel(
    id: id,
    roomId: CloudCenterIds.room,
    position: GridPosition(x, y),
    target: target,
  );
  return RoomModel(
    id: CloudCenterIds.room,
    name: 'Cloud Center',
    type: RoomType.cloudCenter,
    parentId: parentId,
    width: width,
    height: height,
    terminalPosition: const GridPosition(0, 0),
    cloudConsoles: [
      console(
        CloudCenterIds.cloudflare,
        width ~/ 4 - 1,
        height ~/ 4,
        const ProviderConsoleTarget(CloudProvider.cloudflare),
      ),
      console(
        CloudCenterIds.aws,
        width ~/ 2 - 1,
        height ~/ 4,
        const ProviderConsoleTarget(CloudProvider.aws),
      ),
      console(
        CloudCenterIds.gcp,
        width * 3 ~/ 4 - 1,
        height ~/ 4,
        const ProviderConsoleTarget(CloudProvider.gcp),
      ),
      console(
        CloudCenterIds.overview,
        width ~/ 2 - 1,
        height * 2 ~/ 3,
        const CostOverviewTarget(),
      ),
    ],
  );
}

/// Pure, repeatable installation. Never replaces saved rooms, devices or actors.
GameModel installCloudCenter(GameModel model) {
  if (model.rooms.isEmpty) {
    return model.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.noReachableEntrance,
    );
  }
  final savedCenter = model.getRoomById(CloudCenterIds.room);
  if (savedCenter != null && savedCenter.type != RoomType.cloudCenter) {
    return model.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.roomIdConflict,
    );
  }
  var center =
      savedCenter ?? createCloudCenterRoom(parentId: model.currentRoomId);
  final expected = createCloudCenterRoom().cloudConsoles;
  center = center.copyWith(
    cloudConsoles: [
      ...center.cloudConsoles,
      ...expected.where(
        (console) =>
            !center.cloudConsoles.any((saved) => saved.id == console.id),
      ),
    ],
  );
  var result = savedCenter == null
      ? model.addRoom(center)
      : model.updateRoom(center);
  final savedExit = center.doors
      .where((door) => door.id == CloudCenterIds.exit)
      .firstOrNull;
  final sourceId =
      savedExit?.targetRoomId ?? center.parentId ?? model.currentRoomId;
  final source = result.getRoomById(sourceId);
  if (source == null || source.id == center.id) {
    return result.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.noReachableEntrance,
    );
  }
  final existing = source.doors
      .where((door) => door.id == CloudCenterIds.entrance)
      .firstOrNull;
  if (existing != null &&
      savedExit != null &&
      existing.targetRoomId == center.id &&
      source.canWalk(
        savedExit.targetSpawnPosition ??
            existing.getSpawnPosition(source.width, source.height),
      ) &&
      center.canWalk(
        existing.targetSpawnPosition ?? const GridPosition(1, 6),
      )) {
    return result.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.available,
    );
  }
  // Never overwrite a preexisting object that owns a reserved identifier.
  if (existing != null || savedExit != null) {
    return result.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.roomIdConflict,
    );
  }
  final start = source.id == model.currentRoomId
      ? model.playerPosition
      : source.definition?.spawn ?? const GridPosition(1, 1);
  final entrance = _findEntrance(source, start);
  if (entrance == null) {
    return result.copyWith(
      cloudCenterEntryStatus: CloudCenterEntryStatus.noReachableEntrance,
    );
  }
  final returnDoor = DoorModel(
    id: CloudCenterIds.exit,
    targetRoomId: source.id,
    wallSide: WallSide.left,
    wallPosition: center.height ~/ 2,
    targetSpawnPosition: entrance.spawn,
  );
  final cloudSpawn = returnDoor.getSpawnPosition(center.width, center.height);
  center = center.copyWith(
    parentId: source.id,
    doors: [...center.doors, returnDoor],
  );
  result = result
      .updateRoom(center)
      .updateRoom(
        source.addDoor(
          DoorModel(
            id: CloudCenterIds.entrance,
            targetRoomId: center.id,
            wallSide: entrance.side,
            wallPosition: entrance.wallPosition,
            gridPosition: entrance.floorGateway ? entrance.position : null,
            targetSpawnPosition: cloudSpawn,
          ),
        ),
      );
  return result.copyWith(
    cloudCenterEntryStatus: CloudCenterEntryStatus.available,
  );
}

class _Entrance {
  final GridPosition position;
  final GridPosition spawn;
  final WallSide side;
  final int wallPosition;
  final bool floorGateway;
  const _Entrance(
    this.position,
    this.spawn,
    this.side,
    this.wallPosition,
    this.floorGateway,
  );
}

_Entrance? _findEntrance(RoomModel room, GridPosition start) {
  if (!room.canWalk(start)) return null;
  bool available(GridPosition cell) =>
      room.canWalk(cell) &&
      cell != room.terminalPosition &&
      !room.hasDoorAt(cell);
  bool reachable(GridPosition cell) =>
      cell == start || room.findPath(start, cell).isNotEmpty;
  for (final side in WallSide.values) {
    final length = side == WallSide.left || side == WallSide.right
        ? room.height
        : room.width;
    for (var offset = 1; offset < length - 1; offset++) {
      final candidate = DoorModel(
        id: '',
        targetRoomId: '',
        wallSide: side,
        wallPosition: offset,
      );
      final cell = candidate.getPosition(room.width, room.height);
      final spawn = candidate.getSpawnPosition(room.width, room.height);
      if (cell != start &&
          available(cell) &&
          available(spawn) &&
          reachable(spawn)) {
        return _Entrance(cell, spawn, side, offset, false);
      }
    }
  }
  // Shipped atlas boundaries may be solid. A floor gateway leaves every map
  // tile and original portal intact, using the existing door navigation path.
  final floor =
      <GridPosition>[
        for (var y = 1; y < room.height - 1; y++)
          for (var x = 1; x < room.width - 1; x++) GridPosition(x, y),
      ]..sort((a, b) {
        int distance(GridPosition cell) =>
            (cell.x - start.x).abs() + (cell.y - start.y).abs();
        final byDistance = distance(a).compareTo(distance(b));
        return byDistance != 0
            ? byDistance
            : a.y != b.y
            ? a.y.compareTo(b.y)
            : a.x.compareTo(b.x);
      });
  for (final cell in floor) {
    if (cell == start || !available(cell) || !reachable(cell)) continue;
    for (final delta in const [
      GridPosition(0, 1),
      GridPosition(1, 0),
      GridPosition(0, -1),
      GridPosition(-1, 0),
    ]) {
      final spawn = cell + delta;
      if (available(spawn) && reachable(spawn)) {
        return _Entrance(cell, spawn, WallSide.left, cell.y, true);
      }
    }
  }
  return null;
}
