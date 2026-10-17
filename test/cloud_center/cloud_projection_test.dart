import 'dart:convert';
import 'dart:io';

import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:app_cloud/app_cloud.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homelab_simulator/cloud_center/cloud_center_projection.dart';

void main() {
  final fixture = jsonDecode(
    File('docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final connection = (fixture['connections'] as List)
      .map((e) => CloudConnection.fromJson(e))
      .firstWhere((c) => c.id == 'aws-main');
  final costs = (fixture['costs'] as List)
      .map((e) => CostRecord.fromJson(e))
      .where((c) => c.connectionId == connection.id)
      .toList();
  final rule = BudgetRule.fromJson((fixture['budgets'] as List).first);
  final query = CloudQuery(start: rule.start, end: rule.end);
  const console = CloudConsoleModel(
    id: 'aws',
    roomId: 'cloud',
    position: GridPosition(3, 3),
    target: ProviderConsoleTarget(CloudProvider.aws),
  );
  final totals = aggregateCosts(
    costs,
    scopes: [
      BillingScope(
        id: connection.billingScopeId,
        provider: connection.provider,
        accountId: 'demo',
        authoritativeConnectionId: connection.id,
      ),
    ],
  );
  CloudCenterState state({bool offline = false}) => CloudCenterState(
    isOpen: true,
    selectedId: connection.id,
    connections: [connection],
    costs: costs,
    budgets: [rule],
    offline: offline,
    connectionOverview: ConnectionOverview(
      connection: connection,
      totals: totals,
      resourceCount: 3,
      statuses: connection.statuses,
    ),
  );

  test('scene budget reflects known costs and Demo stays visible', () {
    final summary = projectCloudSummary(
      state(),
      query,
      console,
      CloudMode.demo,
    )!;
    expect(summary.budgetState, BudgetState.warning);
    expect(summary.amountLabel, contains('Demo'));
    expect(summary.amountLabel, isNot(contains('USD USD')));
    expect(
      projectCloudSummary(
        state(offline: true),
        query,
        console,
        CloudMode.demo,
      )!.dataState,
      DatasetState.stale,
    );
  });

  test('overview console projects totals while currencies stay separate', () {
    const board = CloudConsoleModel(
      id: 'board',
      roomId: 'cloud',
      position: GridPosition(3, 3),
      target: CostOverviewTarget(),
    );
    final overview = CloudCenterState(
      isOpen: true,
      connections: [connection],
      overview: CloudOverview(
        totals: [
          CostTotal(
            currency: 'USD',
            basis: 'UnblendedCost',
            start: rule.start,
            end: rule.end,
            amount: DecimalAmount.parse('85'),
          ),
          CostTotal(
            currency: 'EUR',
            basis: 'ExportedCost',
            start: rule.start,
            end: rule.end,
            amount: DecimalAmount.parse('16.5'),
          ),
        ],
        connections: [connection],
        coverage: ['partial'],
      ),
    );
    final summary = projectCloudSummary(
      overview,
      query,
      board,
      CloudMode.real,
    )!;
    expect(summary.amountLabel, contains('USD 85'));
    expect(summary.amountLabel, contains('EUR 16.5'));
    expect(summary.amountLabel, isNot(contains('101.5')));
    expect(summary.dataState, DatasetState.partial);
  });
  for (final filter in [
    'service',
    'region',
    'project',
    'search',
    'other-basis',
    'matching-basis',
  ]) {
    test('scene budget does not claim full scope for $filter query', () {
      final filtered = CloudQuery(
        start: rule.start,
        end: rule.end,
        service: filter == 'service' ? 'Compute' : null,
        region: filter == 'region' ? 'us-east-1' : null,
        project: filter == 'project' ? connection.billingScopeId : null,
        search: filter == 'search' ? 'instance' : null,
        basis: filter == 'other-basis'
            ? 'NetUnblendedCost'
            : filter == 'matching-basis'
            ? rule.basis
            : null,
      );
      final row = CostRecord.fromJson({
        ...costs.first.toJson(),
        'amount': '10',
        'basis': filter == 'other-basis' ? 'NetUnblendedCost' : rule.basis,
      });
      final summary = projectCloudSummary(
        state().copy(costs: [row]),
        filtered,
        console,
        CloudMode.real,
      )!;
      expect(
        summary.budgetState,
        filter == 'matching-basis'
            ? BudgetState.withinBudget
            : BudgetState.unknown,
      );
    });
  }
  for (final amount in ['85', '101']) {
    test(
      'filtered known cost $amount still identifies the exceeded threshold',
      () {
        final row = CostRecord.fromJson({
          ...costs.first.toJson(),
          'amount': amount,
        });
        final filtered = CloudQuery(
          start: rule.start,
          end: rule.end,
          service: 'Compute',
        );
        final summary = projectCloudSummary(
          state().copy(costs: [row]),
          filtered,
          console,
          CloudMode.real,
        )!;
        expect(
          summary.budgetState,
          amount == '85' ? BudgetState.warning : BudgetState.exceeded,
        );
      },
    );
  }
}
