import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/util/math.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/entities/effects/floating_text_component.dart';
import 'package:vodkania_game/game/entities/npc/npc_component.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/state/game_state.dart';

/// System for handling competitive player and NPC collections
class CollisionSystem extends Component {
  CollisionSystem({required this.players, required this.npcs});

  final List<PlayerComponent> players;
  final List<NpcComponent> npcs;

  @override
  void update(double dt) {
    super.update(dt);
    _checkPlayerNpcCollisions();
    _checkPlayerCollisions();
  }

  void _checkPlayerCollisions() {
    // ამოწმებს მოთამაშეების ერთმანეთთან შეჯახებას (Stealing System)
    // Checks for player-to-player collisions to perform steals
    for (var i = 0; i < players.length; i++) {
      for (var j = i + 1; j < players.length; j++) {
        final p1 = players[i];
        final p2 = players[j];

        if (p1.stealCooldown > 0 || p2.stealCooldown > 0) continue;

        // Player to player collision
        final distanceSquared = p1.position.distanceToSquared(p2.position);
        final threshold = Tuning.playerRadius * 2;
        if (distanceSquared <= threshold * threshold) {
          if (p1.followers.length > p2.followers.length) {
            _stealNpcs(thief: p1, victim: p2);
          } else if (p2.followers.length > p1.followers.length) {
            _stealNpcs(thief: p2, victim: p1);
          }
        }
      }
    }
  }

  /// ასრულებს მოპარვის ლოგიკას: ძლიერი მოთამაშე ართმევს სუსტს მიმდევრებს.
  /// Executes the stealing logic: stronger player takes 1-3 followers from the weaker.
  void _stealNpcs({
    required PlayerComponent thief,
    required PlayerComponent victim,
  }) {
    if (victim.followers.isEmpty) return;

    // Steal 1 to 3 NPCs depending on victim's size, maxed at what they have
    var amountToSteal = (victim.followers.length * 0.2).ceil().clamp(1, 3);
    amountToSteal = amountToSteal.clamp(0, victim.followers.length);

    if (amountToSteal == 0) return;

    for (var i = 0; i < amountToSteal; i++) {
      final stolenNpc = victim.followers.removeLast();
      victim.npcCount -= stolenNpc.pointValue;

      // Add to thief
      stolenNpc.leader = thief;
      stolenNpc.shirtColor = thief.playerColor;

      if (thief.followers.isEmpty) {
        stolenNpc.targetFollow = thief;
      } else {
        stolenNpc.targetFollow = thief.followers.last;
      }

      thief.followers.add(stolenNpc);
      thief.npcCount += stolenNpc.pointValue;
    }

    // Apply invulnerability cooldown to prevent rapid bouncing
    thief.stealCooldown = 2.0;
    victim.stealCooldown = 3.0; // Victim gets slightly longer invulnerability

    // Floating text feedback (Thief +X, Victim -X)
    thief.parent?.add(
      FloatingTextComponent(
        position: thief.position.clone()..y -= 20,
        text: '+$amountToSteal',
        color: Colors.greenAccent,
      ),
    );
    victim.parent?.add(
      FloatingTextComponent(
        position: victim.position.clone()..y -= 20,
        text: '-$amountToSteal',
        color: Colors.redAccent,
      ),
    );

    // Particle Feedback for steal
    thief.parent?.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 15,
          lifespan: 0.6,
          generator: (i) {
            return AcceleratedParticle(
              position: victim.position.clone(),
              speed: Vector2(MathUtils.randomRange(-80, 80), MathUtils.randomRange(-80, 80)),
              child: CircleParticle(
                radius: 2,
                paint: Paint()..color = Colors.redAccent,
              ),
            );
          },
        ),
      ),
    );
  }

  void _checkPlayerNpcCollisions() {
    for (final player in players) {
      for (final npc in npcs) {
        if (npc.state == NpcState.follower) continue;

        // Use a slightly larger collection radius for gameplay feel
        final distanceSquared = player.position.distanceToSquared(npc.position);
        final threshold = Tuning.playerCollectionRadius + 10;
        if (distanceSquared <= threshold * threshold) {
          _recruitNpc(player, npc);
        }
      }
    }
  }

  void _recruitNpc(PlayerComponent capturingPlayer, NpcComponent npc) {
    npc.state = NpcState.follower;
    npc.leader = capturingPlayer;
    npc.shirtColor =
        capturingPlayer.playerColor; // visual feedback of team color

    // The target to follow is either the player or the tail of the current followers
    if (capturingPlayer.followers.isEmpty) {
      npc.targetFollow = capturingPlayer;
    } else {
      npc.targetFollow = capturingPlayer.followers.last;
    }

    capturingPlayer.followers.add(npc);
    capturingPlayer.npcCount += npc.pointValue;

    final runState = GameState.instance.currentRun;
    if (runState != null) {
      // Treat remainingNpcs as remaining points so early win condition is accurate
      runState.remainingNpcs -= npc.pointValue;
    }

    // Generate Floating text effect (+1)
    capturingPlayer.parent?.add(
      FloatingTextComponent(
        position: capturingPlayer.position.clone()..y -= 20,
        text: '+${npc.pointValue}',
        color: Colors.greenAccent,
      ),
    );

    // Particle Burst Feedback
    capturingPlayer.parent?.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 8,
          lifespan: 0.4,
          generator: (i) {
            return AcceleratedParticle(
              position: capturingPlayer.position.clone(),
              speed: Vector2(MathUtils.randomRange(-50, 50), MathUtils.randomRange(-50, 50)),
              child: CircleParticle(
                radius: 1.5,
                paint: Paint()..color = Colors.cyanAccent,
              ),
            );
          },
        ),
      ),
    );
  }
}
