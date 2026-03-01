import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/entities/npc/npc_component.dart';
import 'package:vodkania_game/game/state/game_state.dart';
import 'package:vodkania_game/game/vodkania_map.dart';

enum AiArchetype { collector, aggressive, opportunist }

/// Simplified Player game component drawn mathematically
class PlayerComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  PlayerComponent({
    required Vector2 position,
    this.isAI = false,
    this.playerName = 'Player',
    this.playerColor = const Color(0xFF3498DB),
    this.aiArchetype,
  }) : super(
         position: position,
         size: Vector2.all(Tuning.playerRadius * 2),
         anchor: Anchor.center,
       ) {
    if (isAI && aiArchetype == null) {
      aiArchetype = AiArchetype.collector;
    }
  }
  bool isAI;
  String playerName;
  Color playerColor;
  AiArchetype? aiArchetype;
  int npcCount = 0;
  List<NpcComponent> followers = [];
  double stealCooldown = 0;

  String orientation = 'idle';
  double _lastAngle = 0;
  Vector2 _lastValidPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  // AI Wandering fallback properties
  double _aiWanderTimer = 0;
  Vector2 _aiWanderTarget = Vector2.zero();
  double _aiDecisionTimer = 0;

  // Static shared paints for performance
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.4 * 255)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  
  static final Paint _auraBasePaint = Paint()
    ..color = Colors.cyanAccent.withValues(alpha: 0.4 * 255)
    ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  static final Paint _skinPaint = Paint()..color = const Color(0xFFFFCC99); // Skin tone
  static final Paint _pantsPaint = Paint()..color = const Color(0xFF2E4053); // Dark slate blue pants
  static final Paint _shoesPaint = Paint()..color = const Color(0xFF17202A); // Black/dark shoes
  static final Paint _hairPaint = Paint()..color = const Color(0xFF5D4037);

  // Instance specific mutable paints
  final Paint _shirtPaint = Paint();
  final Paint _outlinePaint = Paint()..style = PaintingStyle.stroke;

  @override
  void onMount() {
    super.onMount();
    _lastValidPosition = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(CircleHitbox()..collisionType = CollisionType.active);
    priority = 100;

    debugPrint('Player loaded. Size: $size. Canvas Draw mode active.');
  }

  // Call this to set movement direction
  void setMovementDirection(Vector2 newDirection) {
    double speed;
    final level = GameState.instance.currentLevel;
    if (isAI) {
      speed = 60.0 + ((level - 1) * 3.0);
    } else {
      speed = 100.0 + ((level - 1) * 2.0);
    }

    velocity = newDirection * speed;
    if (velocity.x < 0) {
      orientation = 'left';
    } else if (velocity.x > 0) {
      orientation = 'right';
    } else if (velocity.y < 0) {
      orientation = 'up';
    } else if (velocity.y > 0) {
      orientation = 'down';
    } else {
      orientation = 'idle';
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is TiledWall) {
      if (intersectionPoints.length >= 2) {
        final midX = (intersectionPoints.first.x + intersectionPoints.last.x) / 2;
        final midY = (intersectionPoints.first.y + intersectionPoints.last.y) / 2;
        
        var normal = (position - Vector2(midX, midY)).normalized();
        // Snap to closest axis for clean sliding against AABB walls
        if (normal.x.abs() > normal.y.abs()) {
          normal = Vector2(normal.x.sign, 0);
        } else {
          normal = Vector2(0, normal.y.sign);
        }

        // Push out of collision proportional to movement speed to smooth out jitter
        position.add(normal * (velocity.length * 0.016 + 1.0));
      } else {
        revertToLastPosition();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastValidPosition = position.clone();

    if (isAI) {
      _aiDecisionTimer -= dt;
      if (_aiDecisionTimer <= 0) {
        _aiUpdate(dt);
        _aiDecisionTimer = 0.2 + (math.Random().nextDouble() * 0.1);
      }
    }

    if (stealCooldown > 0) {
      stealCooldown -= dt;
    }

    if (velocity.length > 0) {
      position.add(velocity * dt);

      // Keep inside World Bounds
      position.x = position.x.clamp(
        Tuning.playerRadius,
        GameConfig.worldWidth - Tuning.playerRadius,
      );
      position.y = position.y.clamp(
        Tuning.playerRadius,
        GameConfig.worldHeight - Tuning.playerRadius,
      );
    }
  }

  void _aiUpdate(double dt) {
    if (aiArchetype == AiArchetype.opportunist) {
      _aiUpdateOpportunist(dt);
    } else if (aiArchetype == AiArchetype.aggressive) {
      _aiUpdateAggressive(dt);
    } else {
      _aiUpdateCollector(dt);
    }
  }

  void _aiUpdateCollector(double dt) {
    // [EN] Collector: Finds nearest free NPC regardless of tier
    // [GE] კოლექტორი: ეძებს ყველაზე ახლო თავისუფალ ნებისმიერ NPC-ს.
    final allNpcs = parent?.children.whereType<NpcComponent>().toList() ?? [];

    NpcComponent? nearestFreeNpc;
    var minDistance = double.infinity;

    for (final npc in allNpcs) {
      if (npc.state == NpcState.free) {
        final dist = (npc.position - position).length;
        if (dist < minDistance) {
          minDistance = dist;
          nearestFreeNpc = npc;
        }
      }
    }

    if (nearestFreeNpc != null) {
      // Move towards the nearest NPC
      final diff = nearestFreeNpc.position - position;
      setMovementDirection(diff.normalized());
    } else {
      _wanderFallback(dt);
    }
  }

  void _aiUpdateAggressive(double dt) {
    // [EN] Aggressive: Hunts players with fewer followers to steal them.
    // [GE] აგრესიული: დასდევს და უტევს მოთამაშეებს, რომლებსაც მასზე ცოტა NPC ყავთ მოსაპარად.
    final players =
        parent?.children.whereType<PlayerComponent>().toList() ?? [];
    PlayerComponent? targetPlayer;
    var minPlayerDist = double.infinity;

    for (final p in players) {
      if (p == this) continue;
      // Only target if we have more followers
      if (followers.length > p.followers.length) {
        final dist = (p.position - position).length;
        if (dist < minPlayerDist) {
          minPlayerDist = dist;
          targetPlayer = p;
        }
      }
    }

    if (targetPlayer != null &&
        minPlayerDist < Tuning.playerCollectionRadius + 300) {
      setMovementDirection((targetPlayer.position - position).normalized());
      return;
    }

    // Fallback if no targets to steal from -> Behave like a collector
    _aiUpdateCollector(dt);
  }

  void _aiUpdateOpportunist(double dt) {
    // [EN] Opportunist: Targets only Rare and Legendary NPCs (high value).
    // [GE] ოპორტუნისტი: დასდევს და აგროვებს მხოლოდ Rare და Legendary მაღალქულიან NPC-ებს მთელ რუკაზე.
    final allNpcs = parent?.children.whereType<NpcComponent>().toList() ?? [];
    NpcComponent? targetNpc;
    var minDistance = double.infinity;

    for (final npc in allNpcs) {
      if (npc.state == NpcState.free &&
          (npc.tier == NpcTier.rare || npc.tier == NpcTier.legendary)) {
        final dist = (npc.position - position).length;
        if (dist < minDistance) {
          minDistance = dist;
          targetNpc = npc;
        }
      }
    }

    if (targetNpc != null) {
      setMovementDirection((targetNpc.position - position).normalized());
    } else {
      // If no shiny things found, just wander blindly
      _wanderFallback(dt);
    }
  }

  void _wanderFallback(double dt) {
    _aiWanderTimer -= dt;
    if (_aiWanderTimer <= 0 || (position - _aiWanderTarget).length < 10) {
      final angle = math.Random().nextDouble() * 6.28;
      final dist = math.Random().nextDouble() * 300 + 100;
      _aiWanderTarget =
          position + (Vector2(math.cos(angle), math.sin(angle)) * dist);
      _aiWanderTarget.x = _aiWanderTarget.x.clamp(
        Tuning.playerRadius,
        GameConfig.worldWidth - Tuning.playerRadius,
      );
      _aiWanderTarget.y = _aiWanderTarget.y.clamp(
        Tuning.playerRadius,
        GameConfig.worldHeight - Tuning.playerRadius,
      );
      _aiWanderTimer = math.Random().nextDouble() * 2 + 1;
    }
    setMovementDirection((_aiWanderTarget - position).normalized());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Determine custom visual rotation based on velocity vector
    var angle = _lastAngle;
    if (velocity.length > 0) {
      // Calculate exact angle
      final exactAngle = math.atan2(velocity.y, velocity.x) - math.pi / 2;

      // Snap to 8 directions (increments of PI / 4)
      const step = math.pi / 4;
      angle = (exactAngle / step).round() * step;

      _lastAngle = angle;
    }

    // Animate slight walk wobble if moving
    if (velocity.length > 0) {
      // Very simple wobble based on position (pseudo-animation)
      final wobble = (position.x + position.y) % 20 / 20.0;
      angle += (wobble - 0.5) * 0.3; // wobble between -0.15 and 0.15 radians
    }

    // Draw an elliptical shadow beneath the entity's apparent feet
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 10),
        width: radius * 1.8,
        height: radius * 0.8,
      ),
      _shadowPaint,
    );

    // If Human Player, draw a distinct glowing aura underneath the shadow
    if (!isAI) {
      // Slowly animate the aura breathing via time/position tracking
      final pulse =
          1.0 + math.sin(DateTime.now().millisecondsSinceEpoch / 200) * 0.1;
      final adjustedRadius = radius * 1.2 * pulse;

      canvas.drawCircle(Offset.zero, adjustedRadius, _auraBasePaint);
    }

    // Now rotate body
    canvas.rotate(angle);

    // Flash white/transparent occasionally if invulnerable (stealCooldown > 0)
    final isInvulnerableFlash =
        stealCooldown > 0 && (stealCooldown * 10).floor() % 2 == 0;

    _shirtPaint.color = isInvulnerableFlash
          ? Colors.white70
          : playerColor; // Unique player color
    
    _outlinePaint.color = isInvulnerableFlash ? Colors.white : Colors.black87;
    _outlinePaint.strokeWidth = isInvulnerableFlash ? 3.0 : 2.0;

    // Animated Leg Offsets
    double leftLegOffset = 0.0;
    double rightLegOffset = 0.0;
    if (velocity.length > 0) {
      // Create a walk cycle from 0 to 2*PI based on position distance
      final walkCycle = (position.length % 40) / 40.0 * 2 * math.pi;

      // Sine wave for oscillating legs back and forth
      final legSwing = math.sin(walkCycle) * (radius * 0.4);

      leftLegOffset = legSwing;
      rightLegOffset = -legSwing; // Inverse
    }

    // Draw Legs / Feet (drawn below torso)
    final leftFootRect = Rect.fromCenter(
      center: Offset(-radius * 0.4, leftLegOffset - radius * 0.2),
      width: radius * 0.4,
      height: radius * 0.7,
    );
    canvas.drawRect(leftFootRect, _shoesPaint);
    canvas.drawRect(leftFootRect, _outlinePaint);

    final rightFootRect = Rect.fromCenter(
      center: Offset(radius * 0.4, rightLegOffset - radius * 0.2),
      width: radius * 0.4,
      height: radius * 0.7,
    );
    canvas.drawRect(rightFootRect, _shoesPaint);
    canvas.drawRect(rightFootRect, _outlinePaint);

    // Draw Hands (shoulders/arms out front)
    // Left hand
    final leftHandCenter = Offset(-radius * 0.6, radius * 0.4);
    canvas.drawCircle(leftHandCenter, radius * 0.25, _skinPaint);
    canvas.drawCircle(leftHandCenter, radius * 0.25, _outlinePaint);

    // Right hand
    final rightHandCenter = Offset(radius * 0.6, radius * 0.4);
    canvas.drawCircle(rightHandCenter, radius * 0.25, _skinPaint);
    canvas.drawCircle(rightHandCenter, radius * 0.25, _outlinePaint);

    // Draw Shoulders / Torso
    final torsoRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: radius * 1.6,
      height: radius * 0.8,
    );
    final torsoRRect = RRect.fromRectAndRadius(
      torsoRect,
      Radius.circular(radius * 0.4),
    );
    canvas.drawRRect(torsoRRect, _shirtPaint);
    canvas.drawRRect(torsoRRect, _outlinePaint);

    // Draw Head
    final headCenter = Offset(0, radius * 0.1);
    canvas.drawCircle(headCenter, radius * 0.45, _skinPaint);
    canvas.drawCircle(headCenter, radius * 0.45, _outlinePaint);

    // Draw Hair (simple brown cap)
    final hairRect = Rect.fromCenter(
      center: Offset(0, radius * -0.05),
      width: radius * 0.9,
      height: radius * 0.6,
    );
    canvas.drawArc(hairRect, 3.14159, 3.14159, true, _hairPaint);

    canvas.restore();

    // Draw Overhead Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$playerName: $npcCount',
        style: TextStyle(
          color: playerColor,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(blurRadius: 2, color: Colors.white, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Position the text above the player head outside of the rotated canvas
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, -20));
  }

  void revertToLastPosition() {
    position.setFrom(_lastValidPosition);
  }
}
