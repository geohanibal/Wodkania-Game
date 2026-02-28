import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

// Asset path validation helper
bool looksWrong(String p) =>
  p.contains('assets/images/assets/images') ||
  p.contains('//');

/// Parliament area map with dynamic AI obstacles
class ParliamentMapComponent extends PositionComponent {

  ParliamentMapComponent({this.gameRef});
  VodkaniaGame? gameRef;

  // Performance/memory reporting overlay
  @override
  void update(double dt) {
    // Optionally collect stats here
  }

  void renderPerformanceOverlay(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Memory: ${_memoryUsageMB()} MB',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    canvas.drawRect(
        Rect.fromLTWH(10, 10, textPainter.width + 16, textPainter.height + 16),
        paint,);
    textPainter.paint(canvas, const Offset(18, 18));
  }

  double _memoryUsageMB() {
    // Placeholder: implement actual memory usage reporting
    return 0;
  }

  // Tile map structure for layered rendering
  List<List<String>> tileMap = [];
  List<List<String>> layerMap = [];

  // Asset swapping logic
  void swapTileAsset(int x, int y, String newAsset) {
    if (x >= 0 && y >= 0 && y < tileMap.length && x < tileMap[y].length) {
      tileMap[y][x] = newAsset;
    }
  }

  void swapLayerAsset(int x, int y, String newAsset) {
    if (x >= 0 && y >= 0 && y < layerMap.length && x < layerMap[y].length) {
      layerMap[y][x] = newAsset;
    }
  }
  // Retro-style static map, no chaotic polygons

  // Sprite asset filenames (can be swapped easily)
  // Asset keys for dynamic swapping
  String parliamentSpriteKey = 'parliament';
  List<String> buildingSpriteKeys = [
    'building099',
    'building100',
    'building101',
    'building102',
    'building103',
    'building104',
    'building105',
    'building106',
    'building107',
  ];
  String roadSpriteKey = 'road';
  String sidewalkSpriteKey = 'sidewalk';
  String lampSpriteKey = 'lamp_post';
  String blockSpriteKey = 'roadblock';
  List<String> carSpriteKeys = [
    'car_blue',
    'car_green',
    'car_yellow',
    'car_purple',
  ];

  // Asset registry for swapping
  final Map<String, String> assetRegistry = {
    'parliament': 'tiles/parliament.png', // Parliament PNG asset
    'building099': 'buildings/buildingTiles_099.png',
    'building100': 'buildings/buildingTiles_100.png',
    'building101': 'buildings/buildingTiles_101.png',
    'building102': 'buildings/buildingTiles_102.png',
    'building103': 'buildings/buildingTiles_103.png',
    'building104': 'buildings/buildingTiles_104.png',
    'building105': 'buildings/buildingTiles_105.png',
    'building106': 'buildings/buildingTiles_106.png',
    'building107': 'buildings/buildingTiles_107.png',
    'road': 'tiles/tile_0009.png',
    // 'sidewalk': 'assets/images/tiles/tile_0004.png', // Removed: asset missing
    // 'car_blue': 'assets/images/vehicles/car_blue2.png', // Deprecated, use canonical loader
  };

  // Layered tile map
  final List<SpriteComponent> _tiles = [];
  final List<SpriteComponent> _buildings = [];
  final List<SpriteComponent> _roads = [];
  final List<SpriteComponent> _sidewalks = [];
  final List<SpriteComponent> _cars = [];

  // Store building obstacles for collision
  final List<_Obstacle> _buildingObstacles = [];

  // ParliamentMapComponent exposes _buildingObstacles as public getter
  List<_Obstacle> get buildingObstacles => _buildingObstacles;

  // Utility: check collision with building obstacles
  bool isPlayerCollidingWithBuilding(
      Vector2 playerPosition, double playerRadius,) {
    for (final obstacle in _buildingObstacles) {
      final buildingRect = obstacle.rect;
      final playerRect = Rect.fromCircle(
          center: Offset(playerPosition.x, playerPosition.y),
          radius: playerRadius,);
      if (buildingRect.overlaps(playerRect)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> onLoad() async {
    debugPrint('--- Asset load paths ---');
    assetRegistry.forEach((k, v) => debugPrint('$k: $v'));
    // Parliament
    try {
      final parliamentPath = assetRegistry[parliamentSpriteKey]!;
      debugPrint('LOAD: $parliamentPath');
      assert(!looksWrong(parliamentPath), 'Asset path looks wrong: $parliamentPath');
      final sprite = await Sprite.load(parliamentPath);
      final parliament = SpriteComponent()
        ..sprite = sprite
        ..size = Vector2(GameConfig.worldWidth * 0.2, GameConfig.worldHeight * 0.15)
        ..position = Vector2(GameConfig.worldWidth * 0.4, GameConfig.worldHeight * 0.2);
      _tiles.add(parliament);
      await add(parliament);
    } catch (e) {
      debugPrint('Failed to load parliament sprite: $e');
    }

    // Buildings: arrange in grid (5x2)
    for (var i = 0; i < 10; i++) {
      try {
        // Use assetRegistry for first 5, then repeat
        final key = 'building${(i % 5) + 1}';
        final buildingPath = assetRegistry[key]!;
        debugPrint('LOAD: $buildingPath');
        assert(!looksWrong(buildingPath), 'Asset path looks wrong: $buildingPath');
        final sprite = await Sprite.load(buildingPath);
        final comp = SpriteComponent()
          ..sprite = sprite
          ..size = Vector2(GameConfig.worldWidth * 0.08, GameConfig.worldHeight * 0.09)
          ..position = Vector2(
            GameConfig.worldWidth * (0.15 + 0.15 * (i % 5)),
            GameConfig.worldHeight * (0.1 + 0.18 * (i ~/ 5)),
          );
        _buildings.add(comp);
        await add(comp);
        // Add obstacle for collision
        final rect = Rect.fromLTWH(
          comp.position.x,
          comp.position.y,
          comp.size.x,
          comp.size.y,
        );
        _buildingObstacles.add(_Obstacle(rect));
      } catch (e) {
        debugPrint('Failed to load building sprite $i: $e');
      }
    }

    // Road tiles
    for (var i = 0; i < 5; i++) {
      try {
        final roadPath = assetRegistry[roadSpriteKey]!;
        debugPrint('LOAD: $roadPath');
        assert(!looksWrong(roadPath), 'Asset path looks wrong: $roadPath');
        final sprite = await Sprite.load(roadPath);
        final comp = SpriteComponent()
          ..sprite = sprite
          ..size = Vector2(GameConfig.worldWidth * 0.1, GameConfig.worldHeight * 0.05)
          ..position = Vector2(GameConfig.worldWidth * (0.15 + 0.15 * i), GameConfig.worldHeight * 0.5);
        _roads.add(comp);
        await add(comp);
      } catch (e) {
        debugPrint('Failed to load road sprite $i: $e');
      }
    }

    // Sidewalk tiles
    for (var i = 0; i < 5; i++) {
      try {
        final sidewalkPath = assetRegistry[sidewalkSpriteKey]!;
        debugPrint('LOAD: $sidewalkPath');
        assert(!looksWrong(sidewalkPath), 'Asset path looks wrong: $sidewalkPath');
        final sprite = await Sprite.load(sidewalkPath);
        final comp = SpriteComponent()
          ..sprite = sprite
          ..size = Vector2(GameConfig.worldWidth * 0.1, GameConfig.worldHeight * 0.05)
          ..position = Vector2(GameConfig.worldWidth * (0.15 + 0.15 * i), GameConfig.worldHeight * 0.45);
        _sidewalks.add(comp);
        await add(comp);
      } catch (e) {
        debugPrint('Failed to load sidewalk sprite $i: $e');
      }
    }

    // Lamp posts
    for (var i = 0; i < 2; i++) {
      try {
        // No lamp_post asset available, skip
        continue; // No lamp_post asset available, skip
      } catch (e) {
        debugPrint('Failed to load lamp post sprite $i: $e');
      }
    }

    // Roadblocks
    for (var i = 0; i < 2; i++) {
      try {
        // No roadblock asset available, skip
        continue; // No roadblock asset available, skip
      } catch (e) {
        debugPrint('Failed to load roadblock sprite $i: $e');
      }
    }

    // Cars (example: blue sedan facing east)
    // Add a blue sedan car using an existing PNG (carBlue2_000.png)
    try {
      const carPath = 'vehicles/PNG/Civilian/Blue/Sedan 1/carBlue2_000.png';
      assert(!looksWrong(carPath), 'Asset path looks wrong: $carPath');
      final sprite = await Sprite.load(carPath);
      final comp = SpriteComponent()
        ..sprite = sprite
        ..size = Vector2(GameConfig.worldWidth * 0.07, GameConfig.worldHeight * 0.04)
        ..position = Vector2(GameConfig.worldWidth * 0.18, GameConfig.worldHeight * 0.7);
      _cars.add(comp);
      await add(comp);
    } catch (e) {
      debugPrint('Failed to load car sprite (Civilian/Blue/Sedan 1, carBlue2_000.png): $e');
    }
  }

  // No need for manual render; children are rendered automatically
}

// Simple obstacle class for collision
class _Obstacle {
  _Obstacle(this.rect);
  final Rect rect;
}
