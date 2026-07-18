import 'package:flutter/material.dart';

import 'checkers_logic.dart';
import 'checkers_theme.dart';

class CapturedGoti {
  const CapturedGoti({required this.square, required this.piece});

  final Square square;
  final Piece piece;
}

class CheckersBoardAnimation {
  const CheckersBoardAnimation({
    required this.id,
    required this.from,
    required this.to,
    required this.movingPiece,
    required this.capturedPieces,
  });

  final int id;
  final Square from;
  final Square to;
  final Piece movingPiece;
  final List<CapturedGoti> capturedPieces;
}

class CheckersBoard extends StatelessWidget {
  const CheckersBoard({
    super.key,
    required this.game,
    required this.selected,
    required this.targets,
    required this.animation,
    required this.interactive,
    required this.onSquareTap,
  });

  final CheckersGame game;
  final Square? selected;
  final Set<Square> targets;
  final CheckersBoardAnimation? animation;
  final bool interactive;
  final ValueChanged<Square> onSquareTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CheckersTheme.frameHighlight, CheckersTheme.frame],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth / 8;
                final hiddenSquares = <Square>{
                  if (animation != null) animation!.from,
                  if (animation != null) ...animation!.capturedPieces.map((c) => c.square),
                };
                return Stack(
                  children: [
                    Column(
                      children: List.generate(8, (row) {
                        return Row(
                          children: List.generate(8, (col) {
                            final square = Square(row, col);
                            return SizedBox(
                              width: size,
                              height: size,
                              child: _SquareCell(
                                square: square,
                                piece: hiddenSquares.contains(square)
                                    ? Piece.empty
                                    : game.pieceAt(square),
                                selected: selected == square,
                                isTarget: targets.contains(square),
                                interactive: interactive,
                                onTap: () => onSquareTap(square),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                    if (animation != null)
                      _MoveOverlay(
                        animation: animation!,
                        tileSize: size,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveOverlay extends StatelessWidget {
  const _MoveOverlay({required this.animation, required this.tileSize});

  final CheckersBoardAnimation animation;
  final double tileSize;

  Offset _offsetFor(Square square) {
    return Offset(square.col * tileSize, square.row * tileSize);
  }

  @override
  Widget build(BuildContext context) {
    final start = _offsetFor(animation.from);
    final end = _offsetFor(animation.to);

    return IgnorePointer(
      child: Stack(
        children: [
          for (final captured in animation.capturedPieces)
            Positioned(
              left: captured.square.col * tileSize,
              top: captured.square.row * tileSize,
              width: tileSize,
              height: tileSize,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('capture-${animation.id}-${captured.square}'),
                tween: Tween<double>(begin: 1, end: 0),
                duration: CheckersTheme.captureAnimationDuration,
                curve: Curves.easeInCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0, 1),
                    child: Transform.scale(
                      scale: 0.88 + (0.12 * value),
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: _GotiSprite(
                    piece: captured.piece,
                    selected: false,
                    animatedGlow: false,
                  ),
                ),
              ),
            ),
          TweenAnimationBuilder<Offset>(
            key: ValueKey('move-${animation.id}'),
            tween: Tween<Offset>(begin: start, end: end),
            duration: CheckersTheme.moveAnimationDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, offset, child) {
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                width: tileSize,
                height: tileSize,
                child: child!,
              );
            },
            child: Center(
              child: _GotiSprite(
                piece: animation.movingPiece,
                selected: false,
                animatedGlow: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareCell extends StatelessWidget {
  const _SquareCell({
    required this.square,
    required this.piece,
    required this.selected,
    required this.isTarget,
    required this.interactive,
    required this.onTap,
  });

  final Square square;
  final Piece piece;
  final bool selected;
  final bool isTarget;
  final bool interactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: interactive ? onTap : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BoardTile(isDark: square.isDarkSquare),
            if (isTarget)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.38,
                  heightFactor: 0.38,
                  child: Image.asset(
                    CheckersTheme.gotiTarget,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            if (!piece.isEmpty)
              Center(child: _GotiSprite(piece: piece, selected: selected)),
          ],
        ),
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final top = isDark ? CheckersTheme.tileDarkTop : CheckersTheme.tileLightTop;
    final bottom =
        isDark ? CheckersTheme.tileDarkBottom : CheckersTheme.tileLightBottom;
    final bevel =
        isDark ? CheckersTheme.tileDarkBevel : CheckersTheme.tileLightBevel;
    final shadow =
        isDark ? CheckersTheme.tileDarkShadow : CheckersTheme.tileLightShadow;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        border: Border(
          top: BorderSide(color: bevel.withValues(alpha: 0.55), width: 1),
          left: BorderSide(color: bevel.withValues(alpha: 0.45), width: 1),
          bottom: BorderSide(color: shadow.withValues(alpha: 0.9), width: 1),
          right: BorderSide(color: shadow.withValues(alpha: 0.75), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                top.withValues(alpha: 0.92),
                bottom.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: bevel.withValues(alpha: 0.18),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _GotiSprite extends StatelessWidget {
  const _GotiSprite({
    required this.piece,
    required this.selected,
    this.animatedGlow = false,
  });

  final Piece piece;
  final bool selected;
  final bool animatedGlow;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: animatedGlow
          ? CheckersTheme.moveAnimationDuration
          : CheckersTheme.glowAnimationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        final effectiveScale = selected ? 1.0 + (0.08 * progress) : 1.0;
        final glowAlpha = selected ? 0.85 * progress : 0.0;
        final outerGlowAlpha = selected ? 0.35 * progress : 0.0;
        return Transform.scale(
          scale: effectiveScale,
          child: FractionallySizedBox(
            widthFactor: 0.92,
            heightFactor: 0.92,
            child: AnimatedContainer(
              duration: CheckersTheme.glowAnimationDuration,
              curve: Curves.easeOutCubic,
              decoration: selected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: CheckersTheme.selectedGlow.withValues(
                            alpha: glowAlpha,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: CheckersTheme.selectedGlow.withValues(
                            alpha: outerGlowAlpha,
                          ),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: child,
            ),
          ),
        );
      },
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1,
        child: Image.asset(
          CheckersTheme.gotiAsset(piece),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
