import 'package:flutter/material.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

/// Game over overlay
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({required this.onRestart, this.game, super.key});

  final VoidCallback onRestart;
  final VodkaniaGame? game;

  @override
  Widget build(BuildContext context) {
    final runState = GameState.instance.currentRun;
    
    // Determine winner
    PlayerComponent? winner;
    if (game != null && game!.allPlayers.isNotEmpty) {
      final sortedPlayers = List<PlayerComponent>.from(game!.allPlayers)
        ..sort((a, b) => b.npcCount.compareTo(a.npcCount));
      winner = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    }

    return ColoredBox(
      color: Colors.black.withValues(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.8 * 255,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              winner != null 
                ? (winner.playerName == 'You' ? 'YOU WON!' : 'YOU LOST!\n${winner.playerName} Won') 
                : 'GAME OVER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: winner?.playerColor ?? Colors.red,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(blurRadius: 8, offset: Offset(2, 2)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Final Results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            if (game != null) ...[
              ColoredBox(
                color: Colors.white.withValues(
                  red: 255,
                  green: 255,
                  blue: 255,
                  alpha: 0.1 * 255,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Sort players one last time
                        ...((List<PlayerComponent>.from(game!.allPlayers)..sort((a, b) => b.npcCount.compareTo(a.npcCount))).map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: p.playerColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    p.playerName,
                                    style: TextStyle(
                                      color: p.playerName == 'You' ? Colors.cyanAccent : Colors.white,
                                      fontSize: 24,
                                      fontWeight: p.playerName == 'You' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '${p.npcCount}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      game!.playAgain();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Play Again', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: onRestart, // maps to restartGame() -> Main Menu
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Main Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
