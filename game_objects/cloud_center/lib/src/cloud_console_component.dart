import 'package:app_cloud/app_cloud.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/painting.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Small immutable summary projection. Full data remains in Flutter panels.
class CloudConsoleComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  CloudConsoleModel _console;
  CloudConsoleModel get console => _console;
  ConsoleSummary? _summary;
  ConsoleSummary? get summary => _summary;
  final double tileSize;
  final _body = Paint()..color = const Color(0xff193b49);
  final _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final _labels = <TextPainter>[];

  CloudConsoleComponent({
    required CloudConsoleModel console,
    ConsoleSummary? summary,
    this.tileSize = GameConstants.tileSize,
  }) : _console = console,
       super(
         position: Vector2(
           console.position.x * tileSize,
           console.position.y * tileSize,
         ),
         size: Vector2(console.width * tileSize, console.height * tileSize),
       ) {
    _summary = summary;
    _refreshLabels();
  }

  void updateConsole(CloudConsoleModel value) {
    assert(value.id == console.id);
    if (value == console) return;
    _console = value;
    position.setValues(
      value.position.x * tileSize,
      value.position.y * tileSize,
    );
    size.setValues(value.width * tileSize, value.height * tileSize);
    _refreshLabels();
  }

  void updateSummary(ConsoleSummary? value) {
    if (identical(_summary, value)) return;
    _summary = value;
    _refreshLabels();
  }

  void _refreshLabels() {
    for (final label in _labels) {
      label.dispose();
    }
    _labels.clear();
    final title = switch (console.target) {
      ProviderConsoleTarget(:final provider) =>
        provider == CloudProvider.aws
            ? 'AWS'
            : provider == CloudProvider.gcp
            ? 'GCP'
            : 'Cloudflare',
      CostOverviewTarget() => 'All clouds',
    };
    String day(DateTime value) => '${value.month}/${value.day}';
    final summary = _summary;
    final lines = [
      title,
      summary == null
          ? 'Not configured'
          : summary.amountLabel == null
          ? 'Amount unavailable'
          : '${summary.currency ?? ''} ${summary.amountLabel}',
      summary?.start == null || summary?.end == null
          ? 'Period unknown'
          : '${day(summary!.start!)}–${day(summary.end!)}',
      'Data: ${summary?.dataState.name ?? 'unconfigured'}',
      'Budget: ${summary?.budgetState.name ?? 'unknown'}',
    ];
    for (final line in lines) {
      _labels.add(
        TextPainter(
          text: TextSpan(
            text: line,
            style: const TextStyle(fontSize: 8, color: AppColors.textPrimary),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: size.x - 8),
      );
    }
    priority = ((console.position.y + console.height) * tileSize * 100).round();
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, _body);
    _border.color = bloc.state.interactableEntityId == console.id
        ? const Color(0xff7fe6ee)
        : const Color(0xff4a8194);
    canvas.drawRRect(rect, _border);
    for (var index = 0; index < _labels.length; index++) {
      _labels[index].paint(canvas, Offset(4, 5 + index * 11));
    }
  }

  @override
  void onRemove() {
    for (final label in _labels) {
      label.dispose();
    }
    _labels.clear();
    super.onRemove();
  }
}
