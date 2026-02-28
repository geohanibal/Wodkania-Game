# Vodkania Game

A 2D top-down action/survival crowd game set in the fictional state "Vodkania". Play as a rebel leader fleeing police while recruiting civilians to grow your supporter base!

## 🎮 Game Overview

**Vodkania** is a mobile-first survival game where you:
- Control a rebel leader escaping from police
- Recruit civilians to build your crowd of supporters
- Compete with rival factions for supporters
- Collect equipment to boost your power
- Survive as long as possible while difficulty escalates

## 🎯 Core Gameplay

- **Player Power** = Supporters + Equipment Bonuses
- **Recruit Civilians**: Collect yellow civilians to grow your crowd
- **Faction Battles**: When you collide with rival factions, the stronger side steals supporters
- **Police Pursuit**: Police chase you - get captured with <10 supporters = Game Over
- **Equipment**: Collect gas masks and goggles for power boosts
- **Difficulty Scaling**: Police get faster and spawn more frequently over time

## 🏗️ Tech Stack

- **Flutter** (latest stable)
- **Flame** game engine (1.18.0)
- **Dart 3**
- **very_good_analysis** for strict linting

## 📁 Project Structure

```
lib/
  ├── main.dart
  ├── app/
  │   └── game_app.dart
  └── game/
      ├── vodkania_game.dart
      ├── config/              # Game configuration & tuning
      ├── state/               # Game state management
      ├── input/               # Mobile joystick controls
      ├── world/               # World building & camera
      ├── systems/             # Core game systems (collision, spawn, difficulty)
      ├── entities/            # Game entities (player, police, factions, items)
      ├── mechanics/           # Game mechanics (crowd rules, equipment, combat)
      ├── ui/                  # UI overlays (HUD, pause, game over)
      └── util/                # Utilities (math, timers, object pool)
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.0 or later)
- Dart SDK (3.0.0 or later)

### Installation

```bash
# Get dependencies
flutter pub get

# Run the game
flutter run

# For mobile device
flutter run -d <device-id>
```

### Build

```bash
# Android APK
flutter build apk --release

# Web (optional, mobile is priority)
flutter build web
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/crowd_rules_test.dart

# Format code
dart format .

# Analyze code
flutter analyze
```

## 🎨 Game Controls

**Mobile:**
- **Joystick** (bottom-left): Move your character
- Touch and drag to control direction

**Desktop (for testing):**
- Currently optimized for mobile, keyboard controls can be added if needed

## ⚙️ Configuration & Tuning

All gameplay parameters can be adjusted in [`lib/game/config/tuning.dart`](lib/game/config/tuning.dart):

- Player speed, starting supporters
- Civilian spawn rates and behavior
- Faction AI parameters
- Police detection radius, chase speed
- Equipment bonuses
- Difficulty scaling rates

## 🏆 Game Mechanics

### Crowd Rules
- Supporters transfer between entities based on power difference
- Transfer amount: ~20% of power difference (clamped 1-10)
- Can't transfer more than the loser has

### Police Mechanics
- Detection radius: 200 units
- Capture with <10 supporters: Game Over
- Capture with ≥10 supporters: Lose 5 supporters (penalty)

### Difficulty Escalation
- Every 60 seconds: difficulty level increases
- Police speed increases by 10/level
- Police spawn interval decreases by 2s/level (min 10s)

## 📊 Performance

**Target:** 60 FPS on mid-range Android devices

**Optimizations:**
- Object pooling for frequent spawns
- Efficient collision detection
- Minimal UI updates
- Clean component lifecycle management

## 🔧 CI/CD

GitHub Actions workflow runs on every push:
1. Format check
2. Static analysis
3. Run tests
4. Build APK

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

## 🎭 Entity Colors

- **Player**: Blue
- **Civilians**: Yellow
- **Factions**: Pink, Purple, Cyan
- **Police**: Red
- **Items**: Green

## 📝 License

This project is for educational/demo purposes.

## 🤝 Contributing

1. Follow the existing code structure
2. Add tests for new mechanics
3. Keep mobile performance in mind
4. Use `very_good_analysis` linting rules

## 📱 Platform Support

- ✅ **Android** (primary target)
- ✅ **iOS** (supported)
- ⚠️ **Web** (works but mobile UX is priority)
- ⚠️ **Desktop** (not optimized)

## 🎯 Development Roadmap

- [x] Core gameplay loop
- [x] Mobile controls
- [x] Collision & combat system
- [x] Difficulty scaling
- [x] UI overlays
- [ ] Sound effects & music
- [ ] Persistent high scores
- [ ] Power-ups & abilities
- [ ] Multiple maps/environments
- [ ] Tutorial mode

## 🐛 Known Issues

- Police AI can occasionally path inefficiently
- Web build may have touch input lag on some devices

## 💡 Tips for Playing

1. **Recruit early**: Build your crowd before police show up
2. **Avoid strong factions**: Check their size before engaging
3. **Collect equipment**: Every bonus counts in encounters
4. **Keep moving**: Don't let police corner you
5. **Strategic retreats**: Sometimes running is better than fighting

---

Built with ❤️ using Flutter & Flame 
