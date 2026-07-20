import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/connect_four/connect_four_config.dart';
import 'package:gaming_adda/games/connect_four/connect_four_play_screen.dart';
import 'package:gaming_adda/games/connect_four/connect_four_tutorial.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level 1 is the tutorial level', () {
    expect(ConnectFourTutorial.isTutorialLevel(1), isTrue);
    expect(ConnectFourTutorial.isTutorialLevel(2), isFalse);
    expect(ConnectFourTutorial.firstColumn, 3);
  });

  testWidgets('tutorial opens with how-to coach card', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConnectFourPlayScreen(
          config: ConnectFourConfig(
            mode: ConnectFourPlayMode.vsComputer,
            soundEnabled: false,
            level: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Drop a disc'), findsOneWidget);
    expect(find.textContaining('glowing column'), findsOneWidget);
  });
}
