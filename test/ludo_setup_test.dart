import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/ludo/ludo_config.dart';
import 'package:gaming_adda/games/ludo/ludo_logic.dart';
import 'package:gaming_adda/games/ludo/ludo_setup_screen.dart';
import 'package:gaming_adda/games/ludo/ludo_theme.dart';
import 'package:gaming_adda/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LudoConfig defaults', () {
    const config = LudoConfig();
    expect(config.playerCount, 4);
    expect(config.mode, LudoPlayMode.vsComputer);
    expect(config.humanColor, LudoColor.red);
    expect(config.soundEnabled, isTrue);
    expect(config.isVsComputer, isTrue);
  });

  testWidgets('Setup screen offers players, modes, and start', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LudoSetupScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('LUDO'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.image(const AssetImage(LudoTheme.iconAsset)), findsOneWidget);
    expect(find.text('Vs Computer'), findsOneWidget);
    expect(find.text('Local Hotseat'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Local Hotseat'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Local Hotseat'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('2'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('2'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Start Game'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Ludo'), findsOneWidget);
  });
}
