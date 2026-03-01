import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/state/overlays.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

class MainMenuOverlay extends StatelessWidget {
  const MainMenuOverlay({required this.game, super.key});
  final VodkaniaGame game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.4 * 255)),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 600;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'WODKANIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 48 : 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: isSmall ? 4 : 8,
                        shadows: const [
                          Shadow(color: Colors.cyanAccent, blurRadius: 20),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 30 : 60),

                    // Play Button
                    _MenuButton(
                      label: 'PLAY NOW',
                      icon: Icons.play_arrow_rounded,
                      color: Colors.cyanAccent,
                      isSmall: isSmall,
                      onPressed: () {
                        game.overlays.remove(GameOverlays.mainMenu);
                        game.startLevel();
                      },
                    ),
                    SizedBox(height: isSmall ? 12 : 20),

                    // Select Level Button
                    _MenuButton(
                      label: 'SELECT LEVEL',
                      icon: Icons.grid_view_rounded,
                      color: Colors.white,
                      isSmall: isSmall,
                      onPressed: () {
                        game.overlays.add(GameOverlays.mapSelection);
                      },
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSmall = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSmall;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 220 : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2 * 255),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05 * 255),
          foregroundColor: color,
          padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.4 * 255), width: 1.5),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmall ? 20 : 24),
            SizedBox(width: isSmall ? 8 : 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 14 : 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
