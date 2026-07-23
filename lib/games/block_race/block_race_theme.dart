import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class BlockRaceTheme {
  static const Color background = Color(0xFF1A2332);
  static const Color foreground = Color(0xFFF8FAFC);
  static const Color boardBase = Color(0xFF2D3748);
  static const Color pathTile = Color(0xFF4A5568);
  static const Color pathHighlight = Color(0xFF718096);
  static const Color bluePlayer = Color(0xFF3B82F6);
  static const Color redPlayer = Color(0xFFEF4444);
  static const Color barricade = Color(0xFFF59E0B);
  static const Color goalGlow = Color(0xFF34D399);

  static const int bluePlayerHex = 0x3B82F6;
  static const int redPlayerHex = 0xEF4444;
  static const int barricadeHex = 0xF59E0B;
  static const int pathTileHex = 0x4A5568;
  static const int boardBaseHex = 0x2D3748;
  static const int goalBlueHex = 0x34D399;
  static const int goalRedHex = 0xF472B6;

  static const double cellSize = 1.4;
  static const double pawnHeight = 0.55;
  static const double pawnRadius = 0.35;
  static const double barricadeHeight = 0.9;
  static const double moveAnimationDuration = 0.45;
  static const double barricadeAnimationDuration = 0.35;
  static const double hopHeight = 0.55;

  static TextStyle comfortaa({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = foreground,
  }) {
    return GoogleFonts.comfortaa(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
