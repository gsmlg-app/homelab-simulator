import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// A cloud service object placed in a room
class CloudServiceModel extends Equatable {
  final String id;
  final String name;
  final CloudProvider provider;
  final ServiceCategory category;
  final String serviceType; // e.g., "EC2", "S3", "Cloud Run"
  final GridPosition position;
  final int width;
  final int height;
  final Map<String, dynamic> metadata;

  const CloudServiceModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.serviceType,
    required this.position,
    this.width = 1,
    this.height = 1,
    this.metadata = const {},
  });

  /// Get all cells occupied by this service
  List<GridPosition> get occupiedCells {
    final cells = <GridPosition>[];
    for (var dx = 0; dx < width; dx++) {
      for (var dy = 0; dy < height; dy++) {
        cells.add(GridPosition(position.x + dx, position.y + dy));
      }
    }
    return cells;
  }

  /// Check if this service occupies a specific cell
  bool occupiesCell(GridPosition cell) {
    return cell.x >= position.x &&
        cell.x < position.x + width &&
        cell.y >= position.y &&
        cell.y < position.y + height;
  }

  CloudServiceModel copyWith({
    String? id,
    String? name,
    CloudProvider? provider,
    ServiceCategory? category,
    String? serviceType,
    GridPosition? position,
    int? width,
    int? height,
    Map<String, dynamic>? metadata,
  }) {
    return CloudServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'category': category.name,
        'serviceType': serviceType,
        'position': position.toJson(),
        'width': width,
        'height': height,
        'metadata': metadata,
      };

  factory CloudServiceModel.fromJson(Map<String, dynamic> json) {
    return CloudServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: CloudProvider.values.byName(json['provider'] as String),
      category: ServiceCategory.values.byName(json['category'] as String),
      serviceType: json['serviceType'] as String,
      position: GridPosition.fromJson(json['position'] as Map<String, dynamic>),
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        provider,
        category,
        serviceType,
        position,
        width,
        height,
        metadata,
      ];
}

/// Catalog of available cloud services
class CloudServiceCatalog {
  static const List<CloudServiceTemplate> awsServices = [
    CloudServiceTemplate(
      provider: CloudProvider.aws,
      category: ServiceCategory.compute,
      serviceType: 'EC2',
      name: 'EC2 Instance',
      description: 'Virtual compute instance',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.aws,
      category: ServiceCategory.storage,
      serviceType: 'S3',
      name: 'S3 Bucket',
      description: 'Object storage',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.aws,
      category: ServiceCategory.database,
      serviceType: 'RDS',
      name: 'RDS Database',
      description: 'Managed relational database',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.aws,
      category: ServiceCategory.serverless,
      serviceType: 'Lambda',
      name: 'Lambda Function',
      description: 'Serverless compute',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.aws,
      category: ServiceCategory.container,
      serviceType: 'ECS',
      name: 'ECS Cluster',
      description: 'Container orchestration',
    ),
  ];

  static const List<CloudServiceTemplate> gcpServices = [
    CloudServiceTemplate(
      provider: CloudProvider.gcp,
      category: ServiceCategory.compute,
      serviceType: 'ComputeEngine',
      name: 'Compute Engine',
      description: 'Virtual machine instance',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.gcp,
      category: ServiceCategory.storage,
      serviceType: 'CloudStorage',
      name: 'Cloud Storage',
      description: 'Object storage',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.gcp,
      category: ServiceCategory.serverless,
      serviceType: 'CloudRun',
      name: 'Cloud Run',
      description: 'Serverless containers',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.gcp,
      category: ServiceCategory.container,
      serviceType: 'GKE',
      name: 'GKE Cluster',
      description: 'Managed Kubernetes',
    ),
  ];

  static const List<CloudServiceTemplate> vultrServices = [
    CloudServiceTemplate(
      provider: CloudProvider.vultr,
      category: ServiceCategory.compute,
      serviceType: 'VPS',
      name: 'Cloud Compute',
      description: 'Virtual private server',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.vultr,
      category: ServiceCategory.storage,
      serviceType: 'BlockStorage',
      name: 'Block Storage',
      description: 'Persistent block storage',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.vultr,
      category: ServiceCategory.container,
      serviceType: 'K8s',
      name: 'Kubernetes',
      description: 'Managed Kubernetes',
    ),
  ];

  static const List<CloudServiceTemplate> cloudflareServices = [
    CloudServiceTemplate(
      provider: CloudProvider.cloudflare,
      category: ServiceCategory.networking,
      serviceType: 'DNS',
      name: 'DNS Zone',
      description: 'DNS management',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.cloudflare,
      category: ServiceCategory.serverless,
      serviceType: 'Workers',
      name: 'Workers',
      description: 'Edge serverless functions',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.cloudflare,
      category: ServiceCategory.storage,
      serviceType: 'R2',
      name: 'R2 Storage',
      description: 'S3-compatible object storage',
    ),
  ];

  static List<CloudServiceTemplate> getServicesForProvider(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.aws:
        return awsServices;
      case CloudProvider.gcp:
        return gcpServices;
      case CloudProvider.vultr:
        return vultrServices;
      case CloudProvider.cloudflare:
        return cloudflareServices;
      default:
        return [];
    }
  }
}

/// Template for creating cloud service instances
class CloudServiceTemplate {
  final CloudProvider provider;
  final ServiceCategory category;
  final String serviceType;
  final String name;
  final String description;
  final int width;
  final int height;

  const CloudServiceTemplate({
    required this.provider,
    required this.category,
    required this.serviceType,
    required this.name,
    required this.description,
    this.width = 1,
    this.height = 1,
  });
}
