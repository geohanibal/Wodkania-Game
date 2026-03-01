import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A short-lived text component that floats up and fades out.
/// Perfect for combat damage, collection combos, or stealing alerts.
class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;

  double _lifeTimer = 0.0;
  final double maxLife = 1.2; // 1.2 seconds before disappearing

  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    required this.color,
  }) : super(position: position, size: Vector2(80, 40));

  @override
  void update(double dt) {
    super.update(dt);

    _lifeTimer += dt;
    // Float upwards slowly
    position.y -= 35 * dt;

    if (_lifeTimer >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = math.max(0.0, 1.0 - (_lifeTimer / maxLife));

    final textStyle = TextStyle(
      color: color.withValues(alpha: opacity * 255),
      fontSize: 22,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 2.0,
          color: Colors.black.withValues(alpha: opacity * 255),
          offset: const Offset(1, 1),
        ),
      ],
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw centered above the origin
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height),
    );
  }
}
