import 'dart:math' as math;
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

  // Animation state for server light flicker
  double _flickerTime = 0;
  double _flickerPhase = 0; // Random phase offset for variety

  // Cached paint objects for performance
  static final _selectPaint = Paint()
    ..color = AppColors.deviceSelection
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _offLightPaint = Paint()
    ..color = AppColors.offIndicator
    ..style = PaintingStyle.fill;

  // Instance-level cached paints (depend on device type)
  late final Paint _bodyPaint;
  late final Paint _borderPaint;

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
      DeviceType.server => AppColors.deviceServer,
      DeviceType.computer => AppColors.deviceComputer,
      DeviceType.phone => AppColors.devicePhone,
      DeviceType.router => AppColors.deviceRouter,
      DeviceType.switch_ => AppColors.deviceSwitch,
      DeviceType.nas => AppColors.deviceNas,
      DeviceType.iot => AppColors.deviceIot,
    };
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Initialize cached paints (depend on device type)
    _bodyPaint = Paint()
      ..color = _deviceColor
      ..style = PaintingStyle.fill;
    _borderPaint = Paint()
      ..color = _deviceColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Random phase offset for subtle variety between devices
    _flickerPhase = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    _isSelected = worldState.selectedEntityId == device.id;
    // Update flicker animation for running devices
    if (device.isRunning) {
      _flickerTime += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Device body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(4),
      ),
      _bodyPaint,
    );

    // Device lights/details with subtle flicker for running devices
    if (device.isRunning) {
      // Subtle flicker: base brightness 0.7-1.0 with sine wave
      final flicker =
          0.85 + 0.15 * math.sin(_flickerTime * 3.0 + _flickerPhase);
      final flickerPaint = Paint()
        ..color = AppColors.runningIndicator.withValues(alpha: flicker)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.x - 10, 10), 3, flickerPaint);
    } else {
      canvas.drawCircle(Offset(size.x - 10, 10), 3, _offLightPaint);
    }

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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(4),
      ),
      _borderPaint,
    );
  }
}
