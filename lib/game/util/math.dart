import 'dart:math' as math;

/// Math utilities for game calculations
class MathUtils {
  static final math.Random random = math.Random();

  /// Clamp a value between min and max
  static double clamp(double value, double min, double max) {
    return value < min ? min : (value > max ? max : value);
  }

  /// Linear interpolation
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Distance between two points
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Random double between min and max
  static double randomRange(double min, double max) {
    return min + random.nextDouble() * (max - min);
  }

  /// Random int between min (inclusive) and max (exclusive)
  static int randomInt(int min, int max) {
    return min + random.nextInt(max - min);
  }

  /// Random int between min (inclusive) and max (inclusive)
  static int randomRangeInt(int min, int max) {
    return min + (random.nextDouble() * (max - min + 1)).floor();
  }

  /// Random position within bounds
  static (double, double) randomPosition(
    double minX,
    double maxX,
    double minY,
    double maxY,
  ) {
    return (randomRange(minX, maxX), randomRange(minY, maxY));
  }

  /// Normalize angle to [-PI, PI]
  static double normalizeAngle(double angle) {
    while (angle > math.pi) {
      angle -= 2 * math.pi;
    }
    while (angle < -math.pi) {
      angle += 2 * math.pi;
    }
    return angle;
  }
}
