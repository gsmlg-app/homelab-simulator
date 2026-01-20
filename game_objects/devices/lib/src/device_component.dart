import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Renders a placed device in the game world
class DeviceComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final DeviceModel device;
  final double tileSize;
  bool _isSelected = false;

  // Cached paint objects for performance
  static final _selectPaint = Paint()
    ..color = const Color(0xFFFFFF00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _runningLightPaint = Paint()
    ..color = const Color(0xFF00FF00)
    ..style = PaintingStyle.fill;
  static final _offLightPaint = Paint()
    ..color = const Color(0xFF666666)
    ..style = PaintingStyle.fill;

  DeviceComponent({
    required this.device,
    this.tileSize = GameConstants.tileSize,
  }) : super(
         position: Vector2(
           device.position.x * tileSize,
           device.position.y * tileSize,
         ),
         size: Vector2(device.width * tileSize, device.height * tileSize),
       );

  Color get _deviceColor {
    return switch (device.type) {
      DeviceType.server => const Color(0xFF3498DB),
      DeviceType.computer => const Color(0xFF9B59B6),
      DeviceType.phone => const Color(0xFFE74C3C),
      DeviceType.router => const Color(0xFFF39C12),
      DeviceType.switch_ => const Color(0xFF1ABC9C),
      DeviceType.nas => const Color(0xFF34495E),
      DeviceType.iot => const Color(0xFF27AE60),
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    _isSelected = worldState.selectedEntityId == device.id;
  }

  @override
  void render(Canvas canvas) {
    // Device body
    final bodyPaint = Paint()
      ..color = _deviceColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Device lights/details
    final detailPaint = device.isRunning ? _runningLightPaint : _offLightPaint;
    canvas.drawCircle(Offset(size.x - 10, 10), 3, detailPaint);

    // Selection highlight
    if (_isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
          const Radius.circular(4),
        ),
        _selectPaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = _deviceColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(4),
      ),
      borderPaint,
    );
  }
}
