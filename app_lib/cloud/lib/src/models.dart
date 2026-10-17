import 'package:app_lib_core/enums.dart' show CloudProvider;

import 'decimal_amount.dart';

enum DatasetState {
  unconfigured,
  waiting,
  empty,
  partial,
  available,
  stale,
  permissionDenied,
  authenticationFailed,
  unsupported,
  rateLimited,
  failed,
}

enum CostCategory {
  usage,
  subscription,
  tax,
  credit,
  refund,
  adjustment,
  unknown,
}

enum CostView { period, cumulative, invoice, detail }

enum RecordKind { reported }

enum BudgetState { disabled, unknown, withinBudget, warning, exceeded }

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid $key');
  return value;
}

T _enum<T extends Enum>(List<T> values, Map<String, dynamic> json, String key) {
  final name = _string(json, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $key: $name');
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = _string(json, key);
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw FormatException('Date $key must include a timezone');
  }
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : _date(json, key);
DecimalAmount _decimal(Map<String, dynamic> json, String key) =>
    DecimalAmount.parse(_string(json, key));
void _window(DateTime start, DateTime end) {
  if (!start.isBefore(end)) {
    throw ArgumentError('Expected half-open start < end');
  }
}

final class DatasetStatus {
  final DatasetState state;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final DateTime? sourceAsOf;
  final DateTime? observedStart;
  final DateTime? observedEnd;
  final bool complete;
  final String? reason;

  DatasetStatus({
    required this.state,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.sourceAsOf,
    this.observedStart,
    this.observedEnd,
    required this.complete,
    this.reason,
  });

  factory DatasetStatus.fromJson(Map<String, dynamic> json) => DatasetStatus(
    state: _enum(DatasetState.values, json, 'state'),
    lastAttemptAt: _optionalDate(json, 'lastAttemptAt'),
    lastSuccessAt: _optionalDate(json, 'lastSuccessAt'),
    sourceAsOf: _optionalDate(json, 'sourceAsOf'),
    observedStart: _optionalDate(json, 'observedStart'),
    observedEnd: _optionalDate(json, 'observedEnd'),
    complete: json['complete'] as bool,
    reason: _optionalString(json, 'reason'),
  );

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'lastAttemptAt': lastAttemptAt?.toUtc().toIso8601String(),
    'lastSuccessAt': lastSuccessAt?.toUtc().toIso8601String(),
    'sourceAsOf': sourceAsOf?.toUtc().toIso8601String(),
    'observedStart': observedStart?.toUtc().toIso8601String(),
    'observedEnd': observedEnd?.toUtc().toIso8601String(),
    'complete': complete,
    'reason': reason,
  };
}

final class CloudConnection {
  final String id;
  final CloudProvider provider;
  final String displayName;
  final String billingScopeId;
  final Map<String, String> capabilities;
  final Map<String, DatasetStatus> statuses;

  CloudConnection({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.billingScopeId,
    required Map<String, String> capabilities,
    required Map<String, DatasetStatus> statuses,
  }) : capabilities = Map.unmodifiable(capabilities),
       statuses = Map.unmodifiable(statuses);

  factory CloudConnection.fromJson(Map<String, dynamic> json) =>
      CloudConnection(
        id: _string(json, 'id'),
        provider: _enum(CloudProvider.values, json, 'provider'),
        displayName: _string(json, 'displayName'),
        billingScopeId: _string(json, 'billingScopeId'),
        capabilities: Map<String, String>.from(json['capabilities'] as Map),
        statuses: (json['statuses'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, DatasetStatus.fromJson(v as Map<String, dynamic>)),
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'displayName': displayName,
    'billingScopeId': billingScopeId,
    'capabilities': capabilities,
    'statuses': statuses.map((k, v) => MapEntry(k, v.toJson())),
  };
}

final class BillingScope {
  final String id;
  final CloudProvider provider;
  final String? parentId;
  final String accountId;
  final String authoritativeConnectionId;

  BillingScope({
    required this.id,
    required this.provider,
    this.parentId,
    required this.accountId,
    required this.authoritativeConnectionId,
  });

  factory BillingScope.fromJson(Map<String, dynamic> json) => BillingScope(
    id: _string(json, 'id'),
    provider: _enum(CloudProvider.values, json, 'provider'),
    parentId: _optionalString(json, 'parentId'),
    accountId: _string(json, 'accountId'),
    authoritativeConnectionId: _string(json, 'authoritativeConnectionId'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'parentId': parentId,
    'accountId': accountId,
    'authoritativeConnectionId': authoritativeConnectionId,
  };
}

final class CostRecord {
  final String id;
  final String connectionId;
  final String billingScopeId;
  final String service;
  final String? resourceId;
  final DateTime start;
  final DateTime end;
  final String currency;
  final DecimalAmount amount;
  final String basis;
  final CostCategory category;
  final bool? estimated;
  final String source;
  final String sourcePrecision;
  final String? invoiceMonth;
  final RecordKind recordKind;
  final CostView view;
  final List<String> coverage;

  CostRecord({
    required this.id,
    required this.connectionId,
    required this.billingScopeId,
    required this.service,
    this.resourceId,
    required this.start,
    required this.end,
    required this.currency,
    required this.amount,
    required this.basis,
    required this.category,
    this.estimated,
    required this.source,
    required this.sourcePrecision,
    this.invoiceMonth,
    required this.recordKind,
    required this.view,
    required List<String> coverage,
  }) : coverage = List.unmodifiable(coverage) {
    _window(start, end);
  }

  factory CostRecord.fromJson(Map<String, dynamic> json) => CostRecord(
    id: _string(json, 'id'),
    connectionId: _string(json, 'connectionId'),
    billingScopeId: _string(json, 'billingScopeId'),
    service: _string(json, 'service'),
    resourceId: _optionalString(json, 'resourceId'),
    start: _date(json, 'start'),
    end: _date(json, 'end'),
    currency: _string(json, 'currency'),
    amount: _decimal(json, 'amount'),
    basis: _string(json, 'basis'),
    category: _enum(CostCategory.values, json, 'category'),
    estimated: json['estimated'] as bool?,
    source: _string(json, 'source'),
    sourcePrecision: _string(json, 'sourcePrecision'),
    invoiceMonth: _optionalString(json, 'invoiceMonth'),
    recordKind: _enum(RecordKind.values, json, 'recordKind'),
    view: _enum(CostView.values, json, 'view'),
    coverage: List<String>.from(json['coverage'] as List),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'connectionId': connectionId,
    'billingScopeId': billingScopeId,
    'service': service,
    'resourceId': resourceId,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'currency': currency,
    'amount': amount.toString(),
    'basis': basis,
    'category': category.name,
    'estimated': estimated,
    'source': source,
    'sourcePrecision': sourcePrecision,
    'invoiceMonth': invoiceMonth,
    'recordKind': recordKind.name,
    'view': view.name,
    'coverage': coverage,
  };
}

final class CloudResource {
  final String id;
  final String connectionId;
  final String billingScopeId;
  final String service;
  final String type;
  final String region;
  final String name;
  final Map<String, String> tags;
  final DateTime observedAt;
  final String? state;

  CloudResource({
    required this.id,
    required this.connectionId,
    required this.billingScopeId,
    required this.service,
    required this.type,
    required this.region,
    required this.name,
    required Map<String, String> tags,
    required this.observedAt,
    this.state,
  }) : tags = Map.unmodifiable(tags);

  factory CloudResource.fromJson(Map<String, dynamic> json) => CloudResource(
    id: _string(json, 'id'),
    connectionId: _string(json, 'connectionId'),
    billingScopeId: _string(json, 'billingScopeId'),
    service: _string(json, 'service'),
    type: _string(json, 'type'),
    region: _string(json, 'region'),
    name: _string(json, 'name'),
    tags: Map<String, String>.from(json['tags'] as Map),
    observedAt: _date(json, 'observedAt'),
    state: _optionalString(json, 'state'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'connectionId': connectionId,
    'billingScopeId': billingScopeId,
    'service': service,
    'type': type,
    'region': region,
    'name': name,
    'tags': tags,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'state': state,
  };
}

final class UsageSample {
  final String id;
  final String? resourceId;
  final String service;
  final String metric;
  final String unit;
  final DateTime start;
  final DateTime end;
  final String granularity;
  final String aggregation;
  final DecimalAmount value;
  final String source;

  UsageSample({
    required this.id,
    this.resourceId,
    required this.service,
    required this.metric,
    required this.unit,
    required this.start,
    required this.end,
    required this.granularity,
    required this.aggregation,
    required this.value,
    required this.source,
  }) {
    _window(start, end);
  }

  factory UsageSample.fromJson(Map<String, dynamic> json) => UsageSample(
    id: _string(json, 'id'),
    resourceId: _optionalString(json, 'resourceId'),
    service: _string(json, 'service'),
    metric: _string(json, 'metric'),
    unit: _string(json, 'unit'),
    start: _date(json, 'start'),
    end: _date(json, 'end'),
    granularity: _string(json, 'granularity'),
    aggregation: _string(json, 'aggregation'),
    value: _decimal(json, 'value'),
    source: _string(json, 'source'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'resourceId': resourceId,
    'service': service,
    'metric': metric,
    'unit': unit,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'granularity': granularity,
    'aggregation': aggregation,
    'value': value.toString(),
    'source': source,
  };
}

final class BudgetRule {
  final String id;
  final String billingScopeId;
  final String currency;
  final DateTime start;
  final DateTime end;
  final String basis;
  final DecimalAmount amount;
  final List<DecimalAmount> thresholds;

  BudgetRule({
    required this.id,
    required this.billingScopeId,
    required this.currency,
    required this.start,
    required this.end,
    required this.basis,
    required this.amount,
    required List<DecimalAmount> thresholds,
  }) : thresholds = List.unmodifiable(thresholds) {
    _window(start, end);
    if (amount.isNegative) throw ArgumentError('Budget cannot be negative');
    if (thresholds.isEmpty ||
        thresholds.any((t) => t.compareTo(DecimalAmount.zero) <= 0)) {
      throw ArgumentError('Budget thresholds must be positive');
    }
  }

  factory BudgetRule.fromJson(Map<String, dynamic> json) => BudgetRule(
    id: _string(json, 'id'),
    billingScopeId: _string(json, 'billingScopeId'),
    currency: _string(json, 'currency'),
    start: _date(json, 'start'),
    end: _date(json, 'end'),
    basis: _string(json, 'basis'),
    amount: _decimal(json, 'amount'),
    thresholds: json['thresholds'] == null
        ? [DecimalAmount.parse('0.8'), DecimalAmount.parse('1')]
        : (json['thresholds'] as List)
              .map((e) => DecimalAmount.parse(e as String))
              .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'billingScopeId': billingScopeId,
    'currency': currency,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'basis': basis,
    'amount': amount.toString(),
    'thresholds': thresholds.map((e) => e.toString()).toList(),
  };
}

final class ConsoleSummary {
  final String connectionId;
  final CloudProvider provider;
  final String? amountLabel;
  final String? currency;
  final DateTime? start;
  final DateTime? end;
  final BudgetState budgetState;
  final DatasetState dataState;

  ConsoleSummary({
    required this.connectionId,
    required this.provider,
    this.amountLabel,
    this.currency,
    this.start,
    this.end,
    required this.budgetState,
    required this.dataState,
  });

  factory ConsoleSummary.fromJson(Map<String, dynamic> json) => ConsoleSummary(
    connectionId: _string(json, 'connectionId'),
    provider: _enum(CloudProvider.values, json, 'provider'),
    amountLabel: _optionalString(json, 'amountLabel'),
    currency: _optionalString(json, 'currency'),
    start: _optionalDate(json, 'start'),
    end: _optionalDate(json, 'end'),
    budgetState: _enum(BudgetState.values, json, 'budgetState'),
    dataState: _enum(DatasetState.values, json, 'dataState'),
  );

  Map<String, dynamic> toJson() => {
    'connectionId': connectionId,
    'provider': provider.name,
    'amountLabel': amountLabel,
    'currency': currency,
    'start': start?.toUtc().toIso8601String(),
    'end': end?.toUtc().toIso8601String(),
    'budgetState': budgetState.name,
    'dataState': dataState.name,
  };
}

final class CostTotal {
  final String currency;
  final String basis;
  final DateTime start;
  final DateTime end;
  final DecimalAmount amount;

  CostTotal({
    required this.currency,
    required this.basis,
    required this.start,
    required this.end,
    required this.amount,
  }) {
    _window(start, end);
  }

  factory CostTotal.fromJson(Map<String, dynamic> json) => CostTotal(
    currency: _string(json, 'currency'),
    basis: _string(json, 'basis'),
    start: _date(json, 'start'),
    end: _date(json, 'end'),
    amount: _decimal(json, 'amount'),
  );

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'basis': basis,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'amount': amount.toString(),
  };
}
