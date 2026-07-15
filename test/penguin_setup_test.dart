import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/penguin_brothers/penguin_setup_screen.dart';

void main() {
  testWidgets('Penguin setup shows modes and start', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PenguinSetupScreen()));
    await tester.pump();

    expect(find.text('Penguin Brothers'), findsWidgets);
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('AI Partner'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
