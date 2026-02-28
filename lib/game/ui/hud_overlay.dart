import 'dart:math';
import 'package:flutter/material.dart';

import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

/// HUD overlay displaying game stats
class HudOverlay extends StatelessWidget {
  const HudOverlay({this.game, super.key});

  final VodkaniaGame? game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Scoreboard Panel (Right Side)
        if (game != null)
          Positioned(
            right: 16,
            top: 70, // Below the return menu button
            child: StreamBuilder<void>(
              stream: Stream.periodic(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                final runState = GameState.instance.currentRun;
                if (runState == null) return const SizedBox.shrink();

                // Clone and sort the list of players by score descending
                final players = List.of(game!.allPlayers)
                  ..sort((a, b) => b.npcCount.compareTo(a.npcCount));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75 * 255),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SCOREBOARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // List all 5 players
                      ...players.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: p.playerColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120, // fixed width for alignment
                                child: Text(
                                  p.playerName,
                                  style: TextStyle(
                                    color: p.playerName == 'You' ? Colors.cyanAccent : Colors.white,
                                    fontSize: 16,
                                    fontWeight: p.playerName == 'You' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30, // Score aligned
                                child: Text(
                                  '${p.npcCount}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: 8),
                      Text(
                        'Remaining ATMs: ${runState.remainingNpcs}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        // Menu / Return Button (Top Right)
        if (game != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5 * 255),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                tooltip: 'Return to Menu',
                onPressed: () {
                  game!.restartGame();
                },
              ),
            ),
          ),
      ],
    );
  }
}

// Removed _InventoryDialog

