import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_widget_common/app_widget_common.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Renders a placed cloud service in the game world
class CloudServiceComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final CloudServiceModel service;
  final double tileSize;
  bool _isSelected = false;

  // Cached paint objects for performance
  static final _selectPaint = Paint()
    ..color = const Color(0xFFFFFF00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _iconPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.fill;

  // Instance-level cached paints (depend on service properties)
  late final Paint _bgPaint;
  late final Paint _bodyPaint;
  late final Paint _providerPaint;
  late final Paint _borderPaint;

  CloudServiceComponent({
    required this.service,
    this.tileSize = GameConstants.tileSize,
  }) : super(
         position: Vector2(
           service.position.x * tileSize,
           service.position.y * tileSize,
         ),
         size: Vector2(service.width * tileSize, service.height * tileSize),
       );

  Color get _providerColor => service.provider.color;
  Color get _categoryColor => service.category.color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Initialize cached paints (depend on service properties)
    _bgPaint = Paint()
      ..color = _providerColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    _bodyPaint = Paint()
      ..color = _categoryColor
      ..style = PaintingStyle.fill;
    _providerPaint = Paint()
      ..color = _providerColor
      ..style = PaintingStyle.fill;
    _borderPaint = Paint()
      ..color = _providerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    _isSelected = worldState.selectedEntityId == service.id;
  }

  @override
  void render(Canvas canvas) {
    // Background with provider color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(6),
      ),
      _bgPaint,
    );

    // Service body with category color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.x - 16, size.y - 16),
        const Radius.circular(4),
      ),
      _bodyPaint,
    );

    // Provider indicator (small colored dot in corner)
    canvas.drawCircle(Offset(size.x - 12, 12), 5, _providerPaint);

    // Cloud icon representation (simplified)
    _drawCloudIcon(canvas);

    // Selection highlight
    if (_isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
          const Radius.circular(6),
        ),
        _selectPaint,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(6),
      ),
      _borderPaint,
    );
  }

  void _drawCloudIcon(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final scale = size.x / 40; // Scale icon based on tile size

    // Draw a simple cloud shape
    canvas.drawCircle(
      Offset(centerX - 5 * scale, centerY),
      6 * scale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(centerX + 5 * scale, centerY),
      6 * scale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY - 3 * scale),
      5 * scale,
      _iconPaint,
    );

    // Draw bottom rectangle to complete cloud
    canvas.drawRect(
      Rect.fromLTWH(centerX - 10 * scale, centerY, 20 * scale, 5 * scale),
      _iconPaint,
    );
  }
}
