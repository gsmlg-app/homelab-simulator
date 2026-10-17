import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _Repository extends Mock implements CloudRepository {}

void main() {
  final fixture = jsonDecode(
    File('../../docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final connections = (fixture['connections'] as List)
      .map((c) => CloudConnection.fromJson(c))
      .toList();
  CloudPage<T> page<T>(T data, {String revision = '1', String? cursor}) =>
      CloudPage(revision: revision, query: {}, data: data, nextCursor: cursor);
  setUpAll(() {
    registerFallbackValue(CloudQuery());
    registerFallbackValue(CloudCancellation());
  });
  test(
    'close and provider switches reject stale responses and cancel UI work',
    () async {
      final repository = _Repository();
      final first = Completer<CloudPage<List<CloudConnection>>>();
      final second = Completer<CloudPage<List<CloudConnection>>>();
      var calls = 0;
      final cancellations = <CloudCancellation>[];
      when(
        () => repository.connections(cancellation: any(named: 'cancellation')),
      ).thenAnswer((invocation) {
        cancellations.add(
          invocation.namedArguments[#cancellation] as CloudCancellation,
        );
        return calls++ == 0 ? first.future : second.future;
      });
      when(
        () => repository.connectionOverview(
          any(),
          any(),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer((i) async {
        final connection = connections.firstWhere(
          (c) => c.id == i.positionalArguments.first,
        );
        return page(
          ConnectionOverview(
            connection: CloudConnection(
              id: connection.id,
              provider: connection.provider,
              displayName: connection.displayName,
              billingScopeId: connection.billingScopeId,
              capabilities: connection.capabilities,
              statuses: {
                'costs': DatasetStatus(
                  state: DatasetState.stale,
                  complete: false,
                ),
              },
            ),
            totals: [],
            resourceCount: 0,
            statuses: connection.statuses,
          ),
        );
      });
      when(
        () => repository.costs(
          any(),
          any(),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer((_) async => page(<CostRecord>[]));
      when(
        () => repository.resources(
          any(),
          any(),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer((_) async => page(<CloudResource>[]));
      when(() => repository.budgets(cancellation: any(named: 'cancellation')))
          .thenAnswer((_) async => page(<BudgetRule>[]));
      final cubit = CloudCenterCubit(repository);
      final old = cubit.open(provider: CloudProvider.aws);
      final newer = cubit.open(
        provider: CloudProvider.gcp,
        connectionId: 'aws-main',
      );
      expect(cancellations.first.isCancelled, isTrue);
      second.complete(page(connections));
      await newer;
      expect(cubit.state.selectedConnection?.provider, CloudProvider.gcp);
      expect(
        cubit.state.selectedConnection?.statuses['costs']?.state,
        DatasetState.stale,
      );
      first.complete(page(connections));
      await old;
      expect(cubit.state.selectedConnection?.provider, CloudProvider.gcp);
      cubit.closePanel();
      expect(cancellations.last.isCancelled, isTrue);
      expect(cubit.state.isOpen, isFalse);
      await cubit.close();
    },
  );
  test(
    'missing configuration is explicit and cannot substitute demo money',
    () async {
      final repository = _Repository();
      when(
        () => repository.connections(cancellation: any(named: 'cancellation')),
      ).thenThrow(const CloudFailure('unconfigured', 'Backend not configured'));
      final cubit = CloudCenterCubit(repository);
      await cubit.open(provider: CloudProvider.aws);
      expect(cubit.state.error?.code, 'unconfigured');
      expect(cubit.state.costs, isEmpty);
      await cubit.close();
    },
  );
  _Repository populatedRepository() {
    final repo = _Repository();
    when(() => repo.connections(cancellation: any(named: 'cancellation')))
        .thenAnswer((_) async => page(connections));
    when(
      () => repo.connectionOverview(
        any(),
        any(),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer((i) async {
      final q = i.positionalArguments[1] as CloudQuery;
      if (q.service == 'query-B') {
        throw const CloudFailure('failed', 'Failed query B');
      }
      final c = connections.firstWhere(
        (c) => c.id == i.positionalArguments.first,
      );
      return page(
        ConnectionOverview(
          connection: c,
          totals: [],
          resourceCount: 1,
          statuses: c.statuses,
        ),
      );
    });
    when(
      () => repo.costs(any(), any(), cancellation: any(named: 'cancellation')),
    ).thenAnswer((i) async {
      if ((i.positionalArguments[1] as CloudQuery).service == 'query-B') {
        throw const CloudFailure('failed', 'Failed query B');
      }
      return page(
        (fixture['costs'] as List)
            .map((row) => CostRecord.fromJson(row))
            .where((r) => r.connectionId == 'aws-main')
            .toList(),
        cursor: 'old-cost-cursor',
      );
    });
    when(
      () => repo.resources(
        any(),
        any(),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer((i) async {
      if ((i.positionalArguments[1] as CloudQuery).service == 'query-B') {
        throw const CloudFailure('failed', 'Failed query B');
      }
      return page(
        (fixture['resources'] as List)
            .map((row) => CloudResource.fromJson(row))
            .where((r) => r.connectionId == 'aws-main')
            .take(1)
            .toList(),
        cursor: 'old-resource-cursor',
      );
    });
    when(() => repo.budgets(cancellation: any(named: 'cancellation')))
        .thenAnswer((_) async => page(<BudgetRule>[]));
    return repo;
  }

  test('failed new query clears previous data revisions and cursors before pagination', () async {
    final repo = populatedRepository();
    when(
      () => repo.usage(any(), any(), cancellation: any(named: 'cancellation')),
    ).thenAnswer(
      (_) async => page(
        (fixture['usage'] as List)
            .map((row) => UsageSample.fromJson(row))
            .toList(),
      ),
    );
    final cubit = CloudCenterCubit(repo);
    addTearDown(cubit.close);
    await cubit.open(provider: CloudProvider.aws);
    await cubit.loadUsage('resource-A');
    expect(cubit.state.costs, isNotEmpty);
    expect(cubit.state.resources, isNotEmpty);
    expect(cubit.state.usage, isNotEmpty);
    expect(cubit.state.nextCostCursor, isNotNull);
    await cubit.reload(newQuery: CloudQuery(service: 'query-B'));
    expect(cubit.state.error?.code, 'failed');
    expect(cubit.state.costs, isEmpty);
    expect(cubit.state.resources, isEmpty);
    expect(cubit.state.usage, isEmpty);
    expect(cubit.state.connectionOverview, isNull);
    expect(cubit.state.costRevision, isNull);
    expect(cubit.state.resourceRevision, isNull);
    expect(cubit.state.nextCostCursor, isNull);
    expect(cubit.state.nextResourceCursor, isNull);
    clearInteractions(repo);
    await cubit.loadMoreCosts();
    await cubit.loadMoreResources();
    verifyNever(
      () => repo.costs(any(), any(), cancellation: any(named: 'cancellation')),
    );
    verifyNever(
      () => repo.resources(
        any(),
        any(),
        cancellation: any(named: 'cancellation'),
      ),
    );
  });

  test(
    'newest resource usage wins reverse completions and superseded errors',
    () async {
      final repo = populatedRepository();
      final requests = <String, Completer<CloudPage<List<UsageSample>>>>{};
      final cancellations = <CloudCancellation>[];
      when(
        () =>
            repo.usage(any(), any(), cancellation: any(named: 'cancellation')),
      ).thenAnswer((i) {
        cancellations.add(i.namedArguments[#cancellation] as CloudCancellation);
        return (requests[i.positionalArguments.first as String] =
                Completer<CloudPage<List<UsageSample>>>())
            .future;
      });
      final sample = UsageSample.fromJson((fixture['usage'] as List).first);
      final cubit = CloudCenterCubit(repo);
      addTearDown(cubit.close);
      await cubit.open(provider: CloudProvider.aws);
      final older = cubit.loadUsage('resource-A');
      final newer = cubit.loadUsage('resource-B');
      requests['resource-B']!.complete(page([sample]));
      await newer;
      requests['resource-A']!.complete(page(<UsageSample>[]));
      await older;
      expect(cubit.state.usage, [sample]);
      expect(cancellations.first.isCancelled, isTrue);
      final oldError = cubit.loadUsage('resource-C');
      final latest = cubit.loadUsage('resource-D');
      requests['resource-D']!.complete(page([sample]));
      await latest;
      requests['resource-C']!.completeError(
        const CloudFailure('failed', 'Old resource failed'),
      );
      await oldError;
      expect(cubit.state.usage, [sample]);
      expect(cubit.state.error, isNull);
      cubit.closePanel();
      expect(cancellations.last.isCancelled, isTrue);
    },
  );
}
