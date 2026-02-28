import 'dart:io';
import 'dart:math';

void main() {
  const int width = 100;
  const int height = 100;
  List<int> groundData = List.filled(width * height, 0);
  List<String> collisionObjects = [];
  final random = Random(42);

  // GID 1: Sidewalk (tile_0009.png)
  // GID 2: Road (tile_0004.png)
  
  // 1. Generate Ground Layer (Grid based)
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      bool isRoad = (x % 10 == 0 || x % 10 == 1 || y % 10 == 0 || y % 10 == 1);
      groundData[y * width + x] = isRoad ? 2 : 1;
    }
  }

  int objectId = 1;
  
  // 3. Central Parliament Collision
  int centerX = (width ~/ 2) * 64;
  int centerY = (height ~/ 2) * 64;
  int parliamentSize = 64 * 6; // 384x384
  
  collisionObjects.add(
    '  <object id="${objectId++}" name="Parliament" x="${centerX - parliamentSize ~/ 2}" y="${centerY - parliamentSize ~/ 2}" width="$parliamentSize" height="$parliamentSize"/>'
  );

  // 2. Procedural Building Placement Collisions
  for (int by = 2; by < height - 4; by += 10) {
    for (int bx = 2; bx < width - 4; bx += 10) {
      // Don't place buildings near the center (Parliament)
      if (bx > width ~/ 2 - 8 && bx < width ~/ 2 + 8 && by > height ~/ 2 - 8 && by < height ~/ 2 + 8) {
        continue;
      }

      for (int iy = 0; iy < 2; iy++) {
        for (int ix = 0; ix < 2; ix++) {
          if (random.nextDouble() > 0.1) { 
            // 90% chance to have a building
            int px = (bx + ix * 4) * 64;
            int py = (by + iy * 4) * 64;
            int size = 64 * 3; // tileSize * 3
            
            collisionObjects.add(
              '  <object id="${objectId++}" name="Building" x="$px" y="$py" width="$size" height="$size"/>'
            );
          }
        }
      }
    }
  }

  // Create TMX content
  final tmxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal" renderorder="right-down" width="$width" height="$height" tilewidth="64" tileheight="64" infinite="0" nextlayerid="4" nextobjectid="$objectId">
 <tileset firstgid="1" name="BaseTiles" tilewidth="64" tileheight="64" tilecount="2" columns="2">
  <image source="BaseTiles.png" width="128" height="64"/>
 </tileset>
 <layer id="1" name="Ground" width="$width" height="$height">
  <data encoding="csv">
${_chunkList(groundData, width)}
  </data>
 </layer>
 <objectgroup id="2" name="Collisions">
${collisionObjects.join('\n')}
 </objectgroup>
</map>''';

  File('map.tmx').writeAsStringSync(tmxContent);
  print('Generated map.tmx successfully!');
}

String _chunkList(List<int> list, int chunkSize) {
  List<String> lines = [];
  for (int i = 0; i < list.length; i += chunkSize) {
    lines.add(list.sublist(i, i + chunkSize).join(','));
  }
  return lines.join(',\n');
}
