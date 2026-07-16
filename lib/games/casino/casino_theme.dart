import 'package:flutter/material.dart';

import 'casino_logic.dart';

abstract final class CasinoTheme {
  static const feltGreen = Color(0xFF1B5E3B);
  static const feltDark = Color(0xFF0F3D26);
  static const cardFace = Color(0xFFFFFDF8);
  static const cardBack = Color(0xFF1E3A5F);
  static const cardBackAccent = Color(0xFF2E5A8F);
  static const selectedBorder = Color(0xFFFFD54F);
  static const targetGlow = Color(0xFF66BB6A);
  static const buildBadge = Color(0xFF7E57C2);

  static const cardWidth = 58.0;
  static const cardHeight = 84.0;
  static const cardRadius = 7.0;
  static const cardOverlap = 22.0;

  static const aiTurnDelay = Duration(milliseconds: 600);
  static const uiAnimationDuration = Duration(milliseconds: 220);

  /// Classic deck red / black suit colors.
  static Color suitColor(Suit suit) =>
      suit.isRed ? const Color(0xFFE53935) : const Color(0xFF1A1A1A);
}
