import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/entities/npc/npc_component.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/state/overlays.dart';
import 'package:vodkania_game/game/systems/collision_system.dart';
import 'package:vodkania_game/game/world/camera_setup.dart';
import 'package:vodkania_game/game/world/world_builder.dart';

/// Main game class for Vodkania Competitive
class VodkaniaGame extends FlameGame with HasCollisionDetection {
  void restart() {
    restartGame();
  }

  // Competitor setup
  late PlayerComponent player;
  List<PlayerComponent> allPlayers = [];
  List<NpcComponent> allNpcs = [];
  
  late CollisionSystem collisionSystem;

  @override
  Color backgroundColor() => const Color(0xFF1B5E20);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    overlays.add(GameOverlays.mapSelection);
  }

  Future<void> startLevel() async {
    GameState.instance.startNewRun();
    world.removeAll(world.children);

    final worldBackground = WorldBuilder.createWorld();
    await world.add(worldBackground);

    final boundaries = WorldBuilder.createBoundaries();
    for (final boundary in boundaries) {
      await world.add(boundary);
    }

    allPlayers.clear();
    allNpcs.clear();

    // 1. Setup Human Player
    player = PlayerComponent(
      position: Vector2(GameConfig.worldWidth / 2, GameConfig.worldHeight * 0.8),
      playerName: 'You',
    );
    allPlayers.add(player);
    await world.add(player);

    // 2. Setup AI Players
    final aiColors = [
      const Color(0xFFE74C3C), // Red
      const Color(0xFFF1C40F), // Yellow
      const Color(0xFF9B59B6), // Purple
      const Color(0xFFE67E22), // Orange
    ];
    final archetypes = [
      AiArchetype.collector,
      AiArchetype.aggressive,
      AiArchetype.opportunist,
      AiArchetype.aggressive,
    ];
    final random = math.Random();
    for (var i = 0; i < 4; i++) {
        final aiPlayer = PlayerComponent(
          position: Vector2(
            random.nextDouble() * GameConfig.worldWidth * 0.8 + GameConfig.worldWidth * 0.1,
            random.nextDouble() * GameConfig.worldHeight * 0.8 + GameConfig.worldHeight * 0.1,
          ),
          isAI: true,
          playerName: 'AI ${i + 1}',
          playerColor: aiColors[i],
          aiArchetype: archetypes[i],
        );
        allPlayers.add(aiPlayer);
        await world.add(aiPlayer);
    }

    // 3. Setup Camera on Human Player
    camera = CameraSetup.setupCamera(this, player);
    add(camera);

    // 4. Spawn NPCs
    const totalNpcsToSpawn = 100;
    var totalPoints = 0;

    for (var i = 0; i < totalNpcsToSpawn; i++) {
      final rand = random.nextDouble();
      var tier = NpcTier.normal;
      var points = 1;

      if (rand > 0.95) {
        tier = NpcTier.legendary;
        points = 5;
      } else if (rand > 0.8) {
        tier = NpcTier.rare;
        points = 3;
      }
      
      totalPoints += points;

      final npc = NpcComponent(
        tier: tier,
        // Distribute randomly across playable space
        position: Vector2(
          random.nextDouble() * GameConfig.worldWidth * 0.8 + GameConfig.worldWidth * 0.1,
          random.nextDouble() * GameConfig.worldHeight * 0.8 + GameConfig.worldHeight * 0.1,
        ),
      );
      allNpcs.add(npc);
      await world.add(npc);
    }

    GameState.instance.currentRun!.totalNpcs = totalPoints;
    GameState.instance.currentRun!.remainingNpcs = totalPoints;

    // 5. Initialize Collision System
    collisionSystem = CollisionSystem(players: allPlayers, npcs: allNpcs);
    await world.add(collisionSystem);

    overlays.add(GameOverlays.hud);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final runState = GameState.instance.currentRun;
    if (runState != null && !runState.isGameOver) {
      // Math-based Early Win Condition Logic
      if (allPlayers.isNotEmpty) {
        // Sort players descending by score
        final sortedPlayers = List<PlayerComponent>.from(allPlayers)
          ..sort((a, b) => b.npcCount.compareTo(a.npcCount));
        
        final leaderScore = sortedPlayers[0].npcCount;
        final secondScore = sortedPlayers.length > 1 ? sortedPlayers[1].npcCount : 0;
        final remainingNpcs = runState.remainingNpcs;

        // Condition 1: All NPCs collected
        // Condition 2: Leader mathematically cannot be passed
        if (remainingNpcs == 0 || leaderScore > secondScore + remainingNpcs) {
          runState.isGameOver = true;
          // You can also capture the winner explicitly here, or the UI could just read sortedPlayers[0].
          
          pauseEngine();
          // Show Game Over Overlay immediately
          overlays.add(GameOverlays.gameOver);
        }
      }
    }
  }

  void movePlayer(Vector2 direction) {
    if (GameState.instance.currentRun != null && !GameState.instance.currentRun!.isGameOver) {
      player.setMovementDirection(direction);
    }
  }

  void stopPlayer() {
    if (GameState.instance.currentRun != null && !GameState.instance.currentRun!.isGameOver) {
      player.setMovementDirection(Vector2.zero());
    }
  }

  void restartGame() {
    overlays.remove(GameOverlays.gameOver);
    overlays.remove(GameOverlays.pause);
    overlays.remove(GameOverlays.hud);

    GameState.instance.endRun();
    resumeEngine();
    overlays.add(GameOverlays.mapSelection);
  }

  void playAgain() {
    overlays.remove(GameOverlays.gameOver);
    overlays.remove(GameOverlays.pause);
    overlays.remove(GameOverlays.hud);

    GameState.instance.endRun();
    resumeEngine();
    startLevel();
  }
}
