import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ludo_logic.dart';
import 'ludo_theme.dart';

/// Grid cell for the shared track (global index → row, col on 15×15).
@immutable
class BoardCell {
  const BoardCell(this.row, this.col);
  final int row;
  final int col;
}

class LudoBoardGeometry {
  LudoBoardGeometry._();

  static const grid = 15;

  /// Clockwise path; index 0 = red start, 13 = green, 26 = yellow, 39 = blue.
  static const track = <BoardCell>[
    BoardCell(13, 6),
    BoardCell(12, 6),
    BoardCell(11, 6),
    BoardCell(10, 6),
    BoardCell(9, 6),
    BoardCell(8, 5),
    BoardCell(8, 4),
    BoardCell(8, 3),
    BoardCell(8, 2),
    BoardCell(8, 1),
    BoardCell(8, 0),
    BoardCell(7, 0),
    BoardCell(6, 0),
    BoardCell(6, 1),
    BoardCell(6, 2),
    BoardCell(6, 3),
    BoardCell(6, 4),
    BoardCell(6, 5),
    BoardCell(5, 6),
    BoardCell(4, 6),
    BoardCell(3, 6),
    BoardCell(2, 6),
    BoardCell(1, 6),
    BoardCell(0, 6),
    BoardCell(0, 7),
    BoardCell(0, 8),
    BoardCell(1, 8),
    BoardCell(2, 8),
    BoardCell(3, 8),
    BoardCell(4, 8),
    BoardCell(5, 8),
    BoardCell(6, 9),
    BoardCell(6, 10),
    BoardCell(6, 11),
    BoardCell(6, 12),
    BoardCell(6, 13),
    BoardCell(6, 14),
    BoardCell(7, 14),
    BoardCell(8, 14),
    BoardCell(8, 13),
    BoardCell(8, 12),
    BoardCell(8, 11),
    BoardCell(8, 10),
    BoardCell(8, 9),
    BoardCell(9, 8),
    BoardCell(10, 8),
    BoardCell(11, 8),
    BoardCell(12, 8),
    BoardCell(13, 8),
    BoardCell(14, 8),
    BoardCell(14, 7),
    BoardCell(14, 6),
  ];

  static const homeStretch = <LudoColor, List<BoardCell>>{
    LudoColor.red: [
      BoardCell(13, 7),
      BoardCell(12, 7),
      BoardCell(11, 7),
      BoardCell(10, 7),
      BoardCell(9, 7),
    ],
    LudoColor.green: [
      BoardCell(7, 1),
      BoardCell(7, 2),
      BoardCell(7, 3),
      BoardCell(7, 4),
      BoardCell(7, 5),
    ],
    LudoColor.yellow: [
      BoardCell(1, 7),
      BoardCell(2, 7),
      BoardCell(3, 7),
      BoardCell(4, 7),
      BoardCell(5, 7),
    ],
    LudoColor.blue: [
      BoardCell(7, 13),
      BoardCell(7, 12),
      BoardCell(7, 11),
      BoardCell(7, 10),
      BoardCell(7, 9),
    ],
  };

  static const yardSlots = <LudoColor, List<BoardCell>>{
    LudoColor.red: [
      BoardCell(11, 2),
      BoardCell(11, 4),
      BoardCell(13, 2),
      BoardCell(13, 4),
    ],
    LudoColor.green: [
      BoardCell(2, 2),
      BoardCell(2, 4),
      BoardCell(4, 2),
      BoardCell(4, 4),
    ],
    LudoColor.yellow: [
      BoardCell(2, 10),
      BoardCell(2, 12),
      BoardCell(4, 10),
      BoardCell(4, 12),
    ],
    LudoColor.blue: [
      BoardCell(11, 10),
      BoardCell(11, 12),
      BoardCell(13, 10),
      BoardCell(13, 12),
    ],
  };

  static const yardRects = <LudoColor, (int r0, int c0, int r1, int c1)>{
    LudoColor.red: (9, 0, 14, 5),
    LudoColor.green: (0, 0, 5, 5),
    LudoColor.yellow: (0, 9, 5, 14),
    LudoColor.blue: (9, 9, 14, 14),
  };

  /// Star safes (not starts) tinted toward the nearest arm color.
  static Color starColor(int globalIndex) => switch (globalIndex) {
    8 => LudoTheme.vivid(LudoColor.green),
    21 => LudoTheme.vivid(LudoColor.yellow),
    34 => LudoTheme.vivid(LudoColor.blue),
    47 => LudoTheme.vivid(LudoColor.red),
    _ => const Color(0xFF94A3B8),
  };

  static Color colorOf(LudoColor c) => LudoTheme.vivid(c);

  static BoardCell cellForToken(LudoToken token) {
    if (token.inYard) {
      return yardSlots[token.color]![token.id];
    }
    if (token.isFinished) {
      return const BoardCell(7, 7);
    }
    if (token.onHomeStretch) {
      final i = token.progress - LudoGame.homeStretchStart;
      return homeStretch[token.color]![i];
    }
    return track[token.globalIndex!];
  }

  static Offset centerOf(BoardCell cell, double boardSize) {
    final cellSize = boardSize / grid;
    return Offset((cell.col + 0.5) * cellSize, (cell.row + 0.5) * cellSize);
  }

  static int progressPercent(LudoGame game, LudoColor color) {
    final tokens = game.tokensFor(color);
    if (tokens.isEmpty) return 0;
    final sum = tokens.fold<int>(
      0,
      (a, t) => a + (t.progress < 0 ? 0 : t.progress),
    );
    return ((sum / (LudoGame.tokensPerPlayer * LudoGame.finishedProgress)) *
            100)
        .round()
        .clamp(0, 100);
  }
}

class LudoBoard extends StatelessWidget {
  const LudoBoard({
    super.key,
    required this.game,
    required this.selectedTokenId,
    required this.movableTokenIds,
    required this.interactive,
    required this.onTokenTap,
    required this.onBoardTap,
    this.playerLabels = const {},
  });

  final LudoGame game;
  final int? selectedTokenId;
  final Set<int> movableTokenIds;
  final bool interactive;
  final void Function(LudoColor color, int tokenId) onTokenTap;
  final VoidCallback onBoardTap;
  final Map<LudoColor, String> playerLabels;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return GestureDetector(
            onTap: onBoardTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: LudoTheme.boardFrame, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: LudoTheme.boardFrame.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.square(size),
                      painter: _LudoBoardPainter(
                        activeColors: game.activeColors.toSet(),
                        playerLabels: {
                          for (final c in game.activeColors)
                            c: playerLabels[c] ?? c.label,
                        },
                        progressByColor: {
                          for (final c in LudoColor.values)
                            c: LudoBoardGeometry.progressPercent(game, c),
                        },
                        turn: game.turn,
                      ),
                    ),
                    ..._tokenWidgets(size),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tokenWidgets(double boardSize) {
    final widgets = <Widget>[];
    final cellSize = boardSize / LudoBoardGeometry.grid;
    final tokenSize = cellSize * 1.05;

    for (final color in game.activeColors) {
      for (final token in game.tokensFor(color)) {
        if (token.isFinished) continue;
        final cell = LudoBoardGeometry.cellForToken(token);
        final center = LudoBoardGeometry.centerOf(cell, boardSize);
        final movable =
            movableTokenIds.contains(token.id) && token.color == game.turn;
        final selected =
            selectedTokenId == token.id && token.color == game.turn;

        widgets.add(
          Positioned(
            left: center.dx - tokenSize / 2,
            top: center.dy - tokenSize * 0.72,
            width: tokenSize,
            height: tokenSize,
            child: GestureDetector(
              onTap: interactive
                  ? () => onTokenTap(token.color, token.id)
                  : null,
              child: _TokenSprite(
                asset: LudoTheme.tokenAsset(color),
                selected: selected,
                movable: movable,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _TokenSprite extends StatelessWidget {
  const _TokenSprite({
    required this.asset,
    required this.selected,
    required this.movable,
  });

  final String asset;
  final bool selected;
  final bool movable;

  @override
  Widget build(BuildContext context) {
    final glow = selected || movable;
    return AnimatedScale(
      scale: selected ? 1.12 : (movable ? 1.06 : 1.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: glow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xFF5EEAD4).withValues(alpha: 0.75)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.55),
                    blurRadius: selected ? 12 : 8,
                    spreadRadius: selected ? 1 : 0,
                  ),
                ],
              )
            : const BoxDecoration(),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _LudoBoardPainter extends CustomPainter {
  _LudoBoardPainter({
    required this.activeColors,
    required this.playerLabels,
    required this.progressByColor,
    required this.turn,
  });

  final Set<LudoColor> activeColors;
  final Map<LudoColor, String> playerLabels;
  final Map<LudoColor, int> progressByColor;
  final LudoColor turn;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / LudoBoardGeometry.grid;
    final boardR = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(boardR, Paint()..color = LudoTheme.boardFill);

    // Path corridor fill (cross)
    canvas.drawRect(
      Rect.fromLTWH(6 * cell, 0, 3 * cell, size.height),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 6 * cell, size.width, 3 * cell),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    for (final entry in LudoBoardGeometry.yardRects.entries) {
      _paintYard(canvas, cell, entry.key, entry.value);
    }

    for (var i = 0; i < LudoBoardGeometry.track.length; i++) {
      final c = LudoBoardGeometry.track[i];
      final rect = Rect.fromLTWH(c.col * cell, c.row * cell, cell, cell);
      final isStart = LudoColor.values.any((col) => col.startIndex == i);
      final safe = LudoGame.safeGlobalIndices.contains(i);

      Color fill = LudoTheme.pathCell;
      if (isStart) {
        final color = LudoColor.values.firstWhere((col) => col.startIndex == i);
        fill = LudoTheme.vivid(color);
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.6), const Radius.circular(2)),
        Paint()..color = fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.6), const Radius.circular(2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = LudoTheme.pathStroke,
      );

      if (safe && !isStart) {
        _drawStar(
          canvas,
          rect.center,
          cell * 0.28,
          LudoBoardGeometry.starColor(i),
        );
      }
      if (isStart) {
        final color = LudoColor.values.firstWhere((col) => col.startIndex == i);
        _drawEntryArrow(canvas, rect, color, cell);
      }
    }

    for (final entry in LudoBoardGeometry.homeStretch.entries) {
      final paint = Paint()..color = LudoTheme.vivid(entry.key);
      for (final c in entry.value) {
        final rect = Rect.fromLTWH(c.col * cell, c.row * cell, cell, cell);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(2)),
          paint,
        );
      }
    }

    _paintCenter(canvas, cell);
  }

  void _paintYard(
    Canvas canvas,
    double cell,
    LudoColor color,
    (int, int, int, int) bounds,
  ) {
    final (r0, c0, r1, c1) = bounds;
    final rect = Rect.fromLTWH(
      c0 * cell,
      r0 * cell,
      (c1 - c0 + 1) * cell,
      (r1 - r0 + 1) * cell,
    );
    final active = activeColors.contains(color);
    final base = LudoTheme.vivid(color);
    final radius = Radius.circular(cell * 0.55);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(cell * 0.12), radius),
      Paint()..color = active ? base : base.withValues(alpha: 0.28),
    );

    // Inner white nest
    final nest = rect.deflate(cell * 1.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(nest, Radius.circular(cell * 0.45)),
      Paint()..color = Colors.white.withValues(alpha: active ? 1 : 0.55),
    );

    // Empty slot rings
    for (final slot in LudoBoardGeometry.yardSlots[color]!) {
      final cx = (slot.col + 0.5) * cell;
      final cy = (slot.row + 0.5) * cell;
      canvas.drawCircle(
        Offset(cx, cy),
        cell * 0.32,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = base.withValues(alpha: active ? 0.35 : 0.15),
      );
    }

    if (!active) return;

    final label = playerLabels[color] ?? color.label;
    final pct = '${progressByColor[color] ?? 0}%';
    final nameStyle = GoogleFonts.nunito(
      fontSize: cell * 0.55,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1,
    );
    final pctStyle = GoogleFonts.nunito(
      fontSize: cell * 0.48,
      fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.92),
      height: 1,
    );

    // Name near outer edge of yard; % near opposite edge.
    final nameOffset = switch (color) {
      LudoColor.green ||
      LudoColor.yellow => Offset(rect.center.dx, rect.top + cell * 0.55),
      LudoColor.red ||
      LudoColor.blue => Offset(rect.center.dx, rect.bottom - cell * 0.55),
    };
    final pctOffset = switch (color) {
      LudoColor.green ||
      LudoColor.yellow => Offset(rect.center.dx, nest.bottom + cell * 0.45),
      LudoColor.red ||
      LudoColor.blue => Offset(rect.center.dx, nest.top - cell * 0.45),
    };

    _drawCenteredText(canvas, label, nameOffset, nameStyle);
    _drawCenteredText(canvas, pct, pctOffset, pctStyle);

    if (turn == color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(cell * 0.12), radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _paintCenter(Canvas canvas, double cell) {
    final cx = 7.5 * cell;
    final cy = 7.5 * cell;
    final left = 6 * cell;
    final top = 6 * cell;
    final right = 9 * cell;
    final bottom = 9 * cell;
    final tip = Offset(cx, cy);

    void tri(Offset a, Offset b, Color color) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    tri(
      Offset(left, top),
      Offset(right, top),
      LudoTheme.vivid(LudoColor.yellow),
    );
    tri(
      Offset(left, top),
      Offset(left, bottom),
      LudoTheme.vivid(LudoColor.green),
    );
    tri(
      Offset(left, bottom),
      Offset(right, bottom),
      LudoTheme.vivid(LudoColor.red),
    );
    tri(
      Offset(right, top),
      Offset(right, bottom),
      LudoTheme.vivid(LudoColor.blue),
    );
  }

  void _drawEntryArrow(Canvas canvas, Rect rect, LudoColor color, double cell) {
    // Direction: leave start continuing along the path (roughly).
    final angle = switch (color) {
      LudoColor.red => -math.pi / 2, // up
      LudoColor.green => 0.0, // right
      LudoColor.yellow => math.pi / 2, // down
      LudoColor.blue => math.pi, // left
    };
    final c = rect.center;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-cell * 0.12, -cell * 0.18)
      ..lineTo(cell * 0.18, 0)
      ..lineTo(-cell * 0.12, cell * 0.18)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * 0.42;
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) =>
      oldDelegate.turn != turn ||
      oldDelegate.activeColors.length != activeColors.length ||
      !oldDelegate.activeColors.containsAll(activeColors) ||
      oldDelegate.progressByColor.toString() != progressByColor.toString() ||
      oldDelegate.playerLabels.toString() != playerLabels.toString();
}
