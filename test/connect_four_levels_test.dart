import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/connect_four/connect_four_ai.dart';
import 'package:gaming_adda/games/connect_four/connect_four_levels.dart';
import 'package:gaming_adda/games/connect_four/connect_four_levels_screen.dart';
import 'package:gaming_adda/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('difficulty curve grows monotonically over 365 levels', () {
    var lastDepth = 0;
    var lastRandomness = double.infinity;
    for (var level = 1; level <= ConnectFourLevels.maxLevel; level++) {
      final depth = ConnectFourLevels.depthFor(level);
      final randomness = ConnectFourLevels.randomnessFor(level);

      expect(depth, inInclusiveRange(1, 7), reason: 'level $level');
      expect(randomness, inInclusiveRange(0.0, 0.85), reason: 'level $level');
      expect(depth, greaterThanOrEqualTo(lastDepth), reason: 'level $level');
      expect(randomness, lessThanOrEqualTo(lastRandomness),
          reason: 'level $level');

      lastDepth = depth;
      lastRandomness = randomness;
    }

    expect(ConnectFourLevels.depthFor(1), 1);
    expect(ConnectFourLevels.depthFor(ConnectFourLevels.maxLevel), 7);
    expect(ConnectFourLevels.randomnessFor(1), closeTo(0.85, 0.001));
    expect(ConnectFourLevels.randomnessFor(ConnectFourLevels.maxLevel), 0);
  });

  test('tier names cover the whole range', () {
    expect(ConnectFourLevels.tierName(1), 'Tutorial');
    expect(ConnectFourLevels.tierName(120), 'Casual');
    expect(ConnectFourLevels.tierName(365), 'Grandmaster');
  });

  test('AI.forLevel applies the curve', () {
    final weak = ConnectFourAi.forLevel(1);
    final strong = ConnectFourAi.forLevel(365);
    expect(weak.depth, 1);
    expect(weak.randomMoveChance, greaterThan(0.8));
    expect(strong.depth, 7);
    expect(strong.randomMoveChance, 0);
  });

  test('beating a level unlocks the next one', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ConnectFourProgress.highestUnlocked(), 1);

    await ConnectFourProgress.completeLevel(1);
    expect(await ConnectFourProgress.highestUnlocked(), 2);

    // Replaying an old level never regresses progress.
    await ConnectFourProgress.completeLevel(1);
    expect(await ConnectFourProgress.highestUnlocked(), 2);

    // Final level caps at maxLevel.
    await ConnectFourProgress.completeLevel(ConnectFourLevels.maxLevel);
    expect(
      await ConnectFourProgress.highestUnlocked(),
      ConnectFourLevels.maxLevel,
    );
  });

  testWidgets('levels screen shows progress and locks future levels', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'connect_four_highest_unlocked': 3,
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConnectFourLevelsScreen(soundEnabled: false),
      ),
    );
    // The current-level tile pulses forever, so pumpAndSettle would never
    // settle; use bounded pumps instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('2 / 365 cleared'), findsOneWidget);

    // Completed tiles show a check, the current tile glows, future locked.
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);

    // Tapping a locked level does nothing.
    await tester.tap(find.byKey(const ValueKey('level-4')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LEVELS'), findsOneWidget);

    // Tapping the current level opens the play screen at that level.
    await tester.tap(find.byKey(const ValueKey('level-3')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('LEVEL 3'), findsOneWidget);
  });
}
