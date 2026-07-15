import 'package:flutter/material.dart';

import 'ludo_logic.dart';

/// Visual tokens for the modern Ludo play UI (reference-style).
abstract final class LudoTheme {
  static const iconAsset = 'assets/icons/ludo.png';

  static const tokenRed = 'assets/ludo/tokens/token_red.png';
  static const tokenGreen = 'assets/ludo/tokens/token_green.png';
  static const tokenYellow = 'assets/ludo/tokens/token_yellow.png';
  static const tokenBlue = 'assets/ludo/tokens/token_blue.png';

  static String tokenAsset(LudoColor c) => switch (c) {
    LudoColor.red => tokenRed,
    LudoColor.green => tokenGreen,
    LudoColor.yellow => tokenYellow,
    LudoColor.blue => tokenBlue,
  };

  static const bgTop = Color(0xFF0B1B4A);
  static const bgBottom = Color(0xFF071233);
  static const boardFrame = Color(0xFF5EC8FF);
  static const boardFill = Color(0xFFF4F7FB);
  static const pathCell = Color(0xFFFFFFFF);
  static const pathStroke = Color(0xFFD7DEE8);
  static const dieWell = Color(0xFF1E4D9C);
  static const statusText = Color(0xFFE8EEFF);

  static Color vivid(LudoColor c) => switch (c) {
    LudoColor.red => const Color(0xFFFF3B3B),
    LudoColor.green => const Color(0xFF22C55E),
    LudoColor.yellow => const Color(0xFFFACC15),
    LudoColor.blue => const Color(0xFF3B82F6),
  };

  static Color deep(LudoColor c) => switch (c) {
    LudoColor.red => const Color(0xFFDC2626),
    LudoColor.green => const Color(0xFF16A34A),
    LudoColor.yellow => const Color(0xFFEAB308),
    LudoColor.blue => const Color(0xFF2563EB),
  };

  /// Screen corner for each yard (classic seats).
  static Alignment avatarAlignment(LudoColor c) => switch (c) {
    LudoColor.green => Alignment.topLeft,
    LudoColor.yellow => Alignment.topRight,
    LudoColor.red => Alignment.bottomLeft,
    LudoColor.blue => Alignment.bottomRight,
  };
}
