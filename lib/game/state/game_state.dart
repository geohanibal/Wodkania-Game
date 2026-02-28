/// Global game state
class GameState {
  GameState._();
  static final instance = GameState._();

  // Map Selection
  String selectedMap = 'map.tmx';
  bool isTiledMap = true;

  // Current run state
  RunState? currentRun;

  // High scores / persistence (not implemented yet)
  int highScore = 0;

  void startNewRun() {
    currentRun = RunState();
  }

  void endRun() {
    currentRun = null;
  }

  void reset() {
    currentRun = null;
  }
}

/// State for a single game run
class RunState {
  int totalNpcs = 0;
  int remainingNpcs = 0;
  bool isGameOver = false;

  void update(double dt) {
    // Basic time/score updates can go here if needed
  }
}
