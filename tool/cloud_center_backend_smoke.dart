import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_cloud_client/app_cloud_client.dart';

/// Launched by services/cloud_monitor/scripts/client_contract_smoke.exs only.
Future<void> main() async {
  if (Platform.environment['CLOUD_CONTRACT_FIXTURE'] != 'true') {
    throw StateError('Requires the isolated fixture backend smoke launcher');
  }
  final repository = HttpCloudRepository(
    baseUrl: Uri.parse('http://127.0.0.1:${Platform.environment['PORT']}'),
    accessToken: Platform.environment['CLOUD_MONITOR_TOKEN']!,
    authContext: 'offline-contract-smoke',
    allowLoopbackHttp: true,
  );
  var checks = 0;
  void check(bool value, String label) {
    if (!value) throw StateError('Contract failed: $label');
    checks++;
    stdout.writeln('PASS $label');
  }

  try {
    final query = CloudQuery(
      start: DateTime.utc(2026, 10),
      end: DateTime.utc(2026, 11),
      limit: 1,
    );
    final connections = await repository.connections();
    check(
      connections.data.any((c) => c.id == 'client-contract'),
      'Elixir connections decode into Dart models',
    );
    final overview = await repository.connectionOverview(
      'client-contract',
      query,
    );
    check(
      overview.data.totals
              .singleWhere(
                (t) => t.currency == 'USD' && t.basis == 'UnblendedCost',
              )
              .amount ==
          DecimalAmount.parse('85'),
      'reported costs and adjustments aggregate exactly to USD 85',
    );
    check(
      overview.data.totals
              .singleWhere(
                (t) => t.currency == 'USD' && t.basis == 'NetUnblendedCost',
              )
              .amount ==
          DecimalAmount.parse('12'),
      'different billing basis remains separate',
    );
    final first = await repository.resources('client-contract', query);
    check(
      first.data.length == 1 && first.nextCursor != null,
      'real backend resource pagination first page',
    );
    final second = await repository.resources(
      'client-contract',
      CloudQuery(
        start: query.start,
        end: query.end,
        limit: 1,
        cursor: first.nextCursor,
      ),
    );
    check(
      second.data.length == 1 &&
          second.data.single.id != first.data.single.id &&
          second.revision == first.revision,
      'real backend cursor and revision decode',
    );
    final usage = await repository.usage(first.data.single.id, query);
    check(
      usage.data.single.value == DecimalAmount.parse('12.5'),
      'encoded resource identifier and usage units',
    );
    final budgets = await repository.budgets();
    final rule = budgets.data.firstWhere(
      (r) => r.id == 'client-contract-budget',
    );
    final saved = await repository.saveBudget(rule);
    check(
      saved.amount == rule.amount,
      'application budget read/write contract',
    );
    final job = await repository.sync('client-contract', dataset: 'costs');
    check(
      (await repository.syncJob(job.id)).data.state == 'queued',
      'manual sync queues durable job without cloud call',
    );
    final all = await repository.overview(query);
    check(
      all.data.connections.isNotEmpty && all.data.totals.isNotEmpty,
      'cross-cloud overview model decodes',
    );
    stdout.writeln(
      'OFFLINE CONTRACT ONLY: $checks assertions, actual Elixir HTTP to Dart; no cloud account accessed',
    );
  } finally {
    repository.close();
  }
}
