import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class PenguinTheme {
  static const hudBg = Color(0xCC2A1A0C);
  static const accent = Color(0xFFFFE566);
  static const wood = Color(0xFF4A2C14);
  static const green = Color(0xFF3DBE5A);
  static const pink = Color(0xFFE85A9B);

  static TextStyle hud({double fontSize = 16}) => GoogleFonts.fredoka(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
  );

  static TextStyle title({double fontSize = 28}) => GoogleFonts.fredoka(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: accent,
    shadows: const [
      Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
    ],
  );

  static TextStyle combo({double fontSize = 22}) => GoogleFonts.fredoka(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: accent,
    shadows: const [
      Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4),
    ],
  );
}
