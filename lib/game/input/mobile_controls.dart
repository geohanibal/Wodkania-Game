import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Mobile joystick controls for player movement
class MobileControls extends StatefulWidget {
  const MobileControls({required this.onDirectionChanged, super.key});

  final void Function(Vector2) onDirectionChanged;

  @override
  State<MobileControls> createState() => _MobileControlsState();
}

class _MobileControlsState extends State<MobileControls> {
  Offset? _joystickPosition;
  Offset? _touchPosition;

  static const double joystickRadius = 80;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Touch area for joystick
        Positioned(
          left: 20,
          bottom: 20,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _joystickPosition = details.localPosition;
                _touchPosition = details.localPosition;
              });
              _updateDirection();
            },
            onPanUpdate: (details) {
              setState(() {
                _touchPosition = details.localPosition;
              });
              _updateDirection();
            },
            onPanEnd: (_) {
              setState(() {
                _joystickPosition = null;
                _touchPosition = null;
              });
              widget.onDirectionChanged(Vector2.zero());
            },
            child: ColoredBox(
              color: Colors.transparent,
              child: SizedBox(
                width: joystickRadius * 3,
                height: joystickRadius * 3,
                child: CustomPaint(
                  painter: _JoystickPainter(
                    joystickPosition: _joystickPosition,
                    touchPosition: _touchPosition,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateDirection() {
    if (_joystickPosition == null || _touchPosition == null) return;

    final dx = _touchPosition!.dx - _joystickPosition!.dx;
    final dy = _touchPosition!.dy - _joystickPosition!.dy;

    final distance = dx * dx + dy * dy;
    if (distance < 1) {
      widget.onDirectionChanged(Vector2.zero());
      return;
    }

    final direction = Vector2(dx, dy).normalized();
    widget.onDirectionChanged(direction);
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.joystickPosition,
    required this.touchPosition,
  });

  final Offset? joystickPosition;
  final Offset? touchPosition;

  @override
  void paint(Canvas canvas, Size size) {
    if (joystickPosition == null) return;

    final center = joystickPosition!;

    // Draw base
    final basePaint = Paint()
      ..color = Colors.white.withValues(
        red: 255,
        green: 255,
        blue: 255,
        alpha: 0.3 * 255,
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 80, basePaint);

    // Draw knob
    if (touchPosition != null) {
      final dx = touchPosition!.dx - center.dx;
      final dy = touchPosition!.dy - center.dy;
      final distance = dx * dx + dy * dy;

      Offset knobPos;
      if (distance > 50 * 50) {
        final angle = (touchPosition! - center).direction;
        knobPos = center + Offset.fromDirection(angle, 50);
      } else {
        knobPos = touchPosition!;
      }

      final knobPaint = Paint()
        ..color = Colors.white.withValues(
          red: 255,
          green: 255,
          blue: 255,
          alpha: 0.7 * 255,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(knobPos, 30, knobPaint);
    }
  }

  @override
  bool shouldRepaint(_JoystickPainter oldDelegate) => true;
}
