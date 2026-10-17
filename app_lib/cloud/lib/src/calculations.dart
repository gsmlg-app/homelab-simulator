import 'dart:convert';

import 'decimal_amount.dart';
import 'models.dart';

String _windowKey(CostRecord cost) => jsonEncode([
  cost.currency,
  cost.basis,
  cost.start.toUtc().toIso8601String(),
  cost.end.toUtc().toIso8601String(),
]);

/// Selects one authoritative period view. Parent totals replace child detail;
/// aliases and other views remain inspectable in the original ledger only.
List<CostRecord> authoritativeCosts(
  Iterable<CostRecord> records, {
  required Iterable<BillingScope> scopes,
}) {
  final scopeById = {for (final scope in scopes) scope.id: scope};
  final selected = <String, CostRecord>{};
  for (final record in records) {
    final scope = scopeById[record.billingScopeId];
    if (record.view != CostView.period ||
        scope == null ||
        scope.authoritativeConnectionId != record.connectionId) {
      continue;
    }
    final key = jsonEncode([record.billingScopeId, record.id]);
    final previous = selected[key];
    if (previous != null &&
        jsonEncode(previous.toJson()) != jsonEncode(record.toJson())) {
      throw StateError(
        'Conflicting records in the same snapshot: ${record.id}',
      );
    }
    selected[key] = record;
  }
  final occupied = {
    for (final record in selected.values)
      jsonEncode([record.billingScopeId, _windowKey(record)]),
  };
  return List.unmodifiable(
    selected.values.where((record) {
      final visited = <String>{record.billingScopeId};
      var parentId = scopeById[record.billingScopeId]?.parentId;
      while (parentId != null) {
        if (!visited.add(parentId)) {
          throw StateError('Billing scope hierarchy cycle');
        }
        if (occupied.contains(jsonEncode([parentId, _windowKey(record)]))) {
          return false;
        }
        parentId = scopeById[parentId]?.parentId;
      }
      return true;
    }),
  );
}

/// No currency conversion, interval allocation, service filtering or rounding.
List<CostTotal> aggregateCosts(
  Iterable<CostRecord> records, {
  required Iterable<BillingScope> scopes,
}) {
  final groups = <String, CostTotal>{};
  for (final record in authoritativeCosts(records, scopes: scopes)) {
    final key = _windowKey(record);
    groups[key] = CostTotal(
      currency: record.currency,
      basis: record.basis,
      start: record.start,
      end: record.end,
      amount: (groups[key]?.amount ?? DecimalAmount.zero) + record.amount,
    );
  }
  final keys = groups.keys.toList()..sort();
  return List.unmodifiable(keys.map((key) => groups[key]!));
}

final class FreshnessResult {
  final bool collectionStale;

  /// Unknown without both a source watermark and an expected source age.
  final bool? sourceDelayed;
  const FreshnessResult({
    required this.collectionStale,
    required this.sourceDelayed,
  });
}

FreshnessResult evaluateFreshness(
  DatasetStatus status, {
  required DateTime now,
  required Duration collectionMaxAge,
  Duration? sourceMaxAge,
}) => FreshnessResult(
  collectionStale:
      status.lastSuccessAt == null ||
      now.difference(status.lastSuccessAt!) > collectionMaxAge,
  sourceDelayed: status.sourceAsOf == null || sourceMaxAge == null
      ? null
      : now.difference(status.sourceAsOf!) > sourceMaxAge,
);

final class BudgetEvaluation {
  final BudgetState state;
  final DecimalAmount knownAmount;
  final bool complete;
  const BudgetEvaluation({
    required this.state,
    required this.knownAmount,
    required this.complete,
  });
}

/// Evaluates only this application's rule; never changes any cloud budget.
BudgetEvaluation evaluateBudget(
  BudgetRule rule,
  Iterable<CostRecord> records, {
  required Iterable<BillingScope> scopes,
  required bool complete,
}) {
  if (rule.amount.isZero) {
    return BudgetEvaluation(
      state: BudgetState.disabled,
      knownAmount: DecimalAmount.zero,
      complete: complete,
    );
  }
  var amount = DecimalAmount.zero;
  for (final record in authoritativeCosts(
    records.where((record) => record.billingScopeId == rule.billingScopeId),
    scopes: scopes,
  )) {
    if (record.billingScopeId == rule.billingScopeId &&
        record.currency == rule.currency &&
        record.basis == rule.basis &&
        !record.start.isBefore(rule.start) &&
        !record.end.isAfter(rule.end)) {
      amount += record.amount;
    }
  }
  final thresholds = rule.thresholds.toList()..sort();
  final exceeded = amount.compareTo(rule.amount * thresholds.last) >= 0;
  final warning =
      thresholds.length > 1 &&
      amount.compareTo(rule.amount * thresholds.first) >= 0;
  return BudgetEvaluation(
    state: exceeded
        ? BudgetState.exceeded
        : warning
        ? BudgetState.warning
        : complete
        ? BudgetState.withinBudget
        : BudgetState.unknown,
    knownAmount: amount,
    complete: complete,
  );
}
