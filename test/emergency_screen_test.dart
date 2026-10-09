import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/features/emergency/controllers/emergency_controller.dart';
import 'package:biyahebuddy_ph/features/emergency/screens/qr_exchange_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers.dart';

const _maps = 'https://maps.google.com/?q=14.554700,121.024400';

/// Opens Home, then taps EMERGENCY once.
Future<RecordingSosService> openEmergency(
  WidgetTester tester, {
  Size logicalSize = const Size(412, 915),
}) async {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final sos = RecordingSosService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(FakeProfileRepository.sample),
        ),
        codingServiceProvider.overrideWithValue(
          const FixedCodingService(isCoding: false),
        ),
        sosServiceProvider.overrideWithValue(sos),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('home-emergency')));
  await tester.pumpAndSettle();
  return sos;
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one tap from Home, no dialog; first screen shows Ligtas ka ba '
      '+ contacts (small 360x640 phone)', (tester) async {
    await openEmergency(tester, logicalSize: const Size(360, 640));

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Ligtas ka ba?').hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('injured-yes')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('text-all')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('call-contact-0')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sections appear in the required order', (tester) async {
    await openEmergency(tester, logicalSize: const Size(412, 4000));
    double y(Finder f) => tester.getTopLeft(f).dy;

    final order = [
      find.text('Ligtas ka ba?'),
      find.byKey(const Key('text-all')),
      find.byKey(const Key('hotline-911')),
      find.byKey(const Key('check-0')),
      find.byKey(const Key('medical-card')),
      find.byKey(const Key('open-qr')),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(y(order[i]), greaterThan(y(order[i - 1])));
    }
  });

  testWidgets('May sugatan shows 911 first and dials it', (tester) async {
    final sos = await openEmergency(tester);
    expect(find.byKey(const Key('call-911')), findsNothing);

    await tester.tap(find.byKey(const Key('injured-yes')));
    await tester.pumpAndSettle();
    final call911 = find.byKey(const Key('call-911'));
    expect(call911, findsOneWidget);
    expect(
      tester.getTopLeft(call911).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('text-all'))).dy),
    );

    await tester.tap(call911);
    await tester.pumpAndSettle();
    expect(sos.dialed, ['911']);

    await tester.tap(find.byKey(const Key('injured-no')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('call-911')), findsNothing);
  });

  testWidgets('contacts: call, text one with GPS + status, text all', (
    tester,
  ) async {
    final sos = await openEmergency(tester);
    final contacts = FakeProfileRepository.sample.contacts;

    await tester.tap(find.byKey(const Key('call-contact-1')));
    await tester.pumpAndSettle();
    expect(sos.dialed, [contacts[1].phone]);

    await tester.tap(find.byKey(const Key('injured-yes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-contact-0')));
    await tester.pumpAndSettle();
    expect(sos.texts.single.phones, [contacts[0].phone]);
    expect(
      sos.texts.single.message,
      'Naaksidente ako. Lokasyon: $_maps. May sugatan',
    );
    expect(find.text('Na-text si ${contacts[0].name}'), findsOneWidget);

    await tester.tap(find.byKey(const Key('injured-no')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-all')));
    await tester.pumpAndSettle();
    expect(sos.texts.last.phones, [for (final c in contacts) c.phone]);
    expect(
      sos.texts.last.message,
      'Naaksidente ako. Lokasyon: $_maps. Ligtas ako',
    );
  });

  testWidgets('hotline row dials in one tap', (tester) async {
    final sos = await openEmergency(tester);
    final row = find.byKey(const Key('hotline-143'));
    await scrollTo(tester, row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(sos.dialed, ['143']);
  });

  testWidgets('checklist ticks and counts', (tester) async {
    await openEmergency(tester);
    Future<void> tick(int i) async {
      await scrollTo(tester, find.byKey(Key('check-$i')));
      await tester.tap(find.byKey(Key('check-$i')));
      await tester.pumpAndSettle();
    }

    expect(find.text('0/5', skipOffstage: false), findsOneWidget);
    await tick(0);
    await tick(1);
    expect(find.text('2/5', skipOffstage: false), findsOneWidget);
    await tick(0);
    expect(find.text('1/5', skipOffstage: false), findsOneWidget);
  });

  testWidgets('medical card + full-screen QR exchange', (tester) async {
    await openEmergency(tester);
    final p = FakeProfileRepository.sample;

    await scrollTo(tester, find.byKey(const Key('open-qr')));
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('${p.insurer} · Policy ${p.policyNo}'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-qr')));
    await tester.pumpAndSettle();
    expect(find.text('Ipa-scan sa kabilang driver'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tapos na'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.byKey(const Key('open-qr')), findsOneWidget); // back on screen
  });

  test('QR text has name, plate, license, insurer, policy', () {
    final p = FakeProfileRepository.sample;
    final text = qrExchangeText(p);
    for (final v in [p.name, p.plateNo, p.licenseNo, p.insurer!, p.policyNo!]) {
      expect(text, contains(v));
    }
  });

  test('SOS message without GPS or answer', () {
    expect(
      buildSosMessage(null, null),
      'Naaksidente ako. Lokasyon: hindi makuha ang GPS.',
    );
  });
}
