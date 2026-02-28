import 'package:flame/components.dart';
import 'package:vodkania_game/game/entities/player/player_component.dart';
import 'package:vodkania_game/game/entities/npc/npc_component.dart';
import 'package:vodkania_game/game/config/tuning.dart';
import 'package:vodkania_game/game/state/game_state.dart';

/// System for handling competitive player and NPC collections
class CollisionSystem extends Component {
  CollisionSystem({
    required this.players,
    required this.npcs,
  });

  final List<PlayerComponent> players;
  final List<NpcComponent> npcs;

  @override
  void update(double dt) {
    super.update(dt);
    _checkPlayerNpcCollisions();
  }

  void _checkPlayerNpcCollisions() {
    for (final player in players) {
      for (final npc in npcs) {
        if (npc.state == NpcState.follower) continue;
        
        // Use a slightly larger collection radius for gameplay feel
        final distance = player.position.distanceTo(npc.position);
        if (distance <= Tuning.playerCollectionRadius + 10) {
          _recruitNpc(player, npc);
        }
      }
    }
  }

  void _recruitNpc(PlayerComponent capturingPlayer, NpcComponent npc) {
    npc.state = NpcState.follower;
    npc.leader = capturingPlayer;
    npc.shirtColor = capturingPlayer.playerColor; // visual feedback of team color
    
    // The target to follow is either the player or the tail of the current followers
    if (capturingPlayer.followers.isEmpty) {
      npc.targetFollow = capturingPlayer;
    } else {
      npc.targetFollow = capturingPlayer.followers.last;
    }
    
    capturingPlayer.followers.add(npc);
    capturingPlayer.npcCount++;

    final runState = GameState.instance.currentRun;
    if (runState != null) {
      runState.remainingNpcs--;
    }
  }
}
