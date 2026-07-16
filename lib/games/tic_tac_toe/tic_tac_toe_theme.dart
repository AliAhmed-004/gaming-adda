import 'package:flutter/material.dart';

import 'tic_tac_toe_logic.dart';

/// Colors, assets, and motion timings for Tic-Tac-Toe.
abstract final class TicTacToeTheme {
  static const boardFrame = 'assets/tic_tac_toe/board_frame.png';
  static const cellEmpty = 'assets/tic_tac_toe/cell_empty.png';
  static const markX = 'assets/tic_tac_toe/mark_x.png';
  static const markO = 'assets/tic_tac_toe/mark_o.png';
  static const winLine = 'assets/tic_tac_toe/win_line.png';
  static const badgeX = 'assets/tic_tac_toe/badge_x.png';
  static const badgeO = 'assets/tic_tac_toe/badge_o.png';

  static const xColor = Color(0xFFE85D4C);
  static const oColor = Color(0xFF2A9D8F);
  static const boardBg = Color(0xFF3D2B1F);
  static const cellGlow = Color(0xFFF4D35E);
  static const panelWood = Color(0xFF5C3D2E);

  static const placeAnimationDuration = Duration(milliseconds: 320);
  static const winLineDuration = Duration(milliseconds: 420);
  static const uiAnimationDuration = Duration(milliseconds: 220);
  static const aiTurnDelay = Duration(milliseconds: 500);
  static const resultOverlayDelay = Duration(milliseconds: 480);

  static String markAsset(Mark mark) => switch (mark) {
    Mark.x => markX,
    Mark.o => markO,
    Mark.empty => cellEmpty,
  };

  static String badgeAsset(Mark mark) =>
      mark == Mark.x ? badgeX : badgeO;

  static Color markColor(Mark mark) => switch (mark) {
    Mark.x => xColor,
    Mark.o => oColor,
    Mark.empty => Colors.transparent,
  };
}
