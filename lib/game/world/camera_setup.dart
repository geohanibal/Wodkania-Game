import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';

/// Camera setup and configuration
class CameraSetup {
  static CameraComponent setupCamera(FlameGame game, PlayerComponent player) {
    final camera = CameraComponent(world: game.world);

    // Follow the player
    camera.follow(player);

    // Set viewport
    camera.viewfinder.anchor = Anchor.center;

    return camera;
  }

  static void updateCamera(CameraComponent camera, PlayerComponent player) {
    // Camera automatically follows player
    // Additional camera logic can be added here if needed
  }
}
