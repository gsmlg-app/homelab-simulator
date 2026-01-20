import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

/// Renders a placed cloud service in the game world
class CloudServiceComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final CloudServiceModel service;
  final double tileSize;
  bool _isSelected = false;

  CloudServiceComponent({
    required this.service,
    this.tileSize = GameConstants.tileSize,
  }) : super(
          position: Vector2(
            service.position.x * tileSize,
            service.position.y * tileSize,
          ),
          size: Vector2(
            service.width * tileSize,
            service.height * tileSize,
          ),
        );

  Color get _providerColor {
    return switch (service.provider) {
      CloudProvider.aws => const Color(0xFFFF9900),
      CloudProvider.gcp => const Color(0xFF4285F4),
      CloudProvider.cloudflare => const Color(0xFFF38020),
      CloudProvider.vultr => const Color(0xFF007BFC),
      CloudProvider.azure => const Color(0xFF0078D4),
      CloudProvider.digitalOcean => const Color(0xFF0080FF),
      CloudProvider.none => const Color(0xFF9B59B6),
    };
  }

  Color get _categoryColor {
    return switch (service.category) {
      ServiceCategory.compute => const Color(0xFF3498DB),
      ServiceCategory.storage => const Color(0xFF27AE60),
      ServiceCategory.database => const Color(0xFFF39C12),
      ServiceCategory.networking => const Color(0xFF9B59B6),
      ServiceCategory.serverless => const Color(0xFFE74C3C),
      ServiceCategory.container => const Color(0xFF1ABC9C),
      ServiceCategory.other => const Color(0xFF607D8B),
    };
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
    final bgPaint = Paint()
      ..color = _providerColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    // Service body with category color
    final bodyPaint = Paint()
      ..color = _categoryColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.x - 16, size.y - 16),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Provider indicator (small colored dot in corner)
    final providerPaint = Paint()
      ..color = _providerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x - 12, 12),
      5,
      providerPaint,
    );

    // Cloud icon representation (simplified)
    _drawCloudIcon(canvas);

    // Selection highlight
    if (_isSelected) {
      final selectPaint = Paint()
        ..color = const Color(0xFFFFFF00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
          const Radius.circular(6),
        ),
        selectPaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = _providerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(6),
      ),
      borderPaint,
    );
  }

  void _drawCloudIcon(Canvas canvas) {
    final iconPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final scale = size.x / 40; // Scale icon based on tile size

    // Draw a simple cloud shape
    canvas.drawCircle(Offset(centerX - 5 * scale, centerY), 6 * scale, iconPaint);
    canvas.drawCircle(Offset(centerX + 5 * scale, centerY), 6 * scale, iconPaint);
    canvas.drawCircle(Offset(centerX, centerY - 3 * scale), 5 * scale, iconPaint);

    // Draw bottom rectangle to complete cloud
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - 10 * scale,
        centerY,
        20 * scale,
        5 * scale,
      ),
      iconPaint,
    );
  }
}
