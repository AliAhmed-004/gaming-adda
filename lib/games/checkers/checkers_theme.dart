import 'package:flutter/material.dart';

import 'checkers_logic.dart';

/// Colors and assets for the checkers play UI.
abstract final class CheckersTheme {
  static const gotiDark = 'assets/checkers/goti/goti_dark.png';
  static const gotiDarkKing = 'assets/checkers/goti/goti_dark_king.png';
  static const gotiLight = 'assets/checkers/goti/goti_light.png';
  static const gotiLightKing = 'assets/checkers/goti/goti_light_king.png';
  static const gotiTarget = 'assets/checkers/goti/goti_target.png';

  static const selectedGlow = Color(0xFF2DD4BF);
  static const glowAnimationDuration = Duration(milliseconds: 180);
  static const moveAnimationDuration = Duration(milliseconds: 260);
  static const captureAnimationDuration = Duration(milliseconds: 220);
  static const uiAnimationDuration = Duration(milliseconds: 220);

  static const frame = Color(0xFF334155);
  static const frameHighlight = Color(0xFF4B5E78);

  static const tileDarkTop = Color(0xFF263445);
  static const tileDarkBottom = Color(0xFF151D27);
  static const tileDarkBevel = Color(0xFF3D4F63);
  static const tileDarkShadow = Color(0xFF0C1118);

  static const tileLightTop = Color(0xFF3A4A5E);
  static const tileLightBottom = Color(0xFF2A3441);
  static const tileLightBevel = Color(0xFF4E6178);
  static const tileLightShadow = Color(0xFF1A222C);

  static String gotiAsset(Piece piece) {
    if (piece.isEmpty) return gotiDark;
    if (piece.isDark) {
      return piece.isKing ? gotiDarkKing : gotiDark;
    }
    return piece.isKing ? gotiLightKing : gotiLight;
  }
}
