/// Board geometry for classic / junior Sudoku variants.
class SudokuShape {
  const SudokuShape({
    required this.size,
    required this.boxRows,
    required this.boxCols,
  }) : assert(boxRows * boxCols == size);

  /// 4×4 grid with 2×2 boxes (digits 1–4).
  static const four = SudokuShape(size: 4, boxRows: 2, boxCols: 2);

  /// 6×6 grid with 2×3 boxes (digits 1–6).
  static const six = SudokuShape(size: 6, boxRows: 2, boxCols: 3);

  /// Standard 9×9 grid with 3×3 boxes (digits 1–9).
  static const nine = SudokuShape(size: 9, boxRows: 3, boxCols: 3);

  final int size;
  final int boxRows;
  final int boxCols;

  int get maxDigit => size;
  int get cellCount => size * size;

  String get label => '$size×$size';

  @override
  bool operator ==(Object other) =>
      other is SudokuShape &&
      other.size == size &&
      other.boxRows == boxRows &&
      other.boxCols == boxCols;

  @override
  int get hashCode => Object.hash(size, boxRows, boxCols);
}
