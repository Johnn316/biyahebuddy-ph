import 'package:biyahebuddy_ph/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shows emergency and main actions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.text('Tanong kay\nBuddy'), findsOneWidget);
    expect(find.text('Na-flag\nako'), findsOneWidget);
    expect(find.text('NAB 1234'), findsOneWidget);
  });
}
