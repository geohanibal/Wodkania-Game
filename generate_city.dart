import 'dart:io';
import 'dart:math';

void main() {
  generateMap(60, 60, 'map.tmx');
  generateMap(30, 30, 'map_small.tmx');
}

void generateMap(int width, int height, String filename) {
  List<int> groundData = List.filled(width * height, 0);
  List<int> propsData = List.filled(width * height, 0);
  List<String> collisionObjects = [];
  final random = Random(42);

  // 1. Generate Ground Layer
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // Create a grid of roads every 12 tiles
      bool isRoad = (x % 12 == 0 || x % 12 == 1 || y % 12 == 0 || y % 12 == 1);
      groundData[y * width + x] = isRoad ? 2 : 1;
    }
  }

  final props = [
    'barricade_top.png', 'bench_top.png', 'bus_stop_top.png', 'bush_round_top.png', 
    'crosswalk_top.png', 'road_straight_top.png', 'street_lamp_top.png', 
    'traffic_cone_top.png', 'trash_bin_top.png', 'tree_oak_top.png', 'tree_pine_top.png'
  ];
  
  final cars = [
    'car_ambulance_top.png', 'car_police_top.png', 'car_sedan_top.png'
  ];

  final buildings = List.generate(20, (i) => 'buildingTiles_${(i + 90).toString().padLeft(3, '0')}.png');

  Map<String, String> objectPaths = {};
  for (var p in props) objectPaths[p] = '../images/generated_sprite_pack/objects/$p';
  for (var c in cars) objectPaths[c] = '../images/generated_sprite_pack/objects/$c';
  for (var b in buildings) objectPaths[b] = '../images/buildings/$b';
  objectPaths['parliament.png'] = '../images/tiles/parliament.png';

  final allObjects = [...props, ...cars, ...buildings, 'parliament.png'];
  Map<String, int> objectGids = {};
  int currentGid = 3;
  for (var obj in allObjects) {
    objectGids[obj] = currentGid++;
  }

  int objectId = 1;

  // 1.5. Place Parliament (12x8 tiles)
  // We place it at center roughly.
  int parlGX = (width ~/ 2) - 6;
  if (parlGX < 0) parlGX = 2; // safety
  int parlGY = (height ~/ 2) + 4; // Bottom row
  if (parlGY >= height) parlGY = height - 1;
  
  propsData[parlGY * width + parlGX] = objectGids['parliament.png']!;
  collisionObjects.add(
    '  <object id="${objectId++}" name="Wall_Parliament" x="${parlGX * 64 + 20}" y="${(parlGY - 7) * 64 + 20}" width="728" height="472"/>'
  );

  // 2. Procedural Object Placement
  for (int by = 2; by < height - 2; by += 4) {
    for (int bx = 2; bx < width - 2; bx += 4) {
      if (bx % 12 == 0 || bx % 12 == 1 || by % 12 == 0 || by % 12 == 1) continue;

      double chance = random.nextDouble();
      String? selectedObject;
      bool hasCollision = true;

      // Skip parliament area roughly
      if (bx >= parlGX && bx <= parlGX + 12 && by >= parlGY - 8 && by <= parlGY) {
        continue;
      }

      if (chance < 0.3) {
        selectedObject = buildings[random.nextInt(buildings.length)];
        int bWidth = 128;
        int bHeight = 128;
        int gid = objectGids[selectedObject]!;
        // Buildings are 2x2. Place at (bx, by + 1)
        if (by + 1 < height) {
          propsData[(by + 1) * width + bx] = gid;
          String baseName = selectedObject.replaceAll('.png', '');
          collisionObjects.add(
            '  <object id="${objectId++}" name="Wall_$baseName" x="${bx * 64 + 5}" y="${by * 64 + 5}" width="${bWidth - 10}" height="${bHeight - 10}"/>'
          );
        }
      } else if (chance < 0.8) {
        // 64x64 props
        if (chance < 0.45) selectedObject = 'tree_oak_top.png';
        else if (chance < 0.6) selectedObject = 'tree_pine_top.png';
        else if (chance < 0.65) selectedObject = 'bush_round_top.png';
        else if (chance < 0.7) selectedObject = 'bench_top.png';
        else if (chance < 0.73) selectedObject = 'bus_stop_top.png';
        else if (chance < 0.76) { selectedObject = 'street_lamp_top.png'; hasCollision = false; }
        else selectedObject = 'trash_bin_top.png';

        int gid = objectGids[selectedObject]!;
        propsData[by * width + bx] = gid;
        if (hasCollision) {
          collisionObjects.add(
            '  <object id="${objectId++}" name="Wall_Prop" x="${bx * 64 + 10}" y="${by * 64 + 10}" width="44" height="44"/>'
          );
        }
      }
    }
  }

  // 3. Cars
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
       bool isHorizontalRoad = (y % 12 == 0 || y % 12 == 1);
       bool isVerticalRoad = (x % 12 == 0 || x % 12 == 1);
       if ((isHorizontalRoad || isVerticalRoad) && !(isHorizontalRoad && isVerticalRoad)) {
         if (random.nextDouble() < 0.05) {
            String carType = random.nextDouble() < 0.2 ? 'car_police_top.png' : 
                             random.nextDouble() < 0.3 ? 'car_ambulance_top.png' : 'car_sedan_top.png';
            propsData[y * width + x] = objectGids[carType]!;
            collisionObjects.add(
              '  <object id="${objectId++}" name="Wall_Car" x="${x * 64 + 5}" y="${y * 64 + 5}" width="54" height="54"/>'
            );
         }
       }
    }
  }

  // Generate TSX only once (for the large map is fine, or always, doesn't matter)
  if (filename == 'map.tmx') {
    StringBuffer tsxContent = StringBuffer();
    tsxContent.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    tsxContent.writeln('<tileset version="1.10" tiledversion="1.11.2" name="CityObjects" tilewidth="64" tileheight="64" tilecount="${allObjects.length}" columns="0">');
    for (int i = 0; i < allObjects.length; i++) {
      String objName = allObjects[i];
      String path = objectPaths[objName]!;
      int imgW = 64, imgH = 64;
      if (objName.startsWith('building')) { imgW = 128; imgH = 128; }
      else if (objName == 'parliament.png') { imgW = 768; imgH = 512; }
      tsxContent.writeln(' <tile id="$i"><image source="$path" width="$imgW" height="$imgH"/></tile>');
    }
    tsxContent.writeln('</tileset>');
    File('assets/tiles/CityObjects.tsx').writeAsStringSync(tsxContent.toString());
  }

  // Generate TMX
  final tmxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal" renderorder="right-down" width="$width" height="$height" tilewidth="64" tileheight="64" infinite="0" nextlayerid="5" nextobjectid="$objectId">
 <tileset firstgid="1" name="BaseTiles" tilewidth="64" tileheight="64" tilecount="2" columns="2">
  <image source="../images/BaseTiles.png" width="128" height="64"/>
 </tileset>
 <tileset firstgid="3" source="CityObjects.tsx"/>
 <layer id="1" name="Ground" width="$width" height="$height">
  <data encoding="csv">${_chunkList(groundData, width)}</data>
 </layer>
 <layer id="2" name="Props" width="$width" height="$height">
  <data encoding="csv">${_chunkList(propsData, width)}</data>
 </layer>
 <objectgroup id="3" name="Collisions">
${collisionObjects.join('\n')}
 </objectgroup>
</map>''';
  File('assets/tiles/$filename').writeAsStringSync(tmxContent);
  print('Regenerated $filename with Tile Layer for Props.');
}

String _chunkList(List<int> list, int chunkSize) {
  List<String> lines = [];
  for (int i = 0; i < list.length; i += chunkSize) {
    lines.add(list.sublist(i, i + chunkSize).join(','));
  }
  return '\n' + lines.join(',\n') + '\n';
}
