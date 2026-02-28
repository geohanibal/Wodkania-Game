import 'dart:io';

void main() {
  const width = 60;
  const height = 60;
  final grassData = List<int>.filled(width * height, 1);
  final propsData = List<int>.filled(width * height, 0);

  // Generate TMX
  final tmxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal" renderorder="right-down" width="$width" height="$height" tilewidth="16" tileheight="16" infinite="0" nextlayerid="4" nextobjectid="1">
 <tileset firstgid="1" source="city_tileset.tsx"/>
 <layer id="1" name="Ground" width="$width" height="$height">
  <data encoding="csv">${grassData.join(',')}</data>
 </layer>
 <layer id="2" name="Props" width="$width" height="$height">
  <data encoding="csv">${propsData.join(',')}</data>
 </layer>
 <objectgroup id="3" name="Collisions"/>
</map>''';

  File('assets/tiles/real_city.tmx').writeAsStringSync(tmxContent);
  print('Updated real_city.tmx with grass data.');
}
