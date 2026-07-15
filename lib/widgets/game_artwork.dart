import 'package:flutter/material.dart';

/// Loads game art from a bundled asset (`assets/...`) or a network URL.
class GameArtwork extends StatelessWidget {
  const GameArtwork({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  bool get _isAsset => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final image = _isAsset
        ? Image.asset(
            url,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _fallback(),
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _fallback() {
    return ColoredBox(
      color: const Color(0xFF3D2914),
      child: SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(
            Icons.sports_esports,
            color: Color(0xFFFFE566),
            size: 40,
          ),
        ),
      ),
    );
  }
}

/// Play Store–style rounded square app icon.
class GameAppIcon extends StatelessWidget {
  const GameAppIcon({
    super.key,
    required this.url,
    this.size = 72,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Play Store squircles use ~20–25% corner radius.
    final radius = size * 0.22;
    final corners = BorderRadius.circular(radius);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GameArtwork(
        url: url,
        borderRadius: corners,
        width: size,
        height: size,
      ),
    );
  }
}
