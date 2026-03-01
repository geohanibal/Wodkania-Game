import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class TiledWall extends PositionComponent {
  TiledWall({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);
}

class VodkaniaMap extends PositionComponent with HasGameReference {
  VodkaniaMap({required this.mapPath});
  static const double tileSize = 64;
  late TiledComponent map;
  final String mapPath;

  @override
  Future<void> onLoad() async {
    // Load the Tiled Map. For real_city.tmx (16x16 base), this scales it to 64x64 visually.
    map = await TiledComponent.load(mapPath, Vector2.all(64));
    add(map);

    // Setup Collisions (Hitboxes for buildings, trees, etc.)
    final collisionsLayer = map.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer != null) {
      for (final object in collisionsLayer.objects) {
        add(
          TiledWall(
            position: Vector2(object.x, object.y),
            size: Vector2(object.width, object.height),
          )..add(RectangleHitbox()..collisionType = CollisionType.passive),
        );
      }
    }
  }
}
