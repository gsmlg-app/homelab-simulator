import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:app_cloud/app_cloud.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Small scene projection; billing records remain in the Flutter state layer.
ConsoleSummary? projectCloudSummary(
  CloudCenterState state,
  CloudQuery query,
  CloudConsoleModel console,
  CloudMode mode,
) {
  final board = console.target is CostOverviewTarget;
  final connection = board
      ? state.overview?.connections.firstOrNull
      : state.selectedConnection;
  if (connection == null) return null;
  final totals = board
      ? state.overview?.totals ?? <CostTotal>[]
      : state.connectionOverview?.totals ?? <CostTotal>[];
  final costStatus = connection.statuses['costs'];
  var budget = BudgetState.unknown;
  if (!board) {
    final evaluations = state.budgets
        .where((rule) => rule.billingScopeId == connection.billingScopeId)
        .map(
          (rule) => evaluateBudget(
            rule,
            state.costs,
            scopes: [
              BillingScope(
                id: connection.billingScopeId,
                provider: connection.provider,
                accountId: connection.billingScopeId,
                authoritativeConnectionId: connection.id,
              ),
            ],
            complete:
                !state.loading &&
                !state.offline &&
                state.error == null &&
                state.nextCostCursor == null &&
                costStatus?.complete == true &&
                query.service == null &&
                query.region == null &&
                query.project == null &&
                query.search == null &&
                (query.basis == null || query.basis == rule.basis) &&
                query.start != null &&
                !query.start!.isAfter(rule.start) &&
                !query.end!.isBefore(rule.end),
          ).state,
        )
        .toList();
    for (final candidate in [
      BudgetState.exceeded,
      BudgetState.warning,
      BudgetState.unknown,
      BudgetState.withinBudget,
      BudgetState.disabled,
    ]) {
      if (evaluations.contains(candidate)) {
        budget = candidate;
        break;
      }
    }
  }
  final single = totals.length == 1 ? totals.single : null;
  final prefix = mode == CloudMode.demo ? 'Demo · ' : '';
  final amount = totals.isEmpty
      ? 'Unknown'
      : single != null
      ? single.amount.toString()
      : totals
            .map(
              (t) =>
                  '${t.currency} ${t.amount} (${t.basis}; ${t.start.toIso8601String()}–${t.end.toIso8601String()})',
            )
            .join(' / ');
  return ConsoleSummary(
    connectionId: board ? 'overview' : connection.id,
    provider: connection.provider,
    amountLabel: '$prefix$amount',
    currency: single?.currency,
    start: single?.start ?? query.start,
    end: single?.end ?? query.end,
    budgetState: budget,
    dataState: state.offline
        ? DatasetState.stale
        : board
        ? (state.overview!.coverage.isNotEmpty ||
                  state.overview!.connections.any(
                    (c) => c.statuses['costs']?.complete != true,
                  )
              ? DatasetState.partial
              : DatasetState.available)
        : costStatus?.state ?? DatasetState.unconfigured,
  );
}
