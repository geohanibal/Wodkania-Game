import 'dart:io';
import 'package:image/image.dart';

void main() {
  final image = Image(width: 128, height: 64);

  // Fill first 64x64 with Sidewalk color (grey)
  fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 63,
    y2: 63,
    color: ColorRgb8(120, 120, 120),
  );

  // Fill second 64x64 with Road color (dark grey)
  fillRect(image, x1: 64, y1: 0, x2: 127, y2: 63, color: ColorRgb8(80, 80, 80));

  final png = encodePng(image);
  File('BaseTiles.png').writeAsBytesSync(png);
  print('Generated BaseTiles.png');
}
