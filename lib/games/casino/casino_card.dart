import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'casino_logic.dart';
import 'casino_theme.dart';

/// Classic French-suited playing card face (rank, suit, pips / court).
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    this.card,
    this.faceUp = true,
    this.selected = false,
    this.highlighted = false,
    this.floating = false,
    this.rankOnly = false,
    this.width = CasinoTheme.cardWidth,
    this.height = CasinoTheme.cardHeight,
    this.onTap,
  });

  final PlayingCard? card;
  final bool faceUp;
  final bool selected;
  final bool highlighted;
  final bool floating;
  final bool rankOnly;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? CasinoTheme.selectedBorder
        : highlighted
        ? CasinoTheme.targetGlow
        : const Color(0xFFBDBDBD);
    final borderWidth = selected || highlighted ? 2.2 : 1.0;
    final lift = selected ? -14.0 : (floating ? -8.0 : 0.0);

    return Semantics(
      button: onTap != null,
      label: faceUp && card != null ? card.toString() : 'Face-down card',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: CasinoTheme.uiAnimationDuration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, lift, 0),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: faceUp ? CasinoTheme.cardFace : null,
            borderRadius: BorderRadius.circular(CasinoTheme.cardRadius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (selected || highlighted || floating)
                BoxShadow(
                  color:
                      (selected
                              ? CasinoTheme.selectedBorder
                              : CasinoTheme.targetGlow)
                          .withValues(alpha: 0.55),
                  blurRadius: selected ? 16 : 12,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: selected || floating ? 10 : 3,
                offset: Offset(0, selected || floating ? 5 : 1.5),
              ),
            ],
            gradient: faceUp
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CasinoTheme.cardBackAccent, CasinoTheme.cardBack],
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: faceUp && card != null
              ? (rankOnly
                    ? _RankOnlyFace(card: card!, width: width, height: height)
                    : _ClassicFace(card: card!, width: width, height: height))
              : const _CardBack(),
        ),
      ),
    );
  }
}

class _RankOnlyFace extends StatelessWidget {
  const _RankOnlyFace({
    required this.card,
    required this.width,
    required this.height,
  });

  final PlayingCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = CasinoTheme.suitColor(card.suit);
    return Center(
      child: Text(
        card.rank.label,
        style: GoogleFonts.libreBaskerville(
          fontSize: height * 0.38,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ClassicFace extends StatelessWidget {
  const _ClassicFace({
    required this.card,
    required this.width,
    required this.height,
  });

  final PlayingCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = CasinoTheme.suitColor(card.suit);
    final cornerFont = (height * 0.17).clamp(7.0, 15.0);
    final suitFont = (height * 0.13).clamp(6.0, 12.0);
    final pad = (width * 0.055).clamp(2.0, 5.0);
    final isCourt =
        card.rank == Rank.jack ||
        card.rank == Rank.queen ||
        card.rank == Rank.king;

    return Stack(
      children: [
        Positioned(
          left: pad,
          top: pad * 0.5,
          child: _CornerIndex(
            card: card,
            color: color,
            rankSize: cornerFont,
            suitSize: suitFont,
          ),
        ),
        Positioned(
          right: pad,
          bottom: pad * 0.5,
          child: Transform.rotate(
            angle: math.pi,
            child: _CornerIndex(
              card: card,
              color: color,
              rankSize: cornerFont,
              suitSize: suitFont,
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCourt ? width * 0.2 : width * 0.18,
              vertical: isCourt ? height * 0.14 : height * 0.18,
            ),
            child: _CenterArt(card: card, color: color),
          ),
        ),
      ],
    );
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({
    required this.card,
    required this.color,
    required this.rankSize,
    required this.suitSize,
  });

  final PlayingCard card;
  final Color color;
  final double rankSize;
  final double suitSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rank.label,
          style: GoogleFonts.libreBaskerville(
            fontSize: rankSize,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0,
            letterSpacing: card.rank == Rank.ten ? -0.8 : 0,
          ),
        ),
        Text(
          card.suit.symbol,
          style: TextStyle(fontSize: suitSize, color: color, height: 1.0),
        ),
      ],
    );
  }
}

class _CenterArt extends StatelessWidget {
  const _CenterArt({required this.card, required this.color});

  final PlayingCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (card.rank) {
      case Rank.ace:
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.biggest.shortestSide * 0.78).clamp(
              10.0,
              44.0,
            );
            return Center(
              child: Text(
                card.suit.symbol,
                style: TextStyle(fontSize: size, color: color, height: 1),
              ),
            );
          },
        );
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return _CourtCard(card: card, color: color);
      default:
        return _PipLayout(card: card, color: color);
    }
  }
}

/// Standard pip positions as fractions of the center area (x, y) from top-left.
List<Offset> _pipOffsets(Rank rank) {
  switch (rank) {
    case Rank.two:
      return const [Offset(0.5, 0.12), Offset(0.5, 0.88)];
    case Rank.three:
      return const [Offset(0.5, 0.12), Offset(0.5, 0.5), Offset(0.5, 0.88)];
    case Rank.four:
      return const [
        Offset(0.28, 0.18),
        Offset(0.72, 0.18),
        Offset(0.28, 0.82),
        Offset(0.72, 0.82),
      ];
    case Rank.five:
      return const [
        Offset(0.28, 0.18),
        Offset(0.72, 0.18),
        Offset(0.5, 0.5),
        Offset(0.28, 0.82),
        Offset(0.72, 0.82),
      ];
    case Rank.six:
      return const [
        Offset(0.28, 0.18),
        Offset(0.72, 0.18),
        Offset(0.28, 0.5),
        Offset(0.72, 0.5),
        Offset(0.28, 0.82),
        Offset(0.72, 0.82),
      ];
    case Rank.seven:
      return const [
        Offset(0.28, 0.14),
        Offset(0.72, 0.14),
        Offset(0.5, 0.32),
        Offset(0.28, 0.5),
        Offset(0.72, 0.5),
        Offset(0.28, 0.86),
        Offset(0.72, 0.86),
      ];
    case Rank.eight:
      return const [
        Offset(0.28, 0.14),
        Offset(0.72, 0.14),
        Offset(0.5, 0.32),
        Offset(0.28, 0.5),
        Offset(0.72, 0.5),
        Offset(0.5, 0.68),
        Offset(0.28, 0.86),
        Offset(0.72, 0.86),
      ];
    case Rank.nine:
      return const [
        Offset(0.28, 0.12),
        Offset(0.72, 0.12),
        Offset(0.28, 0.34),
        Offset(0.72, 0.34),
        Offset(0.5, 0.5),
        Offset(0.28, 0.66),
        Offset(0.72, 0.66),
        Offset(0.28, 0.88),
        Offset(0.72, 0.88),
      ];
    case Rank.ten:
      return const [
        Offset(0.28, 0.10),
        Offset(0.72, 0.10),
        Offset(0.28, 0.30),
        Offset(0.72, 0.30),
        Offset(0.5, 0.40),
        Offset(0.5, 0.60),
        Offset(0.28, 0.70),
        Offset(0.72, 0.70),
        Offset(0.28, 0.90),
        Offset(0.72, 0.90),
      ];
    default:
      return const [];
  }
}

class _PipLayout extends StatelessWidget {
  const _PipLayout({required this.card, required this.color});

  final PlayingCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final offsets = _pipOffsets(card.rank);
    return LayoutBuilder(
      builder: (context, constraints) {
        final pipSize = (constraints.maxHeight * 0.18).clamp(6.0, 16.0);
        return Stack(
          children: [
            for (final o in offsets)
              Positioned(
                left: o.dx * constraints.maxWidth - pipSize / 2,
                top: o.dy * constraints.maxHeight - pipSize / 2,
                width: pipSize,
                height: pipSize,
                child: Center(
                  child: Text(
                    card.suit.symbol,
                    style: TextStyle(
                      fontSize: pipSize * 0.95,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.card, required this.color});

  final PlayingCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CourtPainter(rank: card.rank, suitColor: color),
      child: const SizedBox.expand(),
    );
  }
}

/// Simplified English-pattern reversible court (J / Q / K).
class _CourtPainter extends CustomPainter {
  _CourtPainter({required this.rank, required this.suitColor});

  final Rank rank;
  final Color suitColor;

  static const _blue = Color(0xFF1565C0);
  static const _gold = Color(0xFFF9A825);
  static const _cream = Color(0xFFFFF8E7);
  static const _skin = Color(0xFFFFE0B2);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(frame, Paint()..color = _cream);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final half = Size(size.width, size.height / 2);
    _paintHalf(canvas, half, upright: true);
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    _paintHalf(canvas, half, upright: true);
    canvas.restore();

    // Center divider band
    final midY = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(2, midY - 1.2, size.width - 4, 2.4),
      Paint()..color = _blue.withValues(alpha: 0.55),
    );
  }

  void _paintHalf(Canvas canvas, Size half, {required bool upright}) {
    final w = half.width;
    final h = half.height;

    // Side ornamental bands
    canvas.drawRect(
      Rect.fromLTWH(1.5, 2, 2.2, h - 4),
      Paint()..color = suitColor.withValues(alpha: 0.45),
    );
    canvas.drawRect(
      Rect.fromLTWH(w - 3.7, 2, 2.2, h - 4),
      Paint()..color = _blue.withValues(alpha: 0.4),
    );

    final cx = w / 2;
    final headR = math.min(w, h) * 0.18;
    final headCenter = Offset(cx, h * 0.32);

    // Torso / robe
    final robe = Path()
      ..moveTo(cx - w * 0.28, h * 0.92)
      ..lineTo(cx - w * 0.22, h * 0.48)
      ..quadraticBezierTo(cx, h * 0.42, cx + w * 0.22, h * 0.48)
      ..lineTo(cx + w * 0.28, h * 0.92)
      ..close();
    canvas.drawPath(robe, Paint()..color = suitColor);
    canvas.drawPath(
      robe,
      Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Gold sash
    canvas.drawLine(
      Offset(cx - w * 0.18, h * 0.62),
      Offset(cx + w * 0.18, h * 0.62),
      Paint()
        ..color = _gold
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Head
    canvas.drawCircle(headCenter, headR, Paint()..color = _skin);
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    // Hair / crown by rank
    switch (rank) {
      case Rank.king:
        _drawCrown(canvas, headCenter, headR);
        _drawSword(canvas, cx, h, w);
      case Rank.queen:
        _drawCrown(canvas, headCenter, headR * 0.9);
        _drawFlower(canvas, Offset(cx + w * 0.22, h * 0.55), w * 0.12);
      case Rank.jack:
        _drawHair(canvas, headCenter, headR);
        _drawHat(canvas, headCenter, headR);
      default:
        break;
    }

    // Eyes
    final eyeY = headCenter.dy - headR * 0.05;
    canvas.drawCircle(
      Offset(headCenter.dx - headR * 0.35, eyeY),
      0.7,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headR * 0.35, eyeY),
      0.7,
      Paint()..color = Colors.black87,
    );
  }

  void _drawHair(Canvas canvas, Offset c, double r) {
    final hair = Path()
      ..moveTo(c.dx - r * 0.95, c.dy)
      ..quadraticBezierTo(c.dx - r, c.dy - r * 1.3, c.dx, c.dy - r * 1.35)
      ..quadraticBezierTo(c.dx + r, c.dy - r * 1.3, c.dx + r * 0.95, c.dy)
      ..close();
    canvas.drawPath(hair, Paint()..color = _gold);
  }

  void _drawHat(Canvas canvas, Offset c, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - r * 0.85),
          width: r * 1.6,
          height: r * 0.45,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = _blue,
    );
  }

  void _drawCrown(Canvas canvas, Offset c, double r) {
    final top = c.dy - r * 1.05;
    final path = Path()
      ..moveTo(c.dx - r * 0.95, top + r * 0.35)
      ..lineTo(c.dx - r * 0.7, top)
      ..lineTo(c.dx - r * 0.35, top + r * 0.28)
      ..lineTo(c.dx, top - r * 0.08)
      ..lineTo(c.dx + r * 0.35, top + r * 0.28)
      ..lineTo(c.dx + r * 0.7, top)
      ..lineTo(c.dx + r * 0.95, top + r * 0.35)
      ..close();
    canvas.drawPath(path, Paint()..color = _gold);
    canvas.drawPath(
      path,
      Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  void _drawSword(Canvas canvas, double cx, double h, double w) {
    final paint = Paint()
      ..color = _blue
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + w * 0.26, h * 0.38),
      Offset(cx + w * 0.32, h * 0.12),
      paint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.22, h * 0.2),
      Offset(cx + w * 0.38, h * 0.22),
      Paint()
        ..color = _gold
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFlower(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(c, s * 0.55, Paint()..color = _gold);
    canvas.drawCircle(c, s * 0.22, Paint()..color = suitColor);
    canvas.drawLine(
      Offset(c.dx, c.dy + s * 0.4),
      Offset(c.dx, c.dy + s * 1.1),
      Paint()
        ..color = _blue
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtPainter oldDelegate) =>
      oldDelegate.rank != rank || oldDelegate.suitColor != suitColor;
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CardBackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E5A8F), Color(0xFF1E3A5F)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      bg,
    );

    final border = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
        const Radius.circular(3),
      ),
      border,
    );

    final diamond = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    const step = 8.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final path = Path()
          ..moveTo(x + step / 2, y)
          ..lineTo(x + step, y + step / 2)
          ..lineTo(x + step / 2, y + step)
          ..lineTo(x, y + step / 2)
          ..close();
        canvas.drawPath(path, diamond);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
