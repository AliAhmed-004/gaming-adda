import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_config.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_setup_screen.dart';
import 'package:gaming_adda/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TicTacToeConfig defaults to vs computer medium with sound on', () {
    const config = TicTacToeConfig();
    expect(config.mode, TicTacToePlayMode.vsComputer);
    expect(config.difficulty, TicTacToeAiDifficulty.medium);
    expect(config.soundEnabled, isTrue);
    expect(config.isVsComputer, isTrue);
  });

  test('TicTacToeConfig local mode flags', () {
    const config = TicTacToeConfig(
      mode: TicTacToePlayMode.localTwoPlayer,
      difficulty: TicTacToeAiDifficulty.hard,
      soundEnabled: false,
    );
    expect(config.isLocalTwoPlayer, isTrue);
    expect(config.isVsComputer, isFalse);
    expect(config.difficulty, TicTacToeAiDifficulty.hard);
    expect(config.soundEnabled, isFalse);
  });

  testWidgets('Setup screen offers modes, difficulty, and start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TicTacToeSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Vs Computer'), findsOneWidget);
    expect(find.text('2 Players'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('2 Players'));
    await tester.pump();

    expect(find.text('Easy'), findsNothing);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('New game'), findsOneWidget);
    expect(find.text("X's turn"), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
  });
}
