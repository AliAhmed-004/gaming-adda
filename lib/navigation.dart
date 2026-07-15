import 'package:flutter/material.dart';

import 'games/checkers/checkers_play_screen.dart';
import 'models/game.dart';
import 'screens/play_game_screen.dart';

void openPlay(BuildContext context, Game game) {
  final Widget screen = game.id == 'checkers'
      ? const CheckersPlayScreen()
      : PlayGameScreen(game: game);

  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
}
