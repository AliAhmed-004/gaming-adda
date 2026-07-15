import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/checkers/checkers_config.dart';
import 'package:gaming_adda/games/checkers/checkers_setup_screen.dart';
import 'package:gaming_adda/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CheckersConfig defaults to vs computer with sound on', () {
    const config = CheckersConfig();
    expect(config.mode, CheckersPlayMode.vsComputer);
    expect(config.soundEnabled, isTrue);
    expect(config.isVsComputer, isTrue);
    expect(config.isLocalTwoPlayer, isFalse);
  });

  test('CheckersConfig local mode flags', () {
    const config = CheckersConfig(
      mode: CheckersPlayMode.localTwoPlayer,
      soundEnabled: false,
    );
    expect(config.isLocalTwoPlayer, isTrue);
    expect(config.isVsComputer, isFalse);
    expect(config.soundEnabled, isFalse);
  });

  testWidgets('Setup screen offers modes, sound toggle, and start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const CheckersSetupScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Vs Computer'), findsOneWidget);
    expect(find.text('2 Players'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('2 Players'));
    await tester.pump();

    await tester.tap(find.text('Sound'));
    await tester.pump();

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('New game'), findsOneWidget);
    expect(find.text("Dark's turn"), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
  });
}
