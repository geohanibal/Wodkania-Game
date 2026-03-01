import 'dart:ui';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = MediaQuery.of(context).size.height < 600;
                return StreamBuilder<void>(
                  stream: Stream.periodic(const Duration(milliseconds: 100)),
                  builder: (context, snapshot) {
                    final runState = GameState.instance.currentRun;
                    if (runState == null) return const SizedBox.shrink();

                    // Clone and sort the list of players by score descending
                    final players = List.of(game!.allPlayers)
                      ..sort((a, b) => b.npcCount.compareTo(a.npcCount));

                    final totalNpcs = runState.totalNpcs;
                    final remainingNpcs = runState.remainingNpcs;
                    final collectedNpcs = totalNpcs - remainingNpcs;
                    final progress = totalNpcs > 0 ? collectedNpcs / totalNpcs : 0.0;

                    return Container(
                      width: isSmall ? 90 : 120, // Halve width
                      padding: EdgeInsets.all(isSmall ? 6 : 10), // Halve padding
                      color: Colors.transparent, // Completely transparent
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    GameState.instance.currentStageName.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: isSmall ? 4 : 5, // Halved
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'LEVEL ${GameState.instance.currentLevel}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 7 : 9, // Halved
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.leaderboard_rounded, color: Colors.white70, size: isSmall ? 10 : 12), // Halved
                            ],
                          ),
                          SizedBox(height: isSmall ? 4 : 8),
                          
                          // Collection Progress
                          Text(
                             'COLLECTION PROGRESS',
                             style: TextStyle(color: Colors.white54, fontSize: isSmall ? 4 : 5, fontWeight: FontWeight.bold), // Halved
                          ),
                          const SizedBox(height: 3),
                          Stack(
                            children: [
                              Container(
                                height: 4, // Halved
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 4, // Halved
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.cyanAccent, Colors.blueAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withValues(alpha: 0.4 * 255),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$collectedNpcs / $totalNpcs',
                              style: TextStyle(color: Colors.white70, fontSize: isSmall ? 4 : 5, fontWeight: FontWeight.bold), // Halved
                            ),
                          ),

                          SizedBox(height: isSmall ? 6 : 10),
                          const Divider(color: Colors.white12, height: 1),
                          SizedBox(height: isSmall ? 4 : 6),

                          // Player List
                          ...players.map((p) {
                            final isLocalPlayer = p.playerName == 'You';
                            return Padding(
                              padding: EdgeInsets.only(bottom: isSmall ? 3 : 5),
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmall ? 9 : 12, // Halved
                                    height: isSmall ? 9 : 12, // Halved
                                    decoration: BoxDecoration(
                                      color: p.playerColor.withValues(alpha: 0.2 * 255),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: p.playerColor, width: 1.5),
                                    ),
                                    child: Icon(
                                      isLocalPlayer ? Icons.person : Icons.android,
                                      size: isSmall ? 5 : 7, // Halved
                                      color: p.playerColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5), // Halved
                                  Expanded(
                                    child: Text(
                                      p.playerName,
                                      style: TextStyle(
                                        color: isLocalPlayer ? Colors.white : Colors.white70,
                                        fontSize: isSmall ? 6 : 7, // Halved
                                        fontWeight: isLocalPlayer ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${p.npcCount}',
                                    style: TextStyle(
                                      color: isLocalPlayer ? Colors.cyanAccent : Colors.white,
                                      fontSize: isSmall ? 7 : 8, // Halved
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }
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
