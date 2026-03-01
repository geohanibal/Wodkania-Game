import 'dart:ui';
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6 * 255),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 600;
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isSmall ? 340 : 500,
                  padding: EdgeInsets.all(isSmall ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5 * 255),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (winner?.playerColor ?? Colors.cyanAccent).withValues(alpha: 0.1 * 255),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    winner != null 
                      ? (winner.playerName == 'You' ? 'VICTORY' : 'DEFEAT') 
                      : 'GAME OVER',
                    style: TextStyle(
                      color: winner?.playerName == 'You' ? Colors.cyanAccent : Colors.redAccent,
                      fontSize: isSmall ? 42 : 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (winner != null && winner.playerName != 'You')
                    Text(
                      '${winner.playerName} won this round',
                      style: TextStyle(color: Colors.white54, fontSize: isSmall ? 14 : 16),
                    ),
                  SizedBox(height: isSmall ? 16 : 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       _buildStatChip(GameState.instance.currentStageName, Colors.cyanAccent, isSmall),
                       const SizedBox(width: 12),
                       _buildStatChip('Level ${GameState.instance.currentLevel}', Colors.white70, isSmall),
                    ],
                  ),
                  
                  SizedBox(height: isSmall ? 20 : 32),
                  const Divider(color: Colors.white12, height: 1),
                  SizedBox(height: isSmall ? 16 : 24),
                  
                  const Text(
                    'RANKINGS',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  SizedBox(height: isSmall ? 12 : 16),

                  if (game != null) 
                    ...((List<PlayerComponent>.from(game!.allPlayers)..sort((a, b) => b.npcCount.compareTo(a.npcCount))).map((p) {
                      final isLocal = p.playerName == 'You';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 8 : 12),
                        decoration: BoxDecoration(
                          color: isLocal ? Colors.white.withValues(alpha: 0.05 * 255) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: p.playerColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                p.playerName,
                                style: TextStyle(
                                  color: isLocal ? Colors.white : Colors.white60,
                                  fontSize: isSmall ? 14 : 18,
                                  fontWeight: isLocal ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${p.npcCount}',
                              style: TextStyle(
                                color: isLocal ? Colors.cyanAccent : Colors.white,
                                fontSize: isSmall ? 16 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    })),

                  SizedBox(height: isSmall ? 24 : 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PremiumButton(
                        label: winner?.playerName == 'You' ? 'NEXT LEVEL' : 'TRY AGAIN',
                        color: Colors.greenAccent,
                        isSmall: isSmall,
                        onPressed: () {
                          if (winner?.playerName == 'You') {
                            GameState.instance.levelUp();
                          } else {
                            GameState.instance.currentLevel = 1;
                          }
                          game!.playAgain();
                        },
                      ),
                      SizedBox(width: isSmall ? 12 : 20),
                      _PremiumButton(
                        label: 'MAIN MENU',
                        color: Colors.blueAccent,
                        isSmall: isSmall,
                        onPressed: onRestart,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
   ),
  );
}

  Widget _buildStatChip(String label, Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1 * 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3 * 255)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: isSmall ? 10 : 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  const _PremiumButton({required this.label, required this.color, required this.onPressed, this.isSmall = false});
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 * 255),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32, vertical: isSmall ? 12 : 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.5 * 255), width: 1.5),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: isSmall ? 12 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
