import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// A cloud service object placed in a room
class CloudServiceModel extends Equatable with GridOccupancy {
  final String id;
  final String name;
  final CloudProvider provider;
  final ServiceCategory category;
  final String serviceType; // e.g., "EC2", "S3", "Cloud Run"
  @override
  final GridPosition position;
  @override
  final int width;
  @override
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

  @override
  String toString() =>
      'CloudServiceModel(id: $id, provider: $provider, type: $serviceType, '
      'position: $position)';
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

  static const List<CloudServiceTemplate> azureServices = [
    CloudServiceTemplate(
      provider: CloudProvider.azure,
      category: ServiceCategory.compute,
      serviceType: 'VM',
      name: 'Virtual Machine',
      description: 'Azure virtual machine',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.azure,
      category: ServiceCategory.storage,
      serviceType: 'BlobStorage',
      name: 'Blob Storage',
      description: 'Object storage',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.azure,
      category: ServiceCategory.database,
      serviceType: 'CosmosDB',
      name: 'Cosmos DB',
      description: 'Globally distributed database',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.azure,
      category: ServiceCategory.serverless,
      serviceType: 'Functions',
      name: 'Azure Functions',
      description: 'Serverless compute',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.azure,
      category: ServiceCategory.container,
      serviceType: 'AKS',
      name: 'AKS Cluster',
      description: 'Managed Kubernetes',
    ),
  ];

  static const List<CloudServiceTemplate> digitalOceanServices = [
    CloudServiceTemplate(
      provider: CloudProvider.digitalOcean,
      category: ServiceCategory.compute,
      serviceType: 'Droplet',
      name: 'Droplet',
      description: 'Virtual machine',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.digitalOcean,
      category: ServiceCategory.storage,
      serviceType: 'Spaces',
      name: 'Spaces',
      description: 'S3-compatible object storage',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.digitalOcean,
      category: ServiceCategory.database,
      serviceType: 'ManagedDB',
      name: 'Managed Database',
      description: 'Managed PostgreSQL/MySQL/Redis',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.digitalOcean,
      category: ServiceCategory.container,
      serviceType: 'DOKS',
      name: 'DOKS Cluster',
      description: 'Managed Kubernetes',
    ),
    CloudServiceTemplate(
      provider: CloudProvider.digitalOcean,
      category: ServiceCategory.serverless,
      serviceType: 'AppPlatform',
      name: 'App Platform',
      description: 'PaaS for apps',
    ),
  ];

  /// Returns all available service templates for a specific cloud provider.
  ///
  /// Returns an empty list if the provider is [CloudProvider.none].
  static List<CloudServiceTemplate> getServicesForProvider(
    CloudProvider provider,
  ) {
    return switch (provider) {
      CloudProvider.aws => awsServices,
      CloudProvider.gcp => gcpServices,
      CloudProvider.vultr => vultrServices,
      CloudProvider.cloudflare => cloudflareServices,
      CloudProvider.azure => azureServices,
      CloudProvider.digitalOcean => digitalOceanServices,
      CloudProvider.none => [],
    };
  }

  /// Get all available services from all providers
  static List<CloudServiceTemplate> get allServices => [
    ...awsServices,
    ...gcpServices,
    ...vultrServices,
    ...cloudflareServices,
    ...azureServices,
    ...digitalOceanServices,
  ];
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

  @override
  String toString() =>
      'CloudServiceTemplate(provider: $provider, type: $serviceType, '
      'name: $name)';
}
