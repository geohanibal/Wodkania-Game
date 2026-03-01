/// Global game state
class GameState {
  GameState._();
  static final instance = GameState._();

  // Map Selection
  String selectedMap = 'map.tmx';
  bool isTiledMap = true;

  // Current run state
  RunState? currentRun;

  // Level Progression System
  int currentLevel = 1;
  final Set<int> completedLevels = {};
  int maxUnlockedLevel = 1;

  String get currentStageName {
    if (currentLevel <= 6) return 'Stage 1 - Easy';
    if (currentLevel <= 14) return 'Stage 2 - Normal';
    if (currentLevel <= 22) return 'Stage 3 - Hard';
    return 'Stage 4 - Expert';
  }

  void startNewRun() {
    currentRun = RunState();
  }

  void endRun() {
    currentRun = null;
  }

  void levelUp() {
    completedLevels.add(currentLevel);
    if (currentLevel < 30) {
      currentLevel++;
      if (currentLevel > maxUnlockedLevel) {
        maxUnlockedLevel = currentLevel;
      }
    }
  }

  void reset() {
    currentRun = null;
    currentLevel = 1;
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
