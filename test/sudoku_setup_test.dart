import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/sudoku/sudoku_config.dart';
import 'package:gaming_adda/games/sudoku/sudoku_setup_screen.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SudokuConfig defaults to campaign with sound on', () {
    const config = SudokuConfig();
    expect(config.mode, SudokuPlayMode.campaign);
    expect(config.soundEnabled, isTrue);
    expect(config.isCampaign, isTrue);
    expect(config.isFreePlay, isFalse);
  });

  test('SudokuConfig free play flags', () {
    const config = SudokuConfig(
      mode: SudokuPlayMode.freePlay,
      soundEnabled: false,
      difficulty: SudokuDifficulty.hard,
    );
    expect(config.isFreePlay, isTrue);
    expect(config.isCampaign, isFalse);
    expect(config.difficulty, SudokuDifficulty.hard);
    expect(config.soundEnabled, isFalse);
  });

  testWidgets('Setup screen offers modes, sound toggle, and start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SudokuSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Campaign'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Free Play'));
    await tester.pump();

    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Med'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);

    await tester.tap(find.text('Sound'));
    await tester.pump();
  });

  testWidgets('Campaign start opens the levels screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SudokuSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('0 / 365 cleared'), findsOneWidget);
  });
}
