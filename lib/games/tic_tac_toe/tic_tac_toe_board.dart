import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tic_tac_toe_logic.dart';
import 'tic_tac_toe_theme.dart';

class TicTacToeBoard extends StatelessWidget {
  const TicTacToeBoard({
    super.key,
    required this.game,
    required this.interactive,
    required this.onCellTap,
    this.placingIndex,
    this.showWinLine = false,
  });

  final TicTacToeGame game;
  final bool interactive;
  final ValueChanged<int> onCellTap;
  final int? placingIndex;
  final bool showWinLine;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final inset = size * 0.11;
          final gap = size * 0.02;
          final cellSize = (size - inset * 2 - gap * 2) / 3;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                TicTacToeTheme.boardFrame,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++) ...[
                      if (row > 0) SizedBox(height: gap),
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < 3; col++) ...[
                              if (col > 0) SizedBox(width: gap),
                              Expanded(
                                child: _BoardCell(
                                  index: row * 3 + col,
                                  mark: game.markAt(row * 3 + col),
                                  isWinning: game.winningLine?.contains(
                                        row * 3 + col,
                                      ) ??
                                      false,
                                  isPlacing: placingIndex == row * 3 + col,
                                  interactive: interactive &&
                                      game.markAt(row * 3 + col) == Mark.empty &&
                                      !game.isOver,
                                  onTap: () => onCellTap(row * 3 + col),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showWinLine && game.winningLine != null)
                _WinLineOverlay(
                  line: game.winningLine!,
                  inset: inset,
                  cellSize: cellSize,
                  gap: gap,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardCell extends StatefulWidget {
  const _BoardCell({
    required this.index,
    required this.mark,
    required this.isWinning,
    required this.isPlacing,
    required this.interactive,
    required this.onTap,
  });

  final int index;
  final Mark mark;
  final bool isWinning;
  final bool isPlacing;
  final bool interactive;
  final VoidCallback onTap;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.95 : 1.0;

    return GestureDetector(
      onTapDown: widget.interactive
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.interactive
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.interactive
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              TicTacToeTheme.cellEmpty,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            if (widget.isWinning)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.2, end: 0.55),
                duration: TicTacToeTheme.winLineDuration,
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: TicTacToeTheme.cellGlow.withValues(
                            alpha: value,
                          ),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (widget.mark != Mark.empty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('${widget.index}-${widget.mark}'),
                  tween: Tween(begin: widget.isPlacing ? 0.0 : 1.0, end: 1.0),
                  duration: widget.isPlacing
                      ? TicTacToeTheme.placeAnimationDuration
                      : Duration.zero,
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Image.asset(
                    TicTacToeTheme.markAsset(widget.mark),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WinLineOverlay extends StatelessWidget {
  const _WinLineOverlay({
    required this.line,
    required this.inset,
    required this.cellSize,
    required this.gap,
  });

  final List<int> line;
  final double inset;
  final double cellSize;
  final double gap;

  Offset _cellCenter(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final x = inset + col * (cellSize + gap) + cellSize / 2;
    final y = inset + row * (cellSize + gap) + cellSize / 2;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final a = _cellCenter(line[0]);
    final b = _cellCenter(line[2]);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final length = (b - a).distance + cellSize * 0.35;
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: TicTacToeTheme.winLineDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(mid.dx - length / 2, mid.dy - 18),
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: length * (0.35 + 0.65 * t),
                height: 36,
                child: Image.asset(
                  TicTacToeTheme.winLine,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
