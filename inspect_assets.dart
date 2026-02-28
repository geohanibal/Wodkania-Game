import 'dart:io';
import 'package:image/image.dart';

void main() {
  final sb = StringBuffer();

  void checkImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }
    final bytes = file.readAsBytesSync();
    final img = decodeImage(bytes);
    if (img != null) {
      sb.writeln('Image ${file.path.split(Platform.pathSeparator).last}: ${img.width}x${img.height}');
    }
  }

  sb.writeln('--- Objects ---');
  final oDir = Directory('assets/images/generated_sprite_pack/objects');
  if (oDir.existsSync()) {
    final entities = oDir.listSync(recursive: true).whereType<File>().toList();
    entities.sort((a, b) => a.path.compareTo(b.path));
    for (final f in entities) {
      if (f.path.endsWith('.png')) checkImage(f.path);
    }
  }

  sb.writeln('\n--- Buildings ---');
  final bDir = Directory('assets/images/buildings');
  if (bDir.existsSync()) {
    final entities = bDir.listSync(recursive: true).whereType<File>().toList();
    entities.sort((a, b) => a.path.compareTo(b.path));
    // Sample first few
    for (var i = 0; i < entities.length; i++) {
      final f = entities[i];
      if (f.path.endsWith('.png')) checkImage(f.path);
      if (i > 100) break; // Don't overflow output
    }
  }

  sb.writeln('\n--- Tiles ---');
  checkImage('assets/images/tiles/parliament.png');
  checkImage('assets/images/BaseTiles.png');
  
  File('output_dims.txt').writeAsStringSync(sb.toString());
  print('Generated output_dims.txt');
}
