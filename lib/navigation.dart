import 'package:flutter/material.dart';

import 'games/casino/casino_setup_screen.dart';
import 'games/checkers/checkers_setup_screen.dart';
import 'games/ludo/ludo_setup_screen.dart';
import 'games/penguin_brothers/penguin_setup_screen.dart';
import 'games/stack/stack_play_screen.dart';
import 'games/tic_tac_toe/tic_tac_toe_setup_screen.dart';
import 'models/game.dart';
import 'screens/play_game_screen.dart';

void openPlay(BuildContext context, Game game) {
  final Widget screen = switch (game.id) {
    'checkers' => const CheckersSetupScreen(),
    'ludo' => const LudoSetupScreen(),
    'penguin_brothers' => const PenguinSetupScreen(),
    'stack' => const StackPlayScreen(),
    'casino' => const CasinoSetupScreen(),
    'tic_tac_toe' => const TicTacToeSetupScreen(),
    _ => PlayGameScreen(game: game),
  };

  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
