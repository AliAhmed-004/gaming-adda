import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/connect_four/connect_four_config.dart';
import 'package:gaming_adda/games/connect_four/connect_four_setup_screen.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConnectFourConfig defaults to vs computer with sound on', () {
    const config = ConnectFourConfig();
    expect(config.mode, ConnectFourPlayMode.vsComputer);
    expect(config.soundEnabled, isTrue);
    expect(config.isVsComputer, isTrue);
    expect(config.isLocalTwoPlayer, isFalse);
  });

  test('ConnectFourConfig local mode flags', () {
    const config = ConnectFourConfig(
      mode: ConnectFourPlayMode.localTwoPlayer,
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
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConnectFourSetupScreen(),
      ),
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

    expect(find.byTooltip('New game'), findsOneWidget);
    expect(find.text("Red's turn"), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Yellow'), findsOneWidget);
  });

  testWidgets('Vs Computer start opens the levels screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConnectFourSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Game'));
    // Bounded pumps: the levels screen's current tile pulses forever.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('0 / 365 cleared'), findsOneWidget);
  });
}
