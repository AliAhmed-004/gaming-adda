import 'package:flutter/material.dart';

import 'games/checkers/checkers_setup_screen.dart';
import 'games/ludo/ludo_setup_screen.dart';
import 'games/penbros_arcade/penbros_arcade_play_screen.dart';
import 'games/penguin_brothers/penguin_setup_screen.dart';
import 'models/game.dart';
import 'screens/play_game_screen.dart';

void openPlay(BuildContext context, Game game) {
  final Widget screen = switch (game.id) {
    'checkers' => const CheckersSetupScreen(),
    'ludo' => const LudoSetupScreen(),
    'penguin_brothers' => const PenguinSetupScreen(),
    'penbros_arcade' => const PenbrosArcadePlayScreen(),
    _ => PlayGameScreen(game: game),
  };

  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
