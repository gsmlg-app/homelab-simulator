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
  // Reusable paint for flicker animation (color updated per frame)
  final Paint _flickerPaint = Paint()..style = PaintingStyle.fill;

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

  // Animation cycle period (2π for sine wave)
  static const _animationPeriod = math.pi * 2;

  @override
  void update(double dt) {
    super.update(dt);
    final worldState = bloc.state;
    _isSelected = worldState.selectedEntityId == device.id;
    // Update flicker animation for running devices (bounded to prevent overflow)
    if (device.isRunning) {
      _flickerTime = (_flickerTime + dt) % _animationPeriod;
    }
  }

  @override
  void render(Canvas canvas) {
    const padding = GameConstants.deviceBodyPadding;
    const radius = Radius.circular(GameConstants.deviceCornerRadius);
    const inset = GameConstants.deviceSelectionInset;
    const ledRadius = GameConstants.deviceLedRadius;
    const ledOffset = GameConstants.deviceLedOffset;

    // Device body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, size.x - padding * 2, size.y - padding * 2),
        radius,
      ),
      _bodyPaint,
    );

    // Device lights/details with subtle flicker for running devices
    if (device.isRunning) {
      // Subtle flicker using centralized animation constants
      final flicker = GameConstants.deviceFlickerMin +
          GameConstants.deviceFlickerAmplitude *
              math.sin(
                _flickerTime * GameConstants.deviceFlickerFrequency +
                    _flickerPhase,
              );
      _flickerPaint.color = AppColors.runningIndicator.withValues(
        alpha: flicker,
      );
      canvas.drawCircle(Offset(size.x - ledOffset, ledOffset), ledRadius, _flickerPaint);
    } else {
      canvas.drawCircle(Offset(size.x - ledOffset, ledOffset), ledRadius, _offLightPaint);
    }

    // Selection highlight
    if (_isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.x - inset * 2, size.y - inset * 2),
          radius,
        ),
        _selectPaint,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, size.x - padding * 2, size.y - padding * 2),
        radius,
      ),
      _borderPaint,
    );
  }
}
