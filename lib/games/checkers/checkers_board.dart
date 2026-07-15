import 'package:flutter/material.dart';

import 'checkers_logic.dart';

class CheckersBoard extends StatelessWidget {
  const CheckersBoard({
    super.key,
    required this.game,
    required this.selected,
    required this.targets,
    required this.interactive,
    required this.onSquareTap,
  });

  final CheckersGame game;
  final Square? selected;
  final Set<Square> targets;
  final bool interactive;
  final ValueChanged<Square> onSquareTap;

  static const _lightSq = Color(0xFF2A3441);
  static const _darkSq = Color(0xFF1A222C);
  static const _highlight = Color(0xFF2DD4BF);
  static const _playerPiece = Color(0xFF0F766E);
  static const _playerRim = Color(0xFF5EEAD4);
  static const _aiPiece = Color(0xFFE7E5E4);
  static const _aiRim = Color(0xFFA8A29E);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth / 8;
              return Column(
                children: List.generate(8, (row) {
                  return Row(
                    children: List.generate(8, (col) {
                      final square = Square(row, col);
                      return SizedBox(
                        width: size,
                        height: size,
                        child: _SquareCell(
                          square: square,
                          piece: game.pieceAt(square),
                          selected: selected == square,
                          isTarget: targets.contains(square),
                          interactive: interactive,
                          onTap: () => onSquareTap(square),
                        ),
                      );
                    }),
                  );
                }),
              );
            },
          ),
        ),
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
    final isDark = square.isDarkSquare;
    final bg = isDark ? CheckersBoard._darkSq : CheckersBoard._lightSq;

    return Material(
      color: bg,
      child: InkWell(
        onTap: interactive ? onTap : null,
        child: Stack(
          children: [
            if (selected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CheckersBoard._highlight, width: 3),
                ),
              ),
            if (isTarget)
              Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: CheckersBoard._highlight.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (!piece.isEmpty) Center(child: _PieceToken(piece: piece)),
          ],
        ),
      ),
    );
  }
}

class _PieceToken extends StatelessWidget {
  const _PieceToken({required this.piece});

  final Piece piece;

  @override
  Widget build(BuildContext context) {
    final isDark = piece.isDark;
    final fill = isDark ? CheckersBoard._playerPiece : CheckersBoard._aiPiece;
    final rim = isDark ? CheckersBoard._playerRim : CheckersBoard._aiRim;

    return FractionallySizedBox(
      widthFactor: 0.72,
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: rim, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: piece.isKing
            ? Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFFCCFBF1)
                    : const Color(0xFF44403C),
              )
            : null,
      ),
    );
  }
}
