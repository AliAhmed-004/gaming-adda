import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'connect_four_logic.dart';

/// Skeuomorphic Connect 4 board: discs drop with a bounce behind a beveled
/// frame with punched holes, drawn with radial gradients for a 3D look.
///
/// Layout is (rows + 1) cells tall: the extra top row is the "drop zone"
/// where the hover ghost floats and falling discs first appear.
class ConnectFourBoard extends StatelessWidget {
  const ConnectFourBoard({
    super.key,
    required this.game,
    required this.interactive,
    required this.onColumnTap,
    this.hoverColumn,
    this.onHoverColumn,
    this.highlightColumn,
    this.allowedColumns,
  });

  final ConnectFourGame game;
  final bool interactive;
  final ValueChanged<int> onColumnTap;
  final int? hoverColumn;
  final ValueChanged<int?>? onHoverColumn;

  /// Soft glow on a column (tutorial coach mark).
  final int? highlightColumn;

  /// When non-null, only these columns accept taps.
  final Set<int>? allowedColumns;

  static const frameLight = Color(0xFF3B82F6);
  static const frame = Color(0xFF2563EB);
  static const frameDark = Color(0xFF1E3A8A);
  static const backPanel = Color(0xFF0B1120);
  static const redDisc = Color(0xFFE11D48);
  static const yellowDisc = Color(0xFFF59E0B);
  static const winGlow = Color(0xFF34D399);

  int get _discCount {
    var n = 0;
    for (var r = 0; r < ConnectFourGame.rows; r++) {
      for (var c = 0; c < ConnectFourGame.cols; c++) {
        if (!game.discAt(r, c).isEmpty) n++;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    const cols = ConnectFourGame.cols;
    const rows = ConnectFourGame.rows;

    return AspectRatio(
      aspectRatio: cols / (rows + 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / cols;
          final dropZone = cell;
          final moveCount = _discCount;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating ghost disc above the hovered column.
              if (interactive &&
                  hoverColumn != null &&
                  game.canDrop(hoverColumn!))
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: hoverColumn! * cell,
                  top: 0,
                  width: cell,
                  height: cell,
                  child: Padding(
                    padding: EdgeInsets.all(cell * 0.10),
                    child: Opacity(
                      opacity: 0.85,
                      child: Disc3D(color: _discColor(game.turn)),
                    ),
                  ),
                ),

              // Board: back panel, discs, then the punched frame on top.
              Positioned(
                top: dropZone,
                left: 0,
                right: 0,
                bottom: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(cell * 0.28),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [backPanel, Color(0xFF050810)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (var r = 0; r < rows; r++)
                      for (var c = 0; c < cols; c++)
                        if (!game.discAt(r, c).isEmpty)
                          _positionedDisc(r, c, cell, moveCount),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _FramePainter()),
                      ),
                    ),
                    if (game.winner != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _WinLinePainter(game.winningLine),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tutorial column glow (behind the frame stack, above background).
              if (highlightColumn != null)
                Positioned(
                  left: highlightColumn! * cell,
                  top: dropZone,
                  width: cell,
                  bottom: 0,
                  child: IgnorePointer(
                    child: _PulsingColumnGlow(width: cell),
                  ),
                ),

              // Transparent tap/hover strips spanning the full height.
              Row(
                children: List.generate(cols, (col) {
                  final allowed = allowedColumns == null ||
                      allowedColumns!.contains(col);
                  final canTap =
                      interactive && allowed && game.canDrop(col);
                  return Expanded(
                    child: MouseRegion(
                      cursor: canTap
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      onEnter: (_) => onHoverColumn?.call(col),
                      onExit: (_) => onHoverColumn?.call(null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: canTap ? () => onColumnTap(col) : null,
                        child: Semantics(
                          button: canTap,
                          label: highlightColumn == col
                              ? 'Tutorial column ${col + 1}, tap here'
                              : 'Column ${col + 1}',
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positionedDisc(int row, int col, double cell, int moveCount) {
    final isLast = game.lastMove == Cell(row, col);
    final isWinning = game.winningLine.contains(Cell(row, col));
    final dimmed = game.winner != null && !isWinning;

    final disc = Padding(
      padding: EdgeInsets.all(cell * 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? 0.35 : 1,
        child: Disc3D(
          color: _discColor(game.discAt(row, col)),
          glow: isWinning,
        ),
      ),
    );

    if (!isLast) {
      return Positioned(
        left: col * cell,
        top: row * cell,
        width: cell,
        height: cell,
        child: disc,
      );
    }

    // Newest disc falls from the drop zone and bounces into place.
    final fallFrom = -cell;
    final fallTo = row * cell;
    return TweenAnimationBuilder<double>(
      key: ValueKey('drop-$moveCount'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 120 * (row + 2)),
      curve: Curves.bounceOut,
      builder: (context, t, child) {
        return Positioned(
          left: col * cell,
          top: fallFrom + (fallTo - fallFrom) * t,
          width: cell,
          height: cell,
          child: child!,
        );
      },
      child: disc,
    );
  }

  static Color _discColor(Disc disc) =>
      disc == Disc.red ? redDisc : yellowDisc;
}

/// Soft pulsing highlight used by the tutorial coach mark.
class _PulsingColumnGlow extends StatefulWidget {
  const _PulsingColumnGlow({required this.width});

  final double width;

  @override
  State<_PulsingColumnGlow> createState() => _PulsingColumnGlowState();
}

class _PulsingColumnGlowState extends State<_PulsingColumnGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ConnectFourBoard.yellowDisc.withValues(alpha: 0.35),
              ConnectFourBoard.yellowDisc.withValues(alpha: 0.08),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ConnectFourBoard.yellowDisc.withValues(alpha: 0.20 + 0.28 * t),
                ConnectFourBoard.yellowDisc.withValues(alpha: 0.05 + 0.10 * t),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: ConnectFourBoard.yellowDisc.withValues(alpha: 0.35 * t),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A glossy game piece: radial-gradient body, darker rim ridge, and an
/// offset specular highlight so it reads as a 3D checker.
class Disc3D extends StatelessWidget {
  const Disc3D({super.key, required this.color, this.glow = false});

  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final light =
        hsl.withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
    final edge =
        hsl.withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0)).toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.15,
          colors: [light, color, dark, edge],
          stops: const [0.0, 0.45, 0.85, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          if (glow)
            BoxShadow(
              color: ConnectFourBoard.winGlow.withValues(alpha: 0.9),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
        border: glow
            ? Border.all(color: ConnectFourBoard.winGlow, width: 2.5)
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final s = c.maxWidth;
          return Stack(
            children: [
              // Inner ridge, like a stacked checker.
              Center(
                child: Container(
                  width: s * 0.62,
                  height: s * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dark.withValues(alpha: 0.55),
                      width: s * 0.035,
                    ),
                  ),
                ),
              ),
              // Specular highlight.
              Positioned(
                left: s * 0.20,
                top: s * 0.12,
                child: Container(
                  width: s * 0.30,
                  height: s * 0.18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints the blue front frame with punched holes (even-odd fill), bevel
/// strokes, and inner hole shading so empty slots look recessed.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / ConnectFourGame.cols;
    final holeR = cell * 0.38;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.28));

    final framePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(rrect);
    for (var r = 0; r < ConnectFourGame.rows; r++) {
      for (var c = 0; c < ConnectFourGame.cols; c++) {
        framePath.addOval(
          Rect.fromCircle(center: _holeCenter(r, c, cell), radius: holeR),
        );
      }
    }

    canvas.drawPath(
      framePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ConnectFourBoard.frameLight,
            ConnectFourBoard.frame,
            ConnectFourBoard.frameDark,
          ],
          stops: [0.0, 0.35, 1.0],
        ).createShader(rect),
    );

    // Outer bevel: light top edge, dark bottom edge.
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.35),
          ],
        ).createShader(rect),
    );

    // Hole rims: dark inner shadow at the top, light lip at the bottom.
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.055
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.45);
    final lipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.045
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);

    for (var r = 0; r < ConnectFourGame.rows; r++) {
      for (var c = 0; c < ConnectFourGame.cols; c++) {
        final holeRect = Rect.fromCircle(
          center: _holeCenter(r, c, cell),
          radius: holeR - cell * 0.02,
        );
        canvas.drawArc(holeRect, math.pi * 1.15, math.pi * 0.7, false,
            shadowPaint);
        canvas.drawArc(holeRect, math.pi * 0.15, math.pi * 0.7, false,
            lipPaint);
      }
    }
  }

  Offset _holeCenter(int row, int col, double cell) =>
      Offset(col * cell + cell / 2, row * cell + cell / 2);

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

/// Draws a glowing line through the four winning discs.
class _WinLinePainter extends CustomPainter {
  _WinLinePainter(this.line);

  final List<Cell> line;

  @override
  void paint(Canvas canvas, Size size) {
    if (line.length < 2) return;
    final cell = size.width / ConnectFourGame.cols;

    Offset center(Cell c) =>
        Offset(c.col * cell + cell / 2, c.row * cell + cell / 2);

    final sorted = [...line]..sort(
        (a, b) => (a.row + a.col * 10).compareTo(b.row + b.col * 10));
    final start = center(sorted.first);
    final end = center(sorted.last);

    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = ConnectFourBoard.winGlow.withValues(alpha: 0.35)
        ..strokeWidth = cell * 0.22
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = cell * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WinLinePainter oldDelegate) => oldDelegate.line != line;
}
