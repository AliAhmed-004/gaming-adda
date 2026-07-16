import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/casino/casino_play_screen.dart';
import 'package:gaming_adda/games/casino/casino_setup_screen.dart';

void main() {
  testWidgets('setup navigates to play screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CasinoSetupScreen()));

    expect(find.text('CARD MATCH'), findsOneWidget);
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(CasinoPlayScreen), findsOneWidget);
    expect(find.text('Card Match'), findsOneWidget);
  });
}
