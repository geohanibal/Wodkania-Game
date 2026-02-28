import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/util/math.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';

enum NpcState { free, follower }

/// NPC entity that can be collected to form a following chain
class NpcComponent extends PositionComponent with HasGameReference {
  NpcComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(Tuning.civilianRadius * 2),
          anchor: Anchor.center,
        );

  NpcState state = NpcState.free;
  PlayerComponent? leader;
  PositionComponent? targetFollow;

  late Vector2 _wanderTarget;
  double _wanderTimer = 0;
  final Vector2 _velocity = Vector2.zero();
  double _lastAngle = 0.0;
  
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

    // Free state: simple wander behavior
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _pickNewWanderTarget();
      _wanderTimer = MathUtils.randomRange(2, 5);
    }

    final direction = (_wanderTarget - position).normalized();
    _velocity.setFrom(direction * Tuning.civilianSpeed * MathUtils.randomRange(0.5, 1.0));
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

    double angle = _lastAngle;
    if (_velocity.length > 0) {
      double exactAngle = _velocity.screenAngle();
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

    canvas.restore();
  }
}
