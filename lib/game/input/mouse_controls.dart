import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Mouse controls for desktop - click and hold to move
class MouseControls extends StatefulWidget {
  const MouseControls({
    required this.onDirectionChanged,
    required this.child,
    super.key,
  });

  final void Function(Vector2) onDirectionChanged;
  final Widget child;

  @override
  State<MouseControls> createState() => _MouseControlsState();
}

class _MouseControlsState extends State<MouseControls> {
  Offset? _mousePosition;
  Offset? _centerPosition;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (_isDragging && _centerPosition != null) {
          setState(() {
            _mousePosition = event.localPosition;
          });
          _updateDirection();
        }
      },
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _centerPosition = details.localPosition;
            _mousePosition = details.localPosition;
            _isDragging = true;
          });
          debugPrint('🖱️ Mouse drag started at: $_centerPosition');
        },
        onPanUpdate: (details) {
          setState(() {
            _mousePosition = details.localPosition;
          });
          _updateDirection();
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            _centerPosition = null;
            _mousePosition = null;
          });
          widget.onDirectionChanged(Vector2.zero());
          debugPrint('🖱️ Mouse drag ended');
        },
        child: widget.child,
      ),
    );
  }

  void _updateDirection() {
    if (_centerPosition == null || _mousePosition == null) return;

    final dx = _mousePosition!.dx - _centerPosition!.dx;
    final dy = _mousePosition!.dy - _centerPosition!.dy;

    final distance = dx * dx + dy * dy;
    if (distance < 25) {
      widget.onDirectionChanged(Vector2.zero());
      return;
    }

    final direction = Vector2(dx, dy).normalized();
    widget.onDirectionChanged(direction);
  }
}
