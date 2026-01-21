import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// A placed device in the game world
class DeviceModel extends Equatable with GridOccupancy {
  final String id;
  final String templateId;
  final String name;
  final DeviceType type;
  @override
  final GridPosition position;
  @override
  final int width;
  @override
  final int height;
  final bool isRunning;

  const DeviceModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.position,
    this.width = 1,
    this.height = 1,
    this.isRunning = false,
  });

  DeviceModel copyWith({
    String? id,
    String? templateId,
    String? name,
    DeviceType? type,
    GridPosition? position,
    int? width,
    int? height,
    bool? isRunning,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'name': name,
    'type': type.name,
    'position': position.toJson(),
    'width': width,
    'height': height,
    'isRunning': isRunning,
  };

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      type: DeviceType.values.byName(json['type'] as String),
      position: GridPosition.fromJson(json['position'] as Map<String, dynamic>),
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
      isRunning: json['isRunning'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    templateId,
    name,
    type,
    position,
    width,
    height,
    isRunning,
  ];
}
