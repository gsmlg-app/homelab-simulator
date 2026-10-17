import 'package:app_lib_core/app_lib_core.dart';
import 'models/room_model.dart';

final class InteractionTarget {
  final String id;
  final InteractionType type;
  final int distance;
  const InteractionTarget(this.id, this.type, this.distance);
}

/// One ranking for doors, consoles and the shop; proximity never activates it.
InteractionTarget? selectInteractionTarget(
  RoomModel room,
  GridPosition player,
) {
  int distance(GridPosition point) =>
      (point.x - player.x).abs() + (point.y - player.y).abs();
  final candidates =
      [
        for (final door in room.doors)
          InteractionTarget(
            door.id,
            InteractionType.door,
            distance(door.getPosition(room.width, room.height)),
          ),
        if (room.type != RoomType.cloudCenter)
          InteractionTarget(
            GameConstants.terminalEntityId,
            InteractionType.terminal,
            distance(room.terminalPosition),
          ),
        for (final console in room.cloudConsoles)
          InteractionTarget(
            console.id,
            InteractionType.cloudConsole,
            console.distanceTo(player),
          ),
      ].where((candidate) => candidate.distance <= 1).toList()..sort((a, b) {
        final byDistance = a.distance.compareTo(b.distance);
        return byDistance != 0 ? byDistance : a.id.compareTo(b.id);
      });
  return candidates.firstOrNull;
}
