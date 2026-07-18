import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/sudoku/sudoku_levels.dart';
import 'package:gaming_adda/games/sudoku/sudoku_levels_screen.dart';
import 'package:gaming_adda/games/sudoku/sudoku_shape.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('board size grows across the campaign', () {
    expect(SudokuLevels.shapeFor(1), SudokuShape.four);
    expect(SudokuLevels.shapeFor(80), SudokuShape.four);
    expect(SudokuLevels.shapeFor(81), SudokuShape.six);
    expect(SudokuLevels.shapeFor(180), SudokuShape.six);
    expect(SudokuLevels.shapeFor(181), SudokuShape.nine);
    expect(SudokuLevels.shapeFor(365), SudokuShape.nine);
  });

  test('clue curve hardens within each size band', () {
    // 4×4 band
    expect(SudokuLevels.cluesFor(1), greaterThan(SudokuLevels.cluesFor(80)));
    // 6×6 band
    expect(SudokuLevels.cluesFor(81), greaterThan(SudokuLevels.cluesFor(180)));
    // 9×9 band
    expect(SudokuLevels.cluesFor(181), greaterThan(SudokuLevels.cluesFor(365)));

    var lastFour = 99;
    for (var level = 1; level <= SudokuLevels.fourEnd; level++) {
      final clues = SudokuLevels.cluesFor(level);
      final range = SudokuLevels.clueRangeFor(SudokuShape.four);
      expect(clues, inInclusiveRange(range.minClues, range.maxClues),
          reason: 'level $level');
      expect(clues, lessThanOrEqualTo(lastFour), reason: 'level $level');
      lastFour = clues;
    }
  });

  test('tier names cover the whole range', () {
    expect(SudokuLevels.tierName(1), 'Tutorial');
    expect(SudokuLevels.tierName(120), 'Casual');
    expect(SudokuLevels.tierName(365), 'Grandmaster');
    expect(SudokuLevels.progressLabel(1), '4×4 · Tutorial');
    expect(SudokuLevels.progressLabel(200), contains('9×9'));
  });

  test('beating a level unlocks the next one', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SudokuProgress.highestUnlocked(), 1);

    await SudokuProgress.completeLevel(1);
    expect(await SudokuProgress.highestUnlocked(), 2);

    await SudokuProgress.completeLevel(1);
    expect(await SudokuProgress.highestUnlocked(), 2);

    await SudokuProgress.completeLevel(2);
    expect(await SudokuProgress.highestUnlocked(), 3);
  });

  testWidgets('levels screen shows progress header', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SudokuLevelsScreen(soundEnabled: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('0 / 365 cleared'), findsOneWidget);
  });
}
