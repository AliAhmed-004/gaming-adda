import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sudoku_logic.dart';

/// Skeuomorphic Sudoku board: raised tiles with bevels and soft shadows.
class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    super.key,
    required this.game,
    required this.interactive,
    required this.onCellTap,
    this.highlightCell,
    this.highlightDigit,
  });

  final SudokuGame game;
  final bool interactive;
  final void Function(int row, int col) onCellTap;

  /// Tutorial coach highlight on a specific cell.
  final SudokuCell? highlightCell;

  /// Tutorial coach highlight on a digit (shown via pad; board may glow matches).
  final int? highlightDigit;

  static const frameLight = Color(0xFF5EEAD4);
  static const frame = Color(0xFF0D9488);
  static const frameDark = Color(0xFF115E59);
  static const tileFace = Color(0xFFF8FAFC);
  static const tileGiven = Color(0xFFE2E8F0);
  static const tileSelected = Color(0xFFCCFBF1);
  static const tileConflict = Color(0xFFFECACA);
  static const gridLine = Color(0xFF334155);
  static const boxLine = Color(0xFF0F172A);
  static const digitGiven = Color(0xFF0F172A);
  static const digitUser = Color(0xFF0D9488);
  static const noteColor = Color(0xFF64748B);
  static const glow = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    final n = game.size;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: interactive
                    ? (details) {
                        final cell = side / n;
                        final col =
                            (details.localPosition.dx / cell).floor().clamp(
                                  0,
                                  n - 1,
                                );
                        final row =
                            (details.localPosition.dy / cell).floor().clamp(
                                  0,
                                  n - 1,
                                );
                        onCellTap(row, col);
                      }
                    : null,
                child: CustomPaint(
                  painter: _SudokuBoardPainter(
                    game: game,
                    highlightCell: highlightCell,
                    highlightDigit: highlightDigit,
                  ),
                  size: Size(side, side),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SudokuBoardPainter extends CustomPainter {
  _SudokuBoardPainter({
    required this.game,
    this.highlightCell,
    this.highlightDigit,
  });

  final SudokuGame game;
  final SudokuCell? highlightCell;
  final int? highlightDigit;

  @override
  void paint(Canvas canvas, Size size) {
    final n = game.size;
    final cell = size.width / n;
    final conflicts = game.conflictingCells();

    // Outer beveled frame.
    final frameRect = Offset.zero & size;
    final frameR = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(14),
    );
    canvas.drawRRect(
      frameR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SudokuBoard.frameLight,
            SudokuBoard.frame,
            SudokuBoard.frameDark,
          ],
        ).createShader(frameRect),
    );

    // Inset panel.
    final inset = frameRect.deflate(cell * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0B1220),
    );

    final boardOrigin = inset.topLeft;
    final boardSize = inset.width;
    final boardCell = boardSize / n;

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(
          boardOrigin.dx + c * boardCell,
          boardOrigin.dy + r * boardCell,
          boardCell,
          boardCell,
        );
        _paintTile(
          canvas,
          rect,
          row: r,
          col: c,
          conflicts: conflicts,
        );
      }
    }

    // Grid lines on top — thick at box boundaries (may differ for rows/cols).
    final linePaint = Paint()
      ..color = SudokuBoard.gridLine.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final boxPaint = Paint()
      ..color = SudokuBoard.boxLine
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i <= n; i++) {
      final thickV = i % game.boxCols == 0;
      final x = boardOrigin.dx + i * boardCell;
      canvas.drawLine(
        Offset(x, boardOrigin.dy),
        Offset(x, boardOrigin.dy + boardSize),
        thickV ? boxPaint : linePaint,
      );
    }
    for (var i = 0; i <= n; i++) {
      final thickH = i % game.boxRows == 0;
      final y = boardOrigin.dy + i * boardCell;
      canvas.drawLine(
        Offset(boardOrigin.dx, y),
        Offset(boardOrigin.dx + boardSize, y),
        thickH ? boxPaint : linePaint,
      );
    }
  }

  void _paintTile(
    Canvas canvas,
    Rect rect, {
    required int row,
    required int col,
    required Set<SudokuCell> conflicts,
  }) {
    final pad = rect.width * 0.06;
    final face = rect.deflate(pad);
    final isSelected =
        game.selectedRow == row && game.selectedCol == col;
    final isGiven = game.isGiven(row, col);
    final isConflict = conflicts.contains(SudokuCell(row, col));
    final isHighlight = highlightCell?.row == row &&
        highlightCell?.col == col;
    final digit = game.digitAt(row, col);
    final sameDigit = highlightDigit != null &&
        digit != 0 &&
        digit == highlightDigit;

    Color faceColor = isGiven ? SudokuBoard.tileGiven : SudokuBoard.tileFace;
    if (isConflict) {
      faceColor = SudokuBoard.tileConflict;
    } else if (isSelected || sameDigit) {
      faceColor = SudokuBoard.tileSelected;
    }

    // Soft drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        face.translate(0, face.height * 0.06),
        Radius.circular(face.width * 0.12),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    final rrect = RRect.fromRectAndRadius(
      face,
      Radius.circular(face.width * 0.12),
    );

    final light = Color.lerp(faceColor, Colors.white, 0.35)!;
    final dark = Color.lerp(faceColor, Colors.black, 0.18)!;
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, faceColor, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(face),
    );

    // Bevel edge highlight.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    if (isHighlight) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = SudokuBoard.glow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    if (digit != 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$digit',
          style: GoogleFonts.fredoka(
            fontSize: face.width * 0.58,
            fontWeight: FontWeight.w700,
            color: isGiven ? SudokuBoard.digitGiven : SudokuBoard.digitUser,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          face.center.dx - tp.width / 2,
          face.center.dy - tp.height / 2,
        ),
      );
      return;
    }

    final notes = game.notesAt(row, col);
    if (notes.isEmpty) return;

    final noteCols = game.boxCols;
    final noteRows = game.boxRows;
    final noteW = face.width / noteCols;
    final noteH = face.height / noteRows;
    for (final n in notes) {
      final i = n - 1;
      final nr = i ~/ noteCols;
      final nc = i % noteCols;
      if (nr >= noteRows) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: GoogleFonts.nunito(
            fontSize: math.min(noteW, noteH) * 0.55,
            fontWeight: FontWeight.w800,
            color: SudokuBoard.noteColor,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          face.left + nc * noteW + (noteW - tp.width) / 2,
          face.top + nr * noteH + (noteH - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuBoardPainter oldDelegate) => true;
}
