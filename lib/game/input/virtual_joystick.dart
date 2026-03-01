import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// A virtual joystick component for mobile movement.
class VirtualJoystick extends JoystickComponent {
  VirtualJoystick()
      : super(
          knob: CircleComponent(
            radius: 25,
            paint: BasicPalette.blue.withAlpha(200).paint(),
          ),
          background: CircleComponent(
            radius: 60,
            paint: BasicPalette.black.withAlpha(100).paint(),
          ),
          margin: const EdgeInsets.only(left: 40, bottom: 40),
        );
}
