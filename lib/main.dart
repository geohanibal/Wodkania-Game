import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vodkania_game/game/state/overlays.dart';
import 'package:vodkania_game/game/ui/game_over_overlay.dart';
import 'package:vodkania_game/game/ui/hud_overlay.dart';
import 'package:vodkania_game/game/ui/main_menu_overlay.dart';
import 'package:vodkania_game/game/ui/map_selection_overlay.dart';
import 'package:vodkania_game/game/vodkania_game.dart';

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
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              GameOverlays.mainMenu: (context, game) =>
                      MainMenuOverlay(game: game! as VodkaniaGame),
                GameOverlays.hud: (context, game) =>
                    HudOverlay(game: game! as VodkaniaGame),
                GameOverlays.gameOver: (context, game) => GameOverOverlay(
                  onRestart: () => (game! as VodkaniaGame).restartGame(),
                  game: game as VodkaniaGame,
                ),
                GameOverlays.mapSelection: (context, game) =>
                    MapSelectionOverlay(game: game! as VodkaniaGame),
              },
            ),
          ),
        ),
      ),
    ),
  );
}
