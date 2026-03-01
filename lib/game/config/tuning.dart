/// Tuning parameters for gameplay balancing
class Tuning {
  // Player
  static const double playerSpeed = 200; // Increased from 150
  static const double playerRadius = 25; // Increased from 20
  static const int playerStartingSupporters = 5;
  static const double playerCollectionRadius =
      60; // How close to collect civilians

  // Civilians
  static const int maxCivilians = 100;
  static const double civilianSpawnInterval = 2; // seconds
  static const double civilianSpeed = 100;
  static const double civilianRadius = 15;
  static const double civilianWanderRadius = 50;
  static const double civilianPanicRange = 150;
  static const double civilianPanicSpeed = 120;

  // Factions
  static const int numFactions = 3;
  static const int factionStartingSupporters = 3;
  static const double factionSpeed = 100;
  static const double factionRadius = 18;
  static const double factionCollectionRadius = 80;

  // Combat/Encounters
  static const int encounterRadius = 40;
  static const double encounterCooldown = 1; // seconds between encounters
  static const double supporterTransferRatio = 0.2; // 20% of difference
  static const int minSupporterTransfer = 1;
  static const int maxSupporterTransfer = 10;

  // Items/Equipment
  static const int maxItems = 10;
  static const double itemSpawnInterval = 15; // seconds
  static const double itemRadius = 12;
  static const double itemCollectionRadius = 30;

  // Equipment bonuses
  static const int gasMaskBonus = 5;
  static const int gogglesBonus = 3;

  // Difficulty scaling
  static const double difficultyIncreaseInterval = 60; // seconds
}
