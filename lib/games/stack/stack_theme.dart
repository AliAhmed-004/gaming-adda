import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class StackTheme {
  static const Color background = Color(0xFFD0CBC7);
  static const Color foreground = Color(0xFF333344);
  static const int baseBlockColor = 0x333344;

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
