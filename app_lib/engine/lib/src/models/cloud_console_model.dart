import 'package:app_lib_core/app_lib_core.dart';
import 'package:equatable/equatable.dart';

sealed class CloudConsoleTarget extends Equatable {
  const CloudConsoleTarget();
  Map<String, dynamic> toJson();

  factory CloudConsoleTarget.fromJson(Map<String, dynamic> json) =>
      switch (json['kind']) {
        'provider' => ProviderConsoleTarget(
          CloudProvider.values.byName(json['provider'] as String),
        ),
        'overview' => const CostOverviewTarget(),
        _ => throw const FormatException('Unknown cloud console target'),
      };
}

final class ProviderConsoleTarget extends CloudConsoleTarget {
  final CloudProvider provider;
  const ProviderConsoleTarget(this.provider)
    : assert(
        provider == CloudProvider.cloudflare ||
            provider == CloudProvider.aws ||
            provider == CloudProvider.gcp,
      );
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'provider',
    'provider': provider.name,
  };
  @override
  List<Object?> get props => [provider];
}

final class CostOverviewTarget extends CloudConsoleTarget {
  const CostOverviewTarget();
  @override
  Map<String, dynamic> toJson() => {'kind': 'overview'};
  @override
  List<Object?> get props => [];
}

/// A stable data entrance; never one object per monitored cloud resource.
final class CloudConsoleModel extends Equatable {
  final String id;
  final String roomId;
  final GridPosition position;
  final int width;
  final int height;
  final CloudConsoleTarget target;

  const CloudConsoleModel({
    required this.id,
    required this.roomId,
    required this.position,
    required this.target,
    this.width = 2,
    this.height = 2,
  });

  bool occupiesCell(GridPosition cell) =>
      cell.x >= position.x &&
      cell.x < position.x + width &&
      cell.y >= position.y &&
      cell.y < position.y + height;

  int distanceTo(GridPosition cell) {
    final dx = cell.x < position.x
        ? position.x - cell.x
        : cell.x >= position.x + width
        ? cell.x - position.x - width + 1
        : 0;
    final dy = cell.y < position.y
        ? position.y - cell.y
        : cell.y >= position.y + height
        ? cell.y - position.y - height + 1
        : 0;
    return dx + dy;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'position': position.toJson(),
    'width': width,
    'height': height,
    'target': target.toJson(),
  };
  factory CloudConsoleModel.fromJson(
    Map<String, dynamic> json,
  ) => CloudConsoleModel(
    id: json['id'] as String,
    roomId: json['roomId'] as String,
    position: GridPosition.fromJson(json['position'] as Map<String, dynamic>),
    width: json['width'] as int? ?? 2,
    height: json['height'] as int? ?? 2,
    target: CloudConsoleTarget.fromJson(json['target'] as Map<String, dynamic>),
  );
  @override
  List<Object?> get props => [id, roomId, position, width, height, target];
}

enum CloudCenterEntryStatus {
  notInstalled,
  available,
  noReachableEntrance,
  roomIdConflict,
}
