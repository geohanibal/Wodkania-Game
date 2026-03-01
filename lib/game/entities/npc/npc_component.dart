import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/config/game_config.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/util/math.dart';
import 'package:vodkania_game/game/vodkania_map.dart';

enum NpcState { free, follower }

// [EN] NPC value types - Normal (1 point), Rare (3 points, faster), Legendary (5 points, fastest + evades)
// [GE] NPC ტიპები - Normal (1 ქულა), Rare (3 ქულა, სწრაფი), Legendary (5 ქულა, გარბის მოთამაშეებისგან)
enum NpcTier { normal, rare, legendary }

/// NPC entity that can be collected to form a following chain
class NpcComponent extends PositionComponent with HasGameReference, CollisionCallbacks {
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

  // Static shared paints for performance
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.3 * 255)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

  static final Paint _skinPaint = Paint()..color = const Color(0xFFFFCC99);
  static final Paint _outlinePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _rareGlowPaint = Paint()
    ..color = Colors.purpleAccent.withValues(alpha: 0.5 * 255)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _legendaryGlowPaint = Paint()
    ..color = Colors.yellowAccent.withValues(alpha: 0.7 * 255)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  // Instance specific paints
  final Paint _shirtPaint = Paint()..color = const Color(0xFF2ECC71); // Default green

  Color get shirtColor => _shirtPaint.color;
  set shirtColor(Color value) {
    _shirtPaint.color = value;
  }

  Vector2 _lastValidPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void onMount() {
    super.onMount();
    _lastValidPosition = position.clone();
    _pickNewWanderTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastValidPosition = position.clone();

    if (state == NpcState.follower && targetFollow != null) {
      // Follow the target maintaining a 10 pixel distance
      final diff = targetFollow!.position - position;
      final dist = diff.length;

      // 10 pixel spacing requested by user
      if (dist > 10.0) {
        _velocity.setFrom(
          diff.normalized() * (Tuning.playerSpeed * 0.95),
        ); // Slightly slower/at speed to form chain
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
      final players =
          parent?.children.whereType<PlayerComponent>().toList() ?? [];
      PlayerComponent? nearestPlayer;
      var minPlayerDist = double.infinity;
      for (final p in players) {
        final d = p.position.distanceTo(position);
        if (d < minPlayerDist) {
          minPlayerDist = d;
          nearestPlayer = p;
        }
      }

      if (nearestPlayer != null &&
          minPlayerDist < Tuning.playerCollectionRadius + 150) {
        // Run away!
        _wanderTarget =
            position + (position - nearestPlayer.position).normalized() * 100;
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
      final distToTarget = (_wanderTarget - position).length;
      if (_wanderTimer <= 0 || distToTarget < 10) {
        _pickNewWanderTarget();
        _wanderTimer = MathUtils.randomRange(2, 5);
      }
    }

    final direction = (_wanderTarget - position).normalized();
    double speedMultiplier = 1.0;
    if (tier == NpcTier.rare) speedMultiplier = 1.4;
    if (tier == NpcTier.legendary) speedMultiplier = 1.8;

    _velocity.setFrom(
      direction *
          Tuning.civilianSpeed *
          MathUtils.randomRange(0.8, 1.2) *
          speedMultiplier,
    );
    position.add(_velocity * dt);

    position.x = position.x.clamp(Tuning.civilianRadius, GameConfig.worldWidth);
    position.y = position.y.clamp(
      Tuning.civilianRadius,
      GameConfig.worldHeight,
    );
  }

  void revertToLastPosition() {
    position.setFrom(_lastValidPosition);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is TiledWall) {
      if (intersectionPoints.length >= 2) {
        final midX = (intersectionPoints.first.x + intersectionPoints.last.x) / 2;
        final midY = (intersectionPoints.first.y + intersectionPoints.last.y) / 2;
        
        var normal = (position - Vector2(midX, midY)).normalized();
        if (normal.x.abs() > normal.y.abs()) {
          normal = Vector2(normal.x.sign, 0);
        } else {
          normal = Vector2(0, normal.y.sign);
        }

        position.add(normal * (_velocity.length * 0.016 + 1.0));
      } else {
        revertToLastPosition();
      }
    }
  }

  void _pickNewWanderTarget() {
    // If the NPC is near the edge of the world, force it to walk towards the center
    // to prevent getting stuck or pooling in the map corners.
    final margin = 150.0;
    if (position.x < margin || position.x > GameConfig.worldWidth - margin ||
        position.y < margin || position.y > GameConfig.worldHeight - margin) {
      
      final mapCenter = Vector2(GameConfig.worldWidth / 2, GameConfig.worldHeight / 2);
      final directionToCenter = (mapCenter - position).normalized();
      final escapeDistance = MathUtils.randomRange(150, 300);
      
      _wanderTarget = position + (directionToCenter * escapeDistance);
      return;
    }

    final angle = MathUtils.randomRange(0, 6.28);
    final distance = MathUtils.randomRange(20, Tuning.civilianWanderRadius);
    _wanderTarget = position + Vector2(distance, 0)
      ..rotate(angle);
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

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 8),
        width: radius * 1.6,
        height: radius * 0.7,
      ),
      _shadowPaint,
    );

    canvas.rotate(angle);

    // Simple minimal draw (torso + head) for NPC crowd performance
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

    final headCenter = Offset(0, radius * 0.1);
    canvas.drawCircle(headCenter, radius * 0.45, _skinPaint);
    canvas.drawCircle(headCenter, radius * 0.45, _outlinePaint);

    // Draw simple UI icon for Rare/Legendary
    if (state == NpcState.free) {
      if (tier == NpcTier.rare) {
        final glowPaint = Paint()
          ..color = Colors.purpleAccent.withValues(alpha: 0.5 * 255)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(const Offset(0, 0), radius * 1.5, glowPaint);
      } else if (tier == NpcTier.legendary) {
        final glowPaint = Paint()
          ..color = Colors.yellowAccent.withValues(alpha: 0.7 * 255)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(const Offset(0, 0), radius * 1.6, glowPaint);
      }
    }

    canvas.restore();
  }
}
