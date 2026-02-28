import 'package:flutter/material.dart';
import 'package:vodkania_game/game/vodkania_game.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/state/overlays.dart';
import 'package:vodkania_game/game/config/game_config.dart';

class MapSelectionOverlay extends StatelessWidget {
  final VodkaniaGame game;

  const MapSelectionOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Map',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildMapOption(
              context,
              title: 'Large Map (Procedural)',
              description: '60x60 tiles. Classic Wodkania experience.',
              onTap: () => _selectMap('map.tmx', true, 3840, 3840),
            ),
            const SizedBox(height: 16),
            _buildMapOption(
              context,
              title: 'Small Map (Procedural)',
              description: '30x30 tiles. Faster action, smaller footprint.',
              onTap: () => _selectMap('map_small.tmx', true, 1920, 1920),
            ),
            const SizedBox(height: 16),
            _buildMapOption(
              context,
              title: 'Photo Map (Custom Image)',
              description: 'Custom background from image.',
              onTap: () => _selectMap('city/mapwodk.jpg', false, 3840, 3840), // Assuming roughly same size or we can adjust
            ),
            const SizedBox(height: 16),
            _buildMapOption(
              context,
              title: 'Real City (Tiled)',
              description: 'Custom map made in Tiled using city assets.',
              onTap: () => _selectMap('real_city.tmx', true, 3840, 3840),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapOption(BuildContext context, {required String title, required String description, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _selectMap(String mapPath, bool isTiled, double width, double height) {
    GameState.instance.selectedMap = mapPath;
    GameState.instance.isTiledMap = isTiled;
    GameConfig.worldWidth = width;
    GameConfig.worldHeight = height;
    
    game.overlays.remove(GameOverlays.mapSelection);
    game.startLevel();
  }
}
