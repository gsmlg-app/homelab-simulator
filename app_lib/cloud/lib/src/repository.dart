import 'models.dart';

/// Explicitly selected storage namespaces; a real failure never selects demo.
enum CloudMode { demo, real }

final class CloudQuery {
  final DateTime? start;
  final DateTime? end;
  final String? service;
  final String? region;
  final String? project;
  final String? search;
  final String? basis;
  final String? cursor;
  final int limit;

  CloudQuery({
    this.start,
    this.end,
    this.service,
    this.region,
    this.project,
    this.search,
    this.basis,
    this.cursor,
    this.limit = 50,
  }) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Expected 1..100');
    }
    if ((start == null) != (end == null)) {
      throw ArgumentError('Both start and end are required');
    }
    if (start != null &&
        (!start!.isBefore(end!) ||
            end!.difference(start!) > const Duration(days: 93))) {
      throw ArgumentError('Window must be positive and at most 93 days');
    }
  }

  Map<String, dynamic> toJson() => {
    if (start != null) 'start': start!.toUtc().toIso8601String(),
    if (end != null) 'end': end!.toUtc().toIso8601String(),
    if (service != null) 'service': service,
    if (region != null) 'region': region,
    if (project != null) 'project': project,
    if (search != null) 'search': search,
    if (basis != null) 'basis': basis,
    if (cursor != null) 'cursor': cursor,
    'limit': limit,
  };
}

final class CloudPage<T> {
  final int schemaVersion;
  final String revision;
  final Map<String, dynamic> query;
  final T data;
  final String? nextCursor;

  CloudPage({
    this.schemaVersion = 1,
    required this.revision,
    required Map<String, dynamic> query,
    required this.data,
    this.nextCursor,
  }) : query = Map.unmodifiable(query) {
    if (schemaVersion != 1) {
      throw FormatException('Unsupported schemaVersion: $schemaVersion');
    }
    if (revision.isEmpty) throw const FormatException('Missing revision');
  }

  factory CloudPage.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) decode,
  ) => CloudPage(
    schemaVersion: json['schemaVersion'] as int,
    revision: json['revision'] as String,
    query: json['query'] as Map<String, dynamic>,
    data: decode(json['data']),
    nextCursor: json['nextCursor'] as String?,
  );
}

final class CloudOverview {
  final List<CostTotal> totals;
  final List<CostTotal> unmappedTotals;
  final List<CloudConnection> connections;
  final List<String> coverage;
  CloudOverview({
    required Iterable<CostTotal> totals,
    Iterable<CostTotal> unmappedTotals = const [],
    required Iterable<CloudConnection> connections,
    required Iterable<String> coverage,
  }) : totals = List.unmodifiable(totals),
       unmappedTotals = List.unmodifiable(unmappedTotals),
       connections = List.unmodifiable(connections),
       coverage = List.unmodifiable(coverage);

  factory CloudOverview.fromJson(Map<String, dynamic> json) => CloudOverview(
    unmappedTotals: ((json['unmappedTotals'] as List?) ?? []).map(
      (e) => CostTotal.fromJson(e as Map<String, dynamic>),
    ),
    totals: (json['totals'] as List).map(
      (e) => CostTotal.fromJson(e as Map<String, dynamic>),
    ),
    connections: (json['connections'] as List).map(
      (e) => CloudConnection.fromJson(e as Map<String, dynamic>),
    ),
    coverage: List<String>.from(json['coverage'] as List),
  );
}

final class ConnectionOverview {
  final CloudConnection connection;
  final List<CostTotal> totals;
  final List<CostTotal> unmappedTotals;
  final int resourceCount;
  final Map<String, DatasetStatus> statuses;
  ConnectionOverview({
    required this.connection,
    required Iterable<CostTotal> totals,
    Iterable<CostTotal> unmappedTotals = const [],
    required this.resourceCount,
    required Map<String, DatasetStatus> statuses,
  }) : totals = List.unmodifiable(totals),
       unmappedTotals = List.unmodifiable(unmappedTotals),
       statuses = Map.unmodifiable(statuses);

  factory ConnectionOverview.fromJson(Map<String, dynamic> json) =>
      ConnectionOverview(
        connection: CloudConnection.fromJson(
          json['connection'] as Map<String, dynamic>,
        ),
        unmappedTotals: ((json['unmappedTotals'] as List?) ?? []).map(
          (e) => CostTotal.fromJson(e as Map<String, dynamic>),
        ),
        totals: (json['totals'] as List).map(
          (e) => CostTotal.fromJson(e as Map<String, dynamic>),
        ),
        resourceCount: json['resourceCount'] as int,
        statuses: (json['statuses'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, DatasetStatus.fromJson(v as Map<String, dynamic>)),
        ),
      );
}

final class SyncJob {
  final String id;
  final String state;
  final String? connectionId;
  final String? dataset;
  final int? attempts;
  final String? errorCode;
  const SyncJob({
    required this.id,
    required this.state,
    this.connectionId,
    this.dataset,
    this.attempts,
    this.errorCode,
  });
  factory SyncJob.fromJson(Map<String, dynamic> json) => SyncJob(
    id: json['id'] as String,
    state: json['state'] as String,
    connectionId: json['connectionId'] as String?,
    dataset: json['dataset'] as String?,
    attempts: json['attempts'] as int?,
    errorCode: json['errorCode'] as String?,
  );
}

final class CloudFailure implements Exception {
  final String code;
  final String message;
  const CloudFailure(this.code, this.message);
  @override
  String toString() => 'CloudFailure($code): $message';
}

/// A UI request token, never a server collection-job cancellation token.
final class CloudCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const CloudFailure('cancelled', 'Request cancelled');
  }
}

abstract interface class CloudRepository {
  CloudMode get mode;
  String get cacheNamespace;
  Future<CloudPage<List<CloudConnection>>> connections({
    CloudCancellation? cancellation,
  });
  Future<CloudPage<CloudOverview>> overview(
    CloudQuery query, {
    CloudCancellation? cancellation,
  });
  Future<CloudPage<ConnectionOverview>> connectionOverview(
    String connectionId,
    CloudQuery query, {
    CloudCancellation? cancellation,
  });
  Future<CloudPage<List<CostRecord>>> costs(
    String connectionId,
    CloudQuery query, {
    CloudCancellation? cancellation,
  });
  Future<CloudPage<List<CloudResource>>> resources(
    String connectionId,
    CloudQuery query, {
    CloudCancellation? cancellation,
  });
  Future<CloudPage<List<UsageSample>>> usage(
    String resourceId,
    CloudQuery query, {
    CloudCancellation? cancellation,
  });
  Future<SyncJob> sync(
    String connectionId, {
    String? dataset,
    CloudCancellation? cancellation,
  });
  Future<CloudPage<SyncJob>> syncJob(
    String id, {
    CloudCancellation? cancellation,
  });
  Future<CloudPage<List<BudgetRule>>> budgets({
    CloudCancellation? cancellation,
  });
  Future<BudgetRule> saveBudget(
    BudgetRule rule, {
    CloudCancellation? cancellation,
  });
}
