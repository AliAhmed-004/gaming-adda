import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/sudoku/sudoku_config.dart';
import 'package:gaming_adda/games/sudoku/sudoku_play_screen.dart';
import 'package:gaming_adda/games/sudoku/sudoku_tutorial.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level 1 is the tutorial level', () {
    expect(SudokuTutorial.isTutorialLevel(1), isTrue);
    expect(SudokuTutorial.isTutorialLevel(2), isFalse);
    expect(SudokuTutorial.needsContinue(SudokuTutorialStep.welcome), isTrue);
    expect(SudokuTutorial.needsContinue(SudokuTutorialStep.selectCell), isFalse);
  });

  testWidgets('tutorial opens with how-to coach card', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SudokuPlayScreen(
          config: SudokuConfig(
            mode: SudokuPlayMode.campaign,
            soundEnabled: false,
            level: 1,
          ),
        ),
      ),
    );
    // Allow puzzle generation.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pick a cell'), findsOneWidget);
    expect(find.textContaining('glowing empty cell'), findsOneWidget);
  });
}
