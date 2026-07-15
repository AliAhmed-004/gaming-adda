import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens for skeuomorphic cartoon game menus (see checkers-settings.md).
abstract final class CartoonTheme {
  static const cream = Color(0xFFE8D9B8);
  static const wood = Color(0xFF4A2C14);
  static const woodMuted = Color(0xFF6B4423);
  static const titleYellow = Color(0xFFFFE566);
  static const titleOutline = Color(0xFF5C2E0A);
  static const focusRing = Color(0xFFFFE566);

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;

  static const minTouch = 48.0;
  static const panelMaxWidth = 400.0;
  static const pressDuration = Duration(milliseconds: 160);

  static TextStyle bannerTitle({double fontSize = 28}) => GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: titleYellow,
        height: 1.1,
        shadows: const [
          Shadow(color: titleOutline, offset: Offset(0, 3)),
          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  static TextStyle circleLabel({double fontSize = 13}) => GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: wood,
        height: 1.2,
      );

  static TextStyle pillLabel({double fontSize = 20}) => GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 2)),
        ],
      );

  static TextStyle sectionLabel({double fontSize = 12}) => GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: woodMuted,
      );
}
