import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_cloud_client/app_cloud_client.dart';
import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_widgets_cloud_center/game_widgets_cloud_center.dart';

class _PanelCubit extends CloudCenterCubit {
  _PanelCubit(super.repository, CloudQuery query) : super(initialQuery: query);
  void show(CloudCenterState state) => emit(state);
}

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'native panel $width keeps Demo/source labels and blocks background taps',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = jsonDecode(
          File('../../docs/cloud-center/fixtures/demo-v1.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        final cubit = CloudCenterCubit(DemoCloudRepository(fixture));
        await cubit.open(provider: CloudProvider.aws);
        var backgroundTaps = 0;
        var closes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => backgroundTaps++,
                      child: const ColoredBox(color: Colors.red),
                    ),
                  ),
                  CloudCenterPanel(
                    cubit: cubit,
                    mode: CloudMode.demo,
                    onClose: () => closes++,
                    onConfigure: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('DEMO · Synthetic data'), findsOneWidget);
        expect(find.textContaining('UTC'), findsWidgets);
        await tester.ensureVisible(find.text('Connection'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Connection'));
        await tester.pumpAndSettle();
        expect(find.text('Source updated'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 600));
        expect(backgroundTaps, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(closes, 1);
        await tester.pumpWidget(const SizedBox());
        await cubit.close();
      },
    );
  }
  for (final scenario in [
    'day',
    'loading',
    'offline',
    'error',
    'pagination',
    'source-partial',
    'exceeded',
    'zero',
    'complete',
    'service',
    'region',
    'project',
    'search',
    'other-basis',
    'matching-basis',
    'filtered-warning',
    'filtered-exceeded',
  ]) {
    testWidgets('budget completeness handles $scenario without false safety', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = jsonDecode(
        File('../../docs/cloud-center/fixtures/demo-v1.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final rawConnection = Map<String, dynamic>.from(
        (fixture['connections'] as List).firstWhere(
          (c) => c['id'] == 'aws-main',
        ),
      );
      rawConnection['statuses'] = {
        'costs': DatasetStatus(
          state: DatasetState.available,
          complete: scenario != 'source-partial',
        ).toJson(),
      };
      final connection = CloudConnection.fromJson(rawConnection);
      final start = DateTime.utc(2026, 10);
      final end = DateTime.utc(2026, 11);
      final query = CloudQuery(
        start: start,
        end: scenario == 'day' ? start.add(const Duration(days: 1)) : end,
        service:
            [
              'service',
              'filtered-warning',
              'filtered-exceeded',
            ].contains(scenario)
            ? 'Compute'
            : null,
        region: scenario == 'region' ? 'us-east-1' : null,
        project: scenario == 'project' ? connection.billingScopeId : null,
        search: scenario == 'search' ? 'instance' : null,
        basis: scenario == 'other-basis'
            ? 'NetUnblendedCost'
            : scenario == 'matching-basis'
            ? 'UnblendedCost'
            : null,
      );
      final cost = CostRecord.fromJson({
        ...Map<String, dynamic>.from(
          (fixture['costs'] as List).firstWhere((c) => c['id'] == 'aws-usage'),
        ),
        'end': '2026-10-02T00:00:00.000Z',
        'amount': ['exceeded', 'filtered-exceeded'].contains(scenario)
            ? '101'
            : scenario == 'filtered-warning'
            ? '85'
            : '10',
        'basis': scenario == 'other-basis'
            ? 'NetUnblendedCost'
            : 'UnblendedCost',
      });
      final rule = BudgetRule(
        id: 'monthly',
        billingScopeId: connection.billingScopeId,
        currency: 'USD',
        start: start,
        end: end,
        basis: 'UnblendedCost',
        amount: DecimalAmount.parse(scenario == 'zero' ? '0' : '100'),
        thresholds: [DecimalAmount.parse('0.8'), DecimalAmount.parse('1')],
      );
      final cubit = _PanelCubit(DemoCloudRepository(fixture), query);
      cubit.show(
        CloudCenterState(
          isOpen: true,
          selectedId: connection.id,
          provider: CloudProvider.aws,
          connections: [connection],
          costs: [cost],
          budgets: [rule],
          loading: scenario == 'loading',
          offline: scenario == 'offline',
          error: scenario == 'error'
              ? const CloudFailure('failed', 'Costs unavailable')
              : null,
          nextCostCursor: ['pagination', 'exceeded'].contains(scenario)
              ? 'next'
              : null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CloudCenterPanel(
              cubit: cubit,
              mode: CloudMode.demo,
              onClose: () {},
              onConfigure: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Budgets'));
      await tester.tap(find.text('Budgets'));
      await tester.pump();
      final expected = scenario == 'filtered-warning'
          ? 'warning'
          : ['exceeded', 'filtered-exceeded'].contains(scenario)
          ? 'exceeded'
          : scenario == 'zero'
          ? 'disabled'
          : ['complete', 'matching-basis'].contains(scenario)
          ? 'withinBudget'
          : 'unknown';
      expect(find.text('USD ${rule.amount} · $expected'), findsOneWidget);
      if (!['complete', 'matching-basis', 'zero'].contains(scenario)) {
        expect(
          find.textContaining(
            'Partial coverage: below threshold does not mean safe',
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
  }

  testWidgets('Escape closes once with resource search field focused', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = jsonDecode(
      File('../../docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final cubit = CloudCenterCubit(DemoCloudRepository(fixture));
    await cubit.open(provider: CloudProvider.aws);
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudCenterPanel(
            cubit: cubit,
            mode: CloudMode.demo,
            onClose: () => closes++,
            onConfigure: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resources'));
    await tester.tap(find.text('Resources'));
    await tester.pumpAndSettle();
    final search = find.byType(TextField).first;
    await tester.tap(search);
    await tester.enterText(search, 'resource input');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closes, 1);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
