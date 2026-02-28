import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/config/game_config.dart';

import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:vodkania_game/game/entities/npc/npc_component.dart';

/// Simplified Player game component drawn mathematically
class PlayerComponent extends PositionComponent with HasGameReference, CollisionCallbacks {
  bool isAI;
  String playerName;
  Color playerColor;
  int npcCount = 0;
  List<NpcComponent> followers = [];

  PlayerComponent({
    required Vector2 position,
    this.isAI = false,
    this.playerName = 'Player',
    this.playerColor = const Color(0xFF3498DB),
  }) : super(
    position: position,
    size: Vector2.all(Tuning.playerRadius * 2),
    anchor: Anchor.center,
  );

  String orientation = 'idle';
  double _lastAngle = 0.0;
  Vector2 _lastValidPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  
  // AI Wandering fallback properties
  double _aiWanderTimer = 0;
  Vector2 _aiWanderTarget = Vector2.zero();

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
    velocity = newDirection * Tuning.playerSpeed;
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
  void update(double dt) {
    super.update(dt);
    _lastValidPosition = position.clone();
    
    if (isAI) {
      _aiUpdate(dt);
    }
    
    if (velocity.length > 0) {
      position.add(velocity * dt);
      
      // Keep inside World Bounds
      position.x = position.x.clamp(Tuning.playerRadius, (GameConfig.worldWidth - Tuning.playerRadius).toDouble());
      position.y = position.y.clamp(Tuning.playerRadius, (GameConfig.worldHeight - Tuning.playerRadius).toDouble());
    }
  }

  void _aiUpdate(double dt) {
    // Find nearest free NPC
    final allNpcs = parent?.children.whereType<NpcComponent>().toList() ?? [];
    
    NpcComponent? nearestFreeNpc;
    double minDistance = double.infinity;
    
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
      // Fallback wandering
      _aiWanderTimer -= dt;
      if (_aiWanderTimer <= 0 || (position - _aiWanderTarget).length < 10) {
         final angle = math.Random().nextDouble() * 6.28;
         final dist = math.Random().nextDouble() * 300 + 100;
         _aiWanderTarget = position + (Vector2(math.cos(angle), math.sin(angle)) * dist);
         _aiWanderTarget.x = _aiWanderTarget.x.clamp(Tuning.playerRadius, (GameConfig.worldWidth - Tuning.playerRadius).toDouble());
         _aiWanderTarget.y = _aiWanderTarget.y.clamp(Tuning.playerRadius, (GameConfig.worldHeight - Tuning.playerRadius).toDouble());
         _aiWanderTimer = math.Random().nextDouble() * 2 + 1;
      }
      setMovementDirection((_aiWanderTarget - position).normalized());
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Determine custom visual rotation based on velocity vector
    double angle = _lastAngle;
    if (velocity.length > 0) {
      // Calculate exact angle
      double exactAngle = math.atan2(velocity.y, velocity.x) - math.pi / 2;
      
      // Snap to 8 directions (increments of PI / 4)
      final step = math.pi / 4;
      angle = (exactAngle / step).round() * step;
      
      _lastAngle = angle;
    }
    
    // Animate slight walk wobble if moving
    if (velocity.length > 0) {
      // Very simple wobble based on position (pseudo-animation)
      double wobble = (position.x + position.y) % 20 / 20.0; 
      angle += (wobble - 0.5) * 0.3; // wobble between -0.15 and 0.15 radians
    }

    canvas.rotate(angle);

    // Paints
    final skinPaint = Paint()..color = const Color(0xFFFFCC99); // Skin tone
    final shirtPaint = Paint()..color = playerColor; // Unique player color
    final pantsPaint = Paint()..color = const Color(0xFF2E4053); // Dark slate blue pants
    final shoesPaint = Paint()..color = const Color(0xFF17202A); // Black/dark shoes
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Animated Leg Offsets
    double leftLegOffset = 0.0;
    double rightLegOffset = 0.0;
    if (velocity.length > 0) {
      // Create a walk cycle from 0 to 2*PI based on position distance
      double walkCycle = (position.length % 40) / 40.0 * 2 * math.pi;
      
      // Sine wave for oscillating legs back and forth
      double legSwing = math.sin(walkCycle) * (radius * 0.4);
      
      leftLegOffset = legSwing;
      rightLegOffset = -legSwing; // Inverse
    }

    // Draw Legs / Feet (drawn below torso)
    final leftFootRect = Rect.fromCenter(
      center: Offset(-radius * 0.4, leftLegOffset - radius * 0.2), 
      width: radius * 0.4, 
      height: radius * 0.7
    );
    canvas.drawRect(leftFootRect, shoesPaint);
    canvas.drawRect(leftFootRect, outlinePaint);
    
    final rightFootRect = Rect.fromCenter(
      center: Offset(radius * 0.4, rightLegOffset - radius * 0.2), 
      width: radius * 0.4, 
      height: radius * 0.7
    );
    canvas.drawRect(rightFootRect, shoesPaint);
    canvas.drawRect(rightFootRect, outlinePaint);

    // Draw Hands (shoulders/arms out front)
    // Left hand
    final leftHandCenter = Offset(-radius * 0.6, radius * 0.4);
    canvas.drawCircle(leftHandCenter, radius * 0.25, skinPaint);
    canvas.drawCircle(leftHandCenter, radius * 0.25, outlinePaint);
    
    // Right hand
    final rightHandCenter = Offset(radius * 0.6, radius * 0.4);
    canvas.drawCircle(rightHandCenter, radius * 0.25, skinPaint);
    canvas.drawCircle(rightHandCenter, radius * 0.25, outlinePaint);

    // Draw Shoulders / Torso
    final torsoRect = Rect.fromCenter(center: Offset(0, 0), width: radius * 1.6, height: radius * 0.8);
    final torsoRRect = RRect.fromRectAndRadius(torsoRect, Radius.circular(radius * 0.4));
    canvas.drawRRect(torsoRRect, shirtPaint);
    canvas.drawRRect(torsoRRect, outlinePaint);

    // Draw Head
    final headCenter = Offset(0, radius * 0.1);
    canvas.drawCircle(headCenter, radius * 0.45, skinPaint);
    canvas.drawCircle(headCenter, radius * 0.45, outlinePaint);

    // Draw Hair (simple brown cap)
    final hairPaint = Paint()..color = const Color(0xFF5D4037);
    final hairRect = Rect.fromCenter(center: Offset(0, radius * -0.05), width: radius * 0.9, height: radius * 0.6);
    canvas.drawArc(hairRect, 3.14159, 3.14159, true, hairPaint);

    canvas.restore();

    // Draw Overhead Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$playerName: $npcCount',
        style: TextStyle(
          color: playerColor,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 2, color: Colors.white, offset: Offset(1, 1))],
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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
  }
}
