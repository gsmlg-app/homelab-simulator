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
    ..color = AppColors.deviceSelection
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _iconPaint = Paint()
    ..color = AppColors.cloudServiceIcon
    ..style = PaintingStyle.fill;

  // Instance-level cached paints (depend on service properties)
  late final Paint _bgPaint;
  late final Paint _bodyPaint;
  late final Paint _providerPaint;
  late final Paint _borderPaint;

  // Cached render values (computed once in onLoad)
  late final double _iconScale;
  late final double _centerX;
  late final double _centerY;

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

    // Cache render values
    _iconScale = size.x / 40;
    _centerX = size.x / 2;
    _centerY = size.y / 2;
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
    // Draw a simple cloud shape using cached values
    canvas.drawCircle(
      Offset(_centerX - 5 * _iconScale, _centerY),
      6 * _iconScale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(_centerX + 5 * _iconScale, _centerY),
      6 * _iconScale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(_centerX, _centerY - 3 * _iconScale),
      5 * _iconScale,
      _iconPaint,
    );

    // Draw bottom rectangle to complete cloud
    canvas.drawRect(
      Rect.fromLTWH(
        _centerX - 10 * _iconScale,
        _centerY,
        20 * _iconScale,
        5 * _iconScale,
      ),
      _iconPaint,
    );
  }
}
