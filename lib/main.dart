import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vodkania_game/game/vodkania_game.dart';
import 'package:vodkania_game/game/input/mouse_controls.dart';
import 'package:vodkania_game/game/input/keyboard_controls.dart';
import 'package:vodkania_game/game/ui/hud_overlay.dart';

import 'package:vodkania_game/game/ui/game_over_overlay.dart';
import 'package:vodkania_game/game/ui/map_selection_overlay.dart';
import 'package:vodkania_game/game/state/overlays.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for mobile only
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  final game = VodkaniaGame();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: KeyboardControls(
        onDirectionChanged: (direction) => game.movePlayer(direction),
        child: MouseControls(
          onDirectionChanged: (direction) => game.movePlayer(direction),
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              GameOverlays.hud: (context, game) => HudOverlay(game: game as VodkaniaGame),
              GameOverlays.gameOver: (context, game) => GameOverOverlay(
                    onRestart: () => (game as VodkaniaGame).restartGame(),
                    game: game as VodkaniaGame,
                  ),
              GameOverlays.mapSelection: (context, game) => MapSelectionOverlay(game: game as VodkaniaGame),
            },
          ),
        ),
      ),
    ),
  ));
}
