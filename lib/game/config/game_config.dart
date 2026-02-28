/// Game configuration constants
class GameConfig {
  // Screen and camera
  static double worldWidth = 3840;
  static double worldHeight = 3840;
  static const double cameraZoom = 1;

  // Performance
  static const int targetFPS = 60;
  static const bool enableDebugMode = false;

  // Game boundaries
  static const int minX = 0;
  static const int minY = 0;
  static double get maxX => worldWidth;
  static double get maxY => worldHeight;
}
