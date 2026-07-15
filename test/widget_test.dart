import 'package:flutter_test/flutter_test.dart';

import 'package:gaming_adda/main.dart';

void main() {
  testWidgets('Store home shows brand and featured section', (tester) async {
    await tester.pumpWidget(const GamingAddaApp());
    await tester.pump();

    expect(find.text('Gaming Adda'), findsOneWidget);
    expect(find.text('Popular games'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
  });
}
