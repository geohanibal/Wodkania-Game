import 'dart:io';
import 'package:image/image.dart' as img;

/// Sprite generator for creating pixel art character animations
void main() {
  print('🎨 Generating player sprites...');

  final generator = SpriteGenerator();

  // Generate all animations
  generator.generateWalkRight();
  generator.generateWalkLeft();
  generator.generateIdle();

  print('✅ Sprites generated successfully!');
  print('📁 Location: assets/images/player/');
}

class SpriteGenerator {
  static const int frameWidth = 64;
  static const int frameHeight = 64;

  // Character colors (based on provided sprite sheets)
  static const skinColor = 0xFFD4A574; // Tan skin
  static const hairColor = 0xFF1A1A1A; // Black hair
  static const capColor = 0xFF2C2C2C; // Dark cap
  static const jacketColor = 0xFF6B6B6B; // Gray jacket
  static const pantsColor = 0xFF2B2B4F; // Dark blue pants
  static const shoesColor = 0xFF1A1A1A; // Black shoes
  static const beardColor = 0xFF3D2817; // Brown beard

  void generateWalkRight() {
    const width = frameWidth * 8; // 8 frames
    const height = frameHeight;
    final image = img.Image(width: width, height: height);

    for (var frame = 0; frame < 8; frame++) {
      final x = frame * frameWidth;
      _drawWalkFrame(image, x, 0, frame, false);
    }

    final bytes = img.encodePng(image);
    File('assets/images/player/walk_right.png').writeAsBytesSync(bytes);
    print('✓ walk_right.png created');
  }

  void generateWalkLeft() {
    const width = frameWidth * 8; // 8 frames
    const height = frameHeight;
    final image = img.Image(width: width, height: height);

    for (var frame = 0; frame < 8; frame++) {
      final x = frame * frameWidth;
      _drawWalkFrame(image, x, 0, frame, true);
    }

    final bytes = img.encodePng(image);
    File('assets/images/player/walk_left.png').writeAsBytesSync(bytes);
    print('✓ walk_left.png created');
  }

  void generateIdle() {
    const width = frameWidth * 4; // 4 frames
    const height = frameHeight;
    final image = img.Image(width: width, height: height);

    for (var frame = 0; frame < 4; frame++) {
      final x = frame * frameWidth;
      _drawIdleFrame(image, x, 0, frame);
    }

    final bytes = img.encodePng(image);
    File('assets/images/player/idle.png').writeAsBytesSync(bytes);
    print('✓ idle.png created');
  }

  void _drawWalkFrame(
      img.Image image, int offsetX, int offsetY, int frame, bool facingLeft,) {
    final centerX = offsetX + frameWidth ~/ 2;
    final centerY = offsetY + frameHeight ~/ 2;

    // Walking animation cycle
    final legOffset = (frame % 4 < 2) ? 2 : -2;
    final armSwing = (frame % 4 < 2) ? 1 : -1;
    final bobbing = (frame % 2 == 0) ? 0 : -1;

    // Draw character from bottom to top
    _drawLegs(image, centerX, centerY + 15 + bobbing, legOffset, facingLeft);
    _drawBody(image, centerX, centerY + bobbing, facingLeft);
    _drawArms(image, centerX, centerY + 2 + bobbing, armSwing, facingLeft);
    _drawHead(image, centerX, centerY - 12 + bobbing, facingLeft);
    _drawCap(image, centerX, centerY - 18 + bobbing, facingLeft);
  }

  void _drawIdleFrame(img.Image image, int offsetX, int offsetY, int frame) {
    final centerX = offsetX + frameWidth ~/ 2;
    final centerY = offsetY + frameHeight ~/ 2;

    // Subtle breathing animation
    final breathing = (frame % 2 == 0) ? 0 : 1;

    _drawLegs(image, centerX, centerY + 15, 0, false);
    _drawBody(image, centerX, centerY + breathing, false);
    _drawArms(image, centerX, centerY + 2 + breathing, 0, false);
    _drawHead(image, centerX, centerY - 12 + breathing, false);
    _drawCap(image, centerX, centerY - 18 + breathing, false);
  }

  void _drawHead(img.Image image, int x, int y, bool facingLeft) {
    // Head (oval)
    _fillRect(image, x - 5, y - 4, 10, 8, skinColor);

    // Beard
    if (facingLeft) {
      _fillRect(image, x - 5, y + 2, 4, 3, beardColor);
    } else {
      _fillRect(image, x + 1, y + 2, 4, 3, beardColor);
    }

    // Eye
    if (facingLeft) {
      _setPixel(image, x - 2, y - 1, 0xFF000000);
    } else {
      _setPixel(image, x + 2, y - 1, 0xFF000000);
    }
  }

  void _drawCap(img.Image image, int x, int y, bool facingLeft) {
    // Cap
    _fillRect(image, x - 6, y - 4, 12, 5, capColor);

    // Cap brim
    if (facingLeft) {
      _fillRect(image, x - 7, y + 1, 5, 2, capColor);
    } else {
      _fillRect(image, x + 2, y + 1, 5, 2, capColor);
    }
  }

  void _drawBody(img.Image image, int x, int y, bool facingLeft) {
    // Torso (jacket)
    _fillRect(image, x - 6, y - 2, 12, 12, jacketColor);

    // Jacket collar
    _fillRect(image, x - 3, y - 2, 6, 2, jacketColor + 0x00202020);
  }

  void _drawArms(img.Image image, int x, int y, int swing, bool facingLeft) {
    // Arms
    if (facingLeft) {
      // Back arm
      _fillRect(image, x + 3, y + swing, 3, 8, jacketColor - 0x00202020);
      // Front arm
      _fillRect(image, x - 6, y - swing, 3, 8, jacketColor);
      // Hand
      _fillRect(image, x - 6, y - swing + 7, 3, 2, skinColor);
    } else {
      // Back arm
      _fillRect(image, x - 6, y + swing, 3, 8, jacketColor - 0x00202020);
      // Front arm
      _fillRect(image, x + 3, y - swing, 3, 8, jacketColor);
      // Hand
      _fillRect(image, x + 3, y - swing + 7, 3, 2, skinColor);
    }
  }

  void _drawLegs(img.Image image, int x, int y, int offset, bool facingLeft) {
    // Legs (pants)
    if (facingLeft) {
      _fillRect(image, x - 5 + offset, y, 4, 10, pantsColor);
      _fillRect(image, x + 1 - offset, y, 4, 10, pantsColor);
    } else {
      _fillRect(image, x - 5 - offset, y, 4, 10, pantsColor);
      _fillRect(image, x + 1 + offset, y, 4, 10, pantsColor);
    }

    // Shoes
    if (facingLeft) {
      _fillRect(image, x - 6 + offset, y + 9, 5, 3, shoesColor);
      _fillRect(image, x - offset, y + 9, 5, 3, shoesColor);
    } else {
      _fillRect(image, x - 6 - offset, y + 9, 5, 3, shoesColor);
      _fillRect(image, x + offset, y + 9, 5, 3, shoesColor);
    }
  }

  void _fillRect(
      img.Image image, int x, int y, int width, int height, int color,) {
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        _setPixel(image, x + dx, y + dy, color);
      }
    }
  }

  void _setPixel(img.Image image, int x, int y, int color) {
    if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
      image.setPixelRgba(
          x,
          y,
          (color >> 16) & 0xFF, // R
          (color >> 8) & 0xFF, // G
          color & 0xFF, // B
          (color >> 24) & 0xFF, // A
          );
    }
  }
}
