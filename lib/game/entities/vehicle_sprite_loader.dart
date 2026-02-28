import 'package:flame/components.dart';

/// Enum for vehicle directions
enum VehicleDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest
}

/// Helper to convert direction enum to suffix
String directionToSuffix(VehicleDirection dir) {
  switch (dir) {
    case VehicleDirection.north:
      return 'N';
    case VehicleDirection.northEast:
      return 'NE';
    case VehicleDirection.east:
      return 'E';
    case VehicleDirection.southEast:
      return 'SE';
    case VehicleDirection.south:
      return 'S';
    case VehicleDirection.southWest:
      return 'SW';
    case VehicleDirection.west:
      return 'W';
    case VehicleDirection.northWest:
      return 'NW';
  }
}

/// Loads a vehicle sprite by type and direction
Future<Sprite> loadVehicleSprite({
  required String vehicleType, // e.g. 'Ambulance', 'Civilian/Blue/Sedan 1'
  required String baseName, // e.g. 'ambulance', 'carBlue2'
  required VehicleDirection direction,
}) async {
  final suffix = directionToSuffix(direction);
  final path =
      'vehicles/PNG/$vehicleType/${baseName}_$suffix.png';
  return Sprite.load(path);
}

/// Usage example:
/// final sprite = await loadVehicleSprite(
///   vehicleType: 'Ambulance',
///   baseName: 'ambulance',
///   direction: VehicleDirection.northEast,
/// );
