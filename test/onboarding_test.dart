import 'dart:convert';

import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
}

Future<void> pickDropdown(
  WidgetTester tester,
  String key,
  String option,
) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('profile-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch: download → profile → home, saved to storage', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    usePhoneScreen(tester);
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // (a) Model download.
    expect(
      find.textContaining('Isang beses lang kailangan ng internet'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('model-continue')), findsNothing);
    await tester.tap(find.byKey(const Key('model-download')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Dina-download'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('model-continue')));
    await tester.pumpAndSettle();

    // (b) Profile: empty submit shows validation errors and stays here.
    expect(find.text('Ang iyong profile'), findsOneWidget);
    await submit(tester);
    expect(find.text('Kailangan ito'), findsWidgets);
    expect(find.text('Ang iyong profile'), findsOneWidget);

    await enter(tester, 'field-name', 'Ana Santos');
    await enter(tester, 'field-age', '29');
    await enter(tester, 'field-license', 'n02-11-222333');
    await enter(tester, 'field-restriction', 'b');
    await enter(tester, 'field-plate', 'abc 1235');
    await pickDropdown(tester, 'field-vehicle', 'Motorsiklo');
    await enter(tester, 'field-contact-name-0', 'Nanay');
    await enter(tester, 'field-contact-phone-0', '12345');
    await submit(tester);
    expect(find.text('Hal. 09171234567'), findsOneWidget); // bad phone
    await enter(tester, 'field-contact-phone-0', '0917 123 4567');

    // Add then remove a second contact.
    await tester.ensureVisible(find.byKey(const Key('add-contact')));
    await tester.tap(find.byKey(const Key('add-contact')));
    await tester.pumpAndSettle();
    expect(find.text('Contact 2'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('remove-contact-1')));
    await tester.tap(find.byKey(const Key('remove-contact-1')));
    await tester.pumpAndSettle();
    expect(find.text('Contact 2'), findsNothing);

    await submit(tester);

    // Home with the new plate.
    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.text('ABC 1235'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(prefs.getString(FakeProfileRepository.prefsKey)!)
            as Map<String, dynamic>;
    expect(saved['name'], 'Ana Santos');
    expect(saved['vehicle_type'], 'Motorsiklo');
    expect(saved['contacts'], [
      {'name': 'Nanay', 'phone': '09171234567'},
    ]);
  });

  testWidgets('second launch with saved profile skips onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FakeProfileRepository.prefsKey: jsonEncode(
        FakeProfileRepository.sample.toJson(),
      ),
    });
    usePhoneScreen(tester);
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.textContaining('Isang beses lang'), findsNothing);
  });
}
