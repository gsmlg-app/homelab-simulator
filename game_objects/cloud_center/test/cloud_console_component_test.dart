import 'package:app_cloud/app_cloud.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_objects_cloud_center/game_objects_cloud_center.dart';

void main() {
  test('1000 small summaries retain one console without resource children', () {
    final model = createCloudCenterRoom().cloudConsoles.first;
    final component = CloudConsoleComponent(console: model);
    for (var index = 0; index < 1000; index++) {
      component.updateSummary(
        ConsoleSummary(
          connectionId: 'account',
          provider: CloudProvider.cloudflare,
          amountLabel: '$index',
          budgetState: BudgetState.warning,
          dataState: DatasetState.partial,
        ),
      );
      expect(component.console, same(model));
      expect(component.children, isEmpty);
    }
    expect(component.summary!.amountLabel, '999');
    expect(component.summary!.budgetState, BudgetState.warning);
    expect(component.summary!.dataState, DatasetState.partial);
    component.updateSummary(null);
    expect(component.summary, isNull);
  });

  test('same console ID geometry refreshes in place', () {
    final original = createCloudCenterRoom().cloudConsoles.first;
    final component = CloudConsoleComponent(console: original);
    final changed = CloudConsoleModel(
      id: original.id,
      roomId: original.roomId,
      position: const GridPosition(6, 7),
      target: original.target,
      width: 3,
      height: 2,
    );
    component.updateConsole(changed);
    expect(component.console, same(changed));
    expect(component.position, Vector2(192, 224));
    expect(component.size, Vector2(96, 64));
    expect(component.priority, 28800);
    expect(component.children, isEmpty);
  });
}
