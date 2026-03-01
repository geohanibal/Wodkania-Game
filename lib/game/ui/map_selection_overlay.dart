import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/state/overlays.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

class MapSelectionOverlay extends StatefulWidget {
  const MapSelectionOverlay({required this.game, super.key});
  final VodkaniaGame game;

  @override
  State<MapSelectionOverlay> createState() => _MapSelectionOverlayState();
}

class _MapSelectionOverlayState extends State<MapSelectionOverlay> {
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _selectedLevel = GameState.instance.currentLevel;
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Overlay background
        GestureDetector(
          onTap: () => widget.game.overlays.remove(GameOverlays.mapSelection),
          child: Container(
            color: Colors.black.withValues(alpha: 0.6 * 255),
          ),
        ),

        // Bottom Sheet Panel
        Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxHeight < 600;
              return TweenAnimationBuilder<Offset>(
                tween: Tween(begin: const Offset(0, 1), end: Offset.zero),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, offset, child) {
                  return FractionalTranslation(
                    translation: offset,
                    child: child,
                  );
                },
                child: Container(
                  height: MediaQuery.of(context).size.height * (isSmall ? 0.85 : 0.7),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white10, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5 * 255),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Indicator
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: isSmall ? 12 : 24),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Level',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: () => widget.game.overlays.remove(GameOverlays.mapSelection),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 8 : 16),

                  // Map Choice (Simplified for mobile)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMapChip('Large Map', 'map.tmx'),
                        const SizedBox(width: 12),
                        _buildMapChip('Small Map', 'map_small.tmx'),
                        const SizedBox(width: 12),
                        _buildMapChip('Real City', 'real_city.tmx'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Level Stages List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        _buildStageSection('Stage 1 - Easy', 1, 6, isSmall),
                        _buildStageSection('Stage 2 - Normal', 7, 14, isSmall),
                        _buildStageSection('Stage 3 - Hard', 15, 22, isSmall),
                        _buildStageSection('Stage 4 - Expert', 23, 30, isSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStageSection(String title, int startLevel, int endLevel, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: isSmall ? 8 : 12, top: isSmall ? 8 : 16),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(endLevel - startLevel + 1, (index) {
              final level = startLevel + index;
              return Padding(
                padding: EdgeInsets.only(right: isSmall ? 8.0 : 12.0),
                child: SizedBox(
                  width: isSmall ? 60 : 80,
                  height: isSmall ? 60 : 80,
                  child: _buildLevelButton(level, isSmall),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMapChip(String label, String path) {
    final isSelected = GameState.instance.selectedMap == path;
    return GestureDetector(
      onTap: () {
        setState(() {
          GameState.instance.selectedMap = path;
          // Set dimensions based on selection
          if (path == 'map_small.tmx') {
            GameConfig.worldWidth = 1920;
            GameConfig.worldHeight = 1920;
          } else {
            GameConfig.worldWidth = 3840;
            GameConfig.worldHeight = 3840;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1 * 255) : Colors.white.withValues(alpha: 0.05 * 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(int level, bool isSmall) {
    final gameState = GameState.instance;
    final isCompleted = gameState.completedLevels.contains(level);
    final isUnlocked = level <= gameState.maxUnlockedLevel;
    final isActive = gameState.currentLevel == level;

    return GestureDetector(
      onTap: isUnlocked ? () => _startLevel(level) : null,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: isActive 
                ? Colors.cyanAccent.withValues(alpha: 0.15 * 255) 
                : Colors.white.withValues(alpha: 0.05 * 255),
            borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
            border: Border.all(
              color: isActive ? Colors.cyanAccent : Colors.white10,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  level.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white24,
                    fontSize: isSmall ? 18 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isUnlocked)
                Positioned(
                  top: isSmall ? 4 : 8,
                  right: isSmall ? 4 : 8,
                  child: Icon(Icons.lock_rounded, size: isSmall ? 12 : 14, color: Colors.white24),
                ),
              if (isCompleted)
                Positioned(
                  bottom: isSmall ? 4 : 8,
                  right: isSmall ? 4 : 8,
                  child: Icon(Icons.star_rounded, size: isSmall ? 14 : 18, color: Colors.amberAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLevel(int level) {
    GameState.instance.currentLevel = level;
    widget.game.overlays.remove(GameOverlays.mapSelection);
    widget.game.overlays.remove(GameOverlays.mainMenu); // Just in case
    widget.game.startLevel();
  }
}
