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
    ..strokeWidth = GameConstants.glowStrokeBase;
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
      ..strokeWidth = GameConstants.glowStrokeBase;

    // Cache render values
    _iconScale = size.x / GameConstants.cloudServiceIconScaleDivisor;
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
    // Use centralized drawing constants
    const bgp = GameConstants.cloudServiceBgPadding;
    const bp = GameConstants.cloudServiceBodyPadding;
    const sp = GameConstants.cloudServiceSelectionPadding;
    const bgr = GameConstants.cloudServiceBgRadius;
    const br = GameConstants.cloudServiceBodyRadius;
    const pdx = GameConstants.cloudServiceProviderDotXOffset;
    const pdy = GameConstants.cloudServiceProviderDotYOffset;
    const pdr = GameConstants.cloudServiceProviderDotRadius;

    // Background with provider color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bgp, bgp, size.x - bgp * 2, size.y - bgp * 2),
        const Radius.circular(bgr),
      ),
      _bgPaint,
    );

    // Service body with category color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bp, bp, size.x - bp * 2, size.y - bp * 2),
        const Radius.circular(br),
      ),
      _bodyPaint,
    );

    // Provider indicator (small colored dot in corner)
    canvas.drawCircle(Offset(size.x - pdx, pdy), pdr, _providerPaint);

    // Cloud icon representation (simplified)
    _drawCloudIcon(canvas);

    // Selection highlight
    if (_isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sp, sp, size.x - sp * 2, size.y - sp * 2),
          const Radius.circular(bgr),
        ),
        _selectPaint,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bgp, bgp, size.x - bgp * 2, size.y - bgp * 2),
        const Radius.circular(bgr),
      ),
      _borderPaint,
    );
  }

  void _drawCloudIcon(Canvas canvas) {
    // Use centralized cloud icon constants
    const ho = GameConstants.cloudIconHorizontalOffset;
    const mr = GameConstants.cloudIconMainRadius;
    const tyo = GameConstants.cloudIconTopYOffset;
    const tr = GameConstants.cloudIconTopRadius;
    const rhw = GameConstants.cloudIconRectHalfWidth;
    const rh = GameConstants.cloudIconRectHeight;

    // Draw a simple cloud shape using cached values
    canvas.drawCircle(
      Offset(_centerX - ho * _iconScale, _centerY),
      mr * _iconScale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(_centerX + ho * _iconScale, _centerY),
      mr * _iconScale,
      _iconPaint,
    );
    canvas.drawCircle(
      Offset(_centerX, _centerY - tyo * _iconScale),
      tr * _iconScale,
      _iconPaint,
    );

    // Draw bottom rectangle to complete cloud
    canvas.drawRect(
      Rect.fromLTWH(
        _centerX - rhw * _iconScale,
        _centerY,
        rhw * 2 * _iconScale,
        rh * _iconScale,
      ),
      _iconPaint,
    );
  }
}
