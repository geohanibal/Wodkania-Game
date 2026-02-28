import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/util/math.dart';

enum NpcState { free, follower }
// [EN] NPC value types - Normal (1 point), Rare (3 points, faster), Legendary (5 points, fastest + evades)
// [GE] NPC ტიპები - Normal (1 ქულა), Rare (3 ქულა, სწრაფი), Legendary (5 ქულა, გარბის მოთამაშეებისგან)
enum NpcTier { normal, rare, legendary }

/// NPC entity that can be collected to form a following chain
class NpcComponent extends PositionComponent with HasGameReference {
  NpcComponent({required Vector2 position, this.tier = NpcTier.normal})
      : super(
          position: position,
          size: Vector2.all(Tuning.civilianRadius * 2),
          anchor: Anchor.center,
        ) {
    if (tier == NpcTier.rare) {
      shirtColor = const Color(0xFF9B59B6); // Purple/Magic
      pointValue = 3;
    } else if (tier == NpcTier.legendary) {
      shirtColor = const Color(0xFFFFD700); // Gold
      pointValue = 5;
    }
  }

  NpcState state = NpcState.free;
  NpcTier tier;
  int pointValue = 1;
  PlayerComponent? leader;
  PositionComponent? targetFollow;

  late Vector2 _wanderTarget;
  double _wanderTimer = 0;
  final Vector2 _velocity = Vector2.zero();
  double _lastAngle = 0;
  
  // Base visual colors that change when recruited
  Color shirtColor = const Color(0xFF2ECC71); // Default green

  @override
  void onMount() {
    super.onMount();
    _pickNewWanderTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state == NpcState.follower && targetFollow != null) {
      // Follow the target maintaining a 10 pixel distance
      final diff = targetFollow!.position - position;
      final dist = diff.length;
      
      // 10 pixel spacing requested by user
      if (dist > 10.0) { 
        _velocity.setFrom(diff.normalized() * (Tuning.playerSpeed * 0.95)); // Slightly slower/at speed to form chain
      } else {
        _velocity.setZero();
      }
      position.add(_velocity * dt);
      return;
    }

    // [EN] Free state: wandering and evasion behavior for shiny NPCs
    // [GE] Free მდგომარეობა: ლოგიკა როცა NPC თავისუფალია. ლეგენდარული გარბის მოთამაშის დანახვაზე.
    if (tier == NpcTier.legendary) {
      // Evade nearest player
      final players = parent?.children.whereType<PlayerComponent>().toList() ?? [];
      PlayerComponent? nearestPlayer;
      var minPlayerDist = double.infinity;
      for (final p in players) {
        final d = p.position.distanceTo(position);
        if (d < minPlayerDist) {
          minPlayerDist = d;
          nearestPlayer = p;
        }
      }

      if (nearestPlayer != null && minPlayerDist < Tuning.playerCollectionRadius + 150) {
        // Run away!
        _wanderTarget = position + (position - nearestPlayer.position).normalized() * 100;
        _wanderTimer = 1.0; // Force update soon
      } else {
         _wanderTimer -= dt;
         if (_wanderTimer <= 0) {
           _pickNewWanderTarget();
           _wanderTimer = MathUtils.randomRange(1, 3);
         }
      }
    } else {
      _wanderTimer -= dt;
      if (_wanderTimer <= 0) {
        _pickNewWanderTarget();
        _wanderTimer = MathUtils.randomRange(2, 5);
      }
    }

    final direction = (_wanderTarget - position).normalized();
    double speedMultiplier = 1.0;
    if (tier == NpcTier.rare) speedMultiplier = 1.4;
    if (tier == NpcTier.legendary) speedMultiplier = 1.8;
    
    _velocity.setFrom(direction * Tuning.civilianSpeed * MathUtils.randomRange(0.8, 1.2) * speedMultiplier);
    position.add(_velocity * dt);

    position.x = position.x.clamp(Tuning.civilianRadius, GameConfig.worldWidth);
    position.y = position.y.clamp(Tuning.civilianRadius, GameConfig.worldHeight);
  }

  void _pickNewWanderTarget() {
    final angle = MathUtils.randomRange(0, 6.28);
    final distance = MathUtils.randomRange(20, Tuning.civilianWanderRadius);
    _wanderTarget = position + Vector2(distance, 0)..rotate(angle);
    _wanderTarget.x = _wanderTarget.x.clamp(50, GameConfig.worldWidth - 50);
    _wanderTarget.y = _wanderTarget.y.clamp(50, GameConfig.worldHeight - 50);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    var angle = _lastAngle;
    if (_velocity.length > 0) {
      final exactAngle = _velocity.screenAngle();
      angle = exactAngle;
      _lastAngle = angle;
    }
    
    canvas.rotate(angle);

    final skinPaint = Paint()..color = const Color(0xFFFFCC99);
    final shirtPaint = Paint()..color = shirtColor;
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Simple minimal draw (torso + head) for NPC crowd performance
    final torsoRect = Rect.fromCenter(center: const Offset(0, 0), width: radius * 1.6, height: radius * 0.8);
    final torsoRRect = RRect.fromRectAndRadius(torsoRect, Radius.circular(radius * 0.4));
    canvas.drawRRect(torsoRRect, shirtPaint);
    canvas.drawRRect(torsoRRect, outlinePaint);

    final headCenter = Offset(0, radius * 0.1);
    canvas.drawCircle(headCenter, radius * 0.45, skinPaint);
    canvas.drawCircle(headCenter, radius * 0.45, outlinePaint);
    
    // Draw simple UI icon for Rare/Legendary
    if (state == NpcState.free) {
      if (tier == NpcTier.rare) {
        final glowPaint = Paint()..color = Colors.purpleAccent.withValues(alpha: 0.5 * 255)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(const Offset(0, 0), radius * 1.5, glowPaint);
      } else if (tier == NpcTier.legendary) {
        final glowPaint = Paint()..color = Colors.yellowAccent.withValues(alpha: 0.7 * 255)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(const Offset(0, 0), radius * 1.6, glowPaint);
      }
    }

    canvas.restore();
  }
}
