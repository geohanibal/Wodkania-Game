import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard controls for desktop platforms
class KeyboardControls extends StatefulWidget {
  const KeyboardControls({
    required this.onDirectionChanged,
    required this.child,
    super.key,
  });

  final void Function(Vector2) onDirectionChanged;
  final Widget child;

  @override
  State<KeyboardControls> createState() => _KeyboardControlsState();
}

class _KeyboardControlsState extends State<KeyboardControls> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      debugPrint('🎯 Keyboard focus requested');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
        debugPrint('🖱️ Focus requested via tap');
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            _pressedKeys.add(event.logicalKey);
            _updateDirection();
            return KeyEventResult.handled;
          } else if (event is KeyUpEvent) {
            _pressedKeys.remove(event.logicalKey);
            _updateDirection();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ColoredBox(color: Colors.transparent, child: widget.child),
      ),
    );
  }

  void _updateDirection() {
    double dx = 0;
    double dy = 0;

    // WASD controls
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }

    if (dx == 0 && dy == 0) {
      widget.onDirectionChanged(Vector2.zero());
    } else {
      widget.onDirectionChanged(Vector2(dx, dy).normalized());
    }
  }
}
