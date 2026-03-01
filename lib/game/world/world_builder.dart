import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/vodkania_map.dart';

class PhotoMap extends PositionComponent {
  PhotoMap({required this.assetPath});
  final String assetPath;

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load(assetPath);
    add(
      SpriteComponent(
        sprite: sprite,
        size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
      ),
    );
  }
}

/// Builds the game world
class WorldBuilder {
  static Component createWorld() {
    // Create a simple colored background and add map obstacles
    return RectangleComponent(
      size: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
      paint: Paint()..color = const Color(0xFF000000), // Black background
      position: Vector2.zero(),
      children: [
        if (GameState.instance.isTiledMap)
          VodkaniaMap(mapPath: GameState.instance.selectedMap)
        else
          PhotoMap(assetPath: GameState.instance.selectedMap),
      ],
    );
  }

  static List<Component> createBoundaries() {
    // Create visible boundaries to show world edges
    final boundaries = <Component>[];

    // Top - Red border
    boundaries.add(
      RectangleComponent(
        size: Vector2(GameConfig.worldWidth, 10),
        position: Vector2(0, 0),
        paint: Paint()..color = const Color(0xFFE53935),
      ),
    );

    // Bottom - Red border
    boundaries.add(
      RectangleComponent(
        size: Vector2(GameConfig.worldWidth, 10),
        position: Vector2(0, GameConfig.worldHeight - 10),
        paint: Paint()..color = const Color(0xFFE53935),
      ),
    );

    // Left - Red border
    boundaries.add(
      RectangleComponent(
        size: Vector2(10, GameConfig.worldHeight),
        position: Vector2(0, 0),
        paint: Paint()..color = const Color(0xFFE53935),
      ),
    );

    // Right - Red border
    boundaries.add(
      RectangleComponent(
        size: Vector2(10, GameConfig.worldHeight),
        position: Vector2(GameConfig.worldWidth - 10, 0),
        paint: Paint()..color = const Color(0xFFE53935),
      ),
    );

    return boundaries;
  }
}

/// Grid component to visualize movement
class GridComponent extends Component {
  @override
  void render(Canvas canvas) {
    final gridPaint = Paint()
      ..color = const Color(
        0xFF2E7D32,
      ).withValues(red: 46, green: 125, blue: 50, alpha: 0.4 * 255)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const gridSize = 100.0;

    // Draw vertical lines
    for (double x = 0; x <= GameConfig.worldWidth; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, GameConfig.worldHeight),
        gridPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= GameConfig.worldHeight; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(GameConfig.worldWidth, y),
        gridPaint,
      );
    }

    // Draw center cross (yellow - more visible)
    final centerPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4;

    final centerX = GameConfig.worldWidth / 2;
    final centerY = GameConfig.worldHeight / 2;

    // Horizontal center line
    canvas.drawLine(
      Offset(centerX - 80, centerY),
      Offset(centerX + 80, centerY),
      centerPaint,
    );

    // Vertical center line
    canvas.drawLine(
      Offset(centerX, centerY - 80),
      Offset(centerX, centerY + 80),
      centerPaint,
    );
  }
}
