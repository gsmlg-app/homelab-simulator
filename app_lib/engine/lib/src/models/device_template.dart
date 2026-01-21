import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Template for purchasable devices
class DeviceTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final DeviceType type;
  final int cost;
  final int width;
  final int height;

  const DeviceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    this.width = 1,
    this.height = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'cost': cost,
    'width': width,
    'height': height,
  };

  factory DeviceTemplate.fromJson(Map<String, dynamic> json) {
    return DeviceTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: DeviceType.values.byName(json['type'] as String),
      cost: json['cost'] as int,
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
    );
  }

  DeviceTemplate copyWith({
    String? id,
    String? name,
    String? description,
    DeviceType? type,
    int? cost,
    int? width,
    int? height,
  }) {
    return DeviceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [id, name, description, type, cost, width, height];

  @override
  String toString() =>
      'DeviceTemplate(id: $id, name: $name, type: $type, cost: $cost)';
}

/// Default device templates available in the shop
const defaultDeviceTemplates = [
  DeviceTemplate(
    id: 'server_basic',
    name: 'Basic Server',
    description: 'A simple rack server for running services',
    type: DeviceType.server,
    cost: 500,
  ),
  DeviceTemplate(
    id: 'server_pro',
    name: 'Pro Server',
    description: 'High-performance server with more resources',
    type: DeviceType.server,
    cost: 1200,
  ),
  DeviceTemplate(
    id: 'computer_desktop',
    name: 'Desktop PC',
    description: 'A workstation computer',
    type: DeviceType.computer,
    cost: 300,
  ),
  DeviceTemplate(
    id: 'router_basic',
    name: 'Router',
    description: 'Network router for connectivity',
    type: DeviceType.router,
    cost: 150,
  ),
  DeviceTemplate(
    id: 'switch_8port',
    name: '8-Port Switch',
    description: 'Network switch with 8 ports',
    type: DeviceType.switch_,
    cost: 100,
  ),
  DeviceTemplate(
    id: 'nas_4bay',
    name: '4-Bay NAS',
    description: 'Network attached storage with 4 drive bays',
    type: DeviceType.nas,
    cost: 400,
  ),
  DeviceTemplate(
    id: 'iot_sensor',
    name: 'IoT Sensor',
    description: 'Environmental monitoring sensor',
    type: DeviceType.iot,
    cost: 50,
  ),
];
