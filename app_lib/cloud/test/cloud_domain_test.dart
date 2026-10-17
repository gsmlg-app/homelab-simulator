import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:test/test.dart';

void main() {
  final fixtureFile = File('../../docs/cloud-center/fixtures/demo-v1.json');

  test(
    'decimal arithmetic preserves source precision without binary floats',
    () {
      expect(
        (DecimalAmount.parse('0.1') + DecimalAmount.parse('0.2')).toString(),
        '0.3',
      );
      expect(
        (DecimalAmount.parse('99999999999999999999.999') +
                DecimalAmount.parse('0.001'))
            .toString(),
        '100000000000000000000',
      );
      expect(
        (DecimalAmount.parse('-2.50') * DecimalAmount.parse('0.8')).toString(),
        '-2',
      );
      expect(() => DecimalAmount.parse('1e3'), throwsFormatException);
      expect(() => DecimalAmount.parse('NaN'), throwsFormatException);
    },
  );

  test(
    'shared fixture round trips every DTO without changing wire semantics',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      expect(fixture['mode'], 'demo');
      for (final entry in fixture['connections'] as List) {
        expect(CloudConnection.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['scopes'] as List) {
        expect(BillingScope.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['costs'] as List) {
        expect(CostRecord.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['resources'] as List) {
        expect(CloudResource.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['usage'] as List) {
        expect(UsageSample.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['budgets'] as List) {
        expect(BudgetRule.fromJson(entry).toJson(), entry);
      }
      for (final entry in fixture['summaries'] as List) {
        expect(ConsoleSummary.fromJson(entry).toJson(), entry);
      }
    },
  );

  test(
    'aggregate excludes aliases parents details cumulative and duplicate ids',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final costs = (fixture['costs'] as List)
          .map((e) => CostRecord.fromJson(e))
          .toList();
      final scopes = (fixture['scopes'] as List)
          .map((e) => BillingScope.fromJson(e))
          .toList();
      final totals = aggregateCosts([...costs, ...costs], scopes: scopes);
      expect(totals.map((e) => e.toJson()).toList(), fixture['expectedTotals']);
      expect(
        costs.any(
          (e) =>
              e.service == 'Unsupported example service' &&
              e.resourceId == null,
        ),
        isTrue,
      );
    },
  );

  test('freshness keeps successful collection separate from source lag', () {
    final status = DatasetStatus(
      state: DatasetState.available,
      lastSuccessAt: DateTime.utc(2026, 10, 17),
      sourceAsOf: DateTime.utc(2026, 10, 12),
      complete: true,
    );
    final result = evaluateFreshness(
      status,
      now: DateTime.utc(2026, 10, 17, 1),
      collectionMaxAge: const Duration(days: 1),
      sourceMaxAge: const Duration(days: 2),
    );
    expect(result.collectionStale, isFalse);
    expect(result.sourceDelayed, isTrue);
    expect(
      evaluateFreshness(
        DatasetStatus(state: DatasetState.waiting, complete: false),
        now: DateTime.utc(2026),
        collectionMaxAge: const Duration(days: 1),
      ).sourceDelayed,
      isNull,
    );
  });

  test('budget uses matching windows basis currency and scope with exact thresholds', () {
    final fixture =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final rule = BudgetRule.fromJson((fixture['budgets'] as List).first);
    final costs = (fixture['costs'] as List)
        .map((e) => CostRecord.fromJson(e))
        .toList();
    final scopes = (fixture['scopes'] as List)
        .map((e) => BillingScope.fromJson(e))
        .toList();
    expect(
      evaluateBudget(rule, costs, scopes: scopes, complete: true).state,
      BudgetState.warning,
    );
    expect(
      evaluateBudget(rule, [], scopes: scopes, complete: false).state,
      BudgetState.unknown,
    );
    final zero = BudgetRule.fromJson({...rule.toJson(), 'amount': '0'});
    expect(
      evaluateBudget(zero, costs, scopes: scopes, complete: true).state,
      BudgetState.disabled,
    );
    final partial = BudgetRule.fromJson({...rule.toJson(), 'amount': '10'});
    expect(
      evaluateBudget(partial, costs, scopes: scopes, complete: false).state,
      BudgetState.exceeded,
    );
  });

  test(
    'monthly budget sums wholly contained daily charges credits and refunds',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final base = Map<String, dynamic>.from((fixture['costs'] as List).first);
      final rule = BudgetRule.fromJson((fixture['budgets'] as List).first);
      final scopes = (fixture['scopes'] as List)
          .map((e) => BillingScope.fromJson(e))
          .toList();
      CostRecord row(
        String id,
        String amount,
        String start,
        String end, {
        String currency = 'USD',
        String basis = 'UnblendedCost',
        String category = 'usage',
      }) => CostRecord.fromJson({
        ...base,
        'id': id,
        'amount': amount,
        'start': start,
        'end': end,
        'currency': currency,
        'basis': basis,
        'category': category,
      });
      final costs = [
        row('day1', '60', '2026-10-01T00:00:00Z', '2026-10-02T00:00:00Z'),
        row('day2', '40', '2026-10-02T00:00:00Z', '2026-10-03T00:00:00Z'),
        row(
          'credit',
          '-10',
          '2026-10-02T00:00:00Z',
          '2026-10-03T00:00:00Z',
          category: 'credit',
        ),
        row(
          'refund',
          '-5',
          '2026-10-03T00:00:00Z',
          '2026-10-04T00:00:00Z',
          category: 'refund',
        ),
        row('coarse', '900', '2026-09-15T00:00:00Z', '2026-10-15T00:00:00Z'),
        row('after', '900', '2026-11-01T00:00:00Z', '2026-11-02T00:00:00Z'),
        row(
          'other-currency',
          '900',
          '2026-10-01T00:00:00Z',
          '2026-10-02T00:00:00Z',
          currency: 'EUR',
        ),
        row(
          'other-basis',
          '900',
          '2026-10-01T00:00:00Z',
          '2026-10-02T00:00:00Z',
          basis: 'NetUnblendedCost',
        ),
      ];
      final result = evaluateBudget(
        rule,
        costs,
        scopes: scopes,
        complete: true,
      );
      expect(result.knownAmount.toString(), '85');
      expect(result.state, BudgetState.warning);
    },
  );

  test(
    'budget can evaluate a child scope independently of parent overview',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final costs = (fixture['costs'] as List)
          .map((e) => CostRecord.fromJson(e))
          .toList();
      final scopes = (fixture['scopes'] as List)
          .map((e) => BillingScope.fromJson(e))
          .toList();
      final rule = BudgetRule.fromJson({
        ...Map<String, dynamic>.from((fixture['budgets'] as List).first),
        'billingScopeId': 'scope-aws-child',
      });
      final result = evaluateBudget(
        rule,
        costs,
        scopes: scopes,
        complete: true,
      );
      expect(result.knownAmount.toString(), '100');
      expect(result.state, BudgetState.exceeded);
    },
  );

  test(
    'DTO collections are immutable and strict decimal input rejects numbers',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final raw = Map<String, dynamic>.from((fixture['costs'] as List).first);
      expect(
        () => CostRecord.fromJson({...raw, 'amount': 1.1}),
        throwsFormatException,
      );
      expect(
        () => CostRecord.fromJson({...raw, 'recordKind': 'forecast'}),
        throwsFormatException,
      );
      expect(
        () => CostRecord.fromJson({...raw, 'start': '2026-10-01T00:00:00'}),
        throwsFormatException,
      );
      expect(
        () => CostRecord.fromJson({...raw, 'end': raw['start']}),
        throwsArgumentError,
      );
      final cost = CostRecord.fromJson(raw);
      expect(() => cost.coverage.add('mutated'), throwsUnsupportedError);
      final connection = CloudConnection.fromJson(
        (fixture['connections'] as List).first,
      );
      expect(
        () => connection.capabilities['costs'] = 'mutated',
        throwsUnsupportedError,
      );
      expect(() => connection.statuses.clear(), throwsUnsupportedError);
    },
  );

  test('conflicting duplicate records fail instead of choosing an arbitrary charge', () {
    final fixture =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final raw = Map<String, dynamic>.from((fixture['costs'] as List).first);
    final scopes = (fixture['scopes'] as List).map(
      (e) => BillingScope.fromJson(e),
    );
    expect(
      () => aggregateCosts([
        CostRecord.fromJson(raw),
        CostRecord.fromJson({...raw, 'amount': '999'}),
      ], scopes: scopes),
      throwsStateError,
    );
  });

  test(
    'strict windows and query limits preserve half-open dates and timezones',
    () {
      expect(
        () => CloudQuery(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2027, 1, 1),
        ),
        throwsArgumentError,
      );
      expect(() => CloudQuery(limit: 101), throwsArgumentError);
      final query = CloudQuery(
        start: DateTime.parse('2025-12-31T23:00:00-01:00'),
        end: DateTime.utc(2026, 2),
      );
      expect(query.toJson()['start'], '2026-01-01T00:00:00.000Z');
      expect(
        () => CostRecord.fromJson({'amount': 1.1}),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('fixture contains 1000 stable resources for paginated repositories', () {
    final fixture =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    expect(fixture['resources'], hasLength(1000));
    expect(
      (fixture['resources'] as List).map((e) => e['id']).toSet(),
      hasLength(1000),
    );
    expect(fixture['pagination']['pageSize'], 50);
    expect(fixture['pagination']['pages'], 20);
  });
}
