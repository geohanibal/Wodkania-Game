import 'package:vodkania_game/game/state/game_state.dart';

/// Run state tracking for current game session
/// This is a convenience wrapper around GameState.instance.currentRun
class RunStateManager {
  static RunState get current {
    final run = GameState.instance.currentRun;
    if (run == null) {
      throw StateError('No active run');
    }
    return run;
  }

  static bool get hasActiveRun => GameState.instance.currentRun != null;
}
