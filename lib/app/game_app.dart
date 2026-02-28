import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vodkania_game/game/input/keyboard_controls.dart';
import 'package:vodkania_game/game/input/mouse_controls.dart';
import 'package:vodkania_game/game/ui/game_over_overlay.dart';
import 'package:vodkania_game/game/ui/hud_overlay.dart';
import 'package:vodkania_game/game/ui/pause_overlay.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

/// Main game app wrapper
class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vodkania Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late VodkaniaGame _game;

  @override
  void initState() {
    super.initState();
    _game = VodkaniaGame();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    Widget gameContent = Scaffold(
      appBar: AppBar(
        title: const Text('Vodkania Game'),
      ),
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'hud': (context, game) => HudOverlay(game: _game),
              'pause': (context, game) =>
                  PauseOverlay(onResume: () => _game.resumeEngine()),
              'gameOver': (context, game) =>
                  GameOverOverlay(onRestart: () => _game.restart()),
            },
          ),
        ],
      ),
    );

    if (isDesktop) {
      // First wrap with mouse controls (outer)
      gameContent = MouseControls(
        onDirectionChanged: (direction) {
          if (direction.length > 0.1) {
            _game.movePlayer(direction);
          } else {
            _game.stopPlayer();
          }
        },
        child: gameContent,
      );
      // Then wrap with keyboard controls (inner, so both work)
      gameContent = KeyboardControls(
        onDirectionChanged: (direction) {
          if (direction.length > 0.1) {
            _game.movePlayer(direction);
          } else {
            _game.stopPlayer();
          }
        },
        child: gameContent,
      );
    }

    return gameContent;
  }
}
