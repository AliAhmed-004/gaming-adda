import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cartoon_assets.dart';

/// Wooden banner strip with gold-outlined title text.
class CartoonBannerTitle extends StatelessWidget {
  const CartoonBannerTitle({
    super.key,
    required this.title,
    this.height = 52,
    this.fontSize = 22,
  });

  final String title;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              CartoonAssets.bannerWood,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFE566),
                shadows: const [
                  Shadow(
                    color: Color(0xFF5C2E0A),
                    blurRadius: 0,
                    offset: Offset(0, 2),
                  ),
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
