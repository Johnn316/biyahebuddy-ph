import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/features/emergency/controllers/emergency_controller.dart';
import 'package:biyahebuddy_ph/features/emergency/screens/qr_exchange_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers.dart';

const _maps =
    'Lokasyon (GPS): 14.554700, 121.024400\n'
    'I-paste sa Google Maps o Waze para makita.';

/// Device without SIM / dialer: capability checks say no, actions throw
/// [SosUnavailable] with a user-facing message.
class LimitedSosService extends RecordingSosService {
  LimitedSosService({this.sms = false, this.call = false});

  final bool sms;
  final bool call;

  static const noDialer = 'Walang phone app sa device na ito.';
  static const noSms = 'Walang SIM — hindi makapag-text.';

  @override
  Future<bool> canSendSms() async => sms;

  @override
  Future<bool> canCall() async => call;

  @override
  Future<void> openDialer(String number) async =>
      throw const SosUnavailable(noDialer);

  @override
  Future<void> smsContacts(
    List<EmergencyContact> contacts,
    String message,
  ) async => throw const SosUnavailable(noSms);
}

/// Opens Home, then taps SOS once.
Future<RecordingSosService> openEmergency(
  WidgetTester tester, {
  Size logicalSize = const Size(412, 915),
  RecordingSosService? sosService,
}) async {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final sos = sosService ?? RecordingSosService();
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
    final first = sos.texts.single.message;
    expect(first, startsWith('BiyaheBuddy PH - SOS ALERT\n'));
    expect(
      first,
      contains(
        'Si Juan Dela Cruz (plate NAB 1234) ay naaksidente at humihingi ng '
        'tulong.\nMay sugatan.\n$_maps\n'
        'Sasakyan: Kotse | Blood type: O+\n',
      ),
    );
    expect(first, isNot(contains('null')));
    // No links: PH networks drop P2P SMS that contain URLs.
    expect(first, isNot(contains('http')));
    expect(find.text('Na-text si ${contacts[0].name}'), findsOneWidget);

    await tester.tap(find.byKey(const Key('injured-no')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('text-all')));
    await tester.pumpAndSettle();
    expect(sos.texts.last.phones, [for (final c in contacts) c.phone]);
    expect(sos.texts.last.message, contains('\nWalang sugatan.\n'));
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

  testWidgets('SosUnavailable message is shown when calling fails', (
    tester,
  ) async {
    // Says it can call, but the device has no dialer app (Wi-Fi tablet).
    await openEmergency(
      tester,
      sosService: LimitedSosService(sms: true, call: true),
    );
    await tester.tap(find.byKey(const Key('call-contact-0')));
    await tester.pump();
    expect(find.text(LimitedSosService.noDialer), findsOneWidget);
  });

  testWidgets('SosUnavailable message is shown when texting fails', (
    tester,
  ) async {
    await openEmergency(
      tester,
      sosService: LimitedSosService(sms: true, call: true),
    );
    await tester.tap(find.byKey(const Key('text-all')));
    await tester.pump();
    expect(find.text(LimitedSosService.noSms), findsOneWidget);
  });

  testWidgets('no SIM: text + call buttons greyed with a note; 911 still on', (
    tester,
  ) async {
    final sos = await openEmergency(tester, sosService: LimitedSosService());

    IconButton button(String key) => tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(IconButton),
      ),
    );
    expect(button('call-contact-0').onPressed, isNull);
    expect(button('text-contact-0').onPressed, isNull);
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('text-all')))
          .onPressed,
      isNull,
    );
    expect(
      find.textContaining('Hindi makapag-text o makatawag ang device na ito'),
      findsOneWidget,
    );

    // Hotlines: 911 stays enabled (works without SIM), others greyed.
    await scrollTo(tester, find.byKey(const Key('hotline-143')));
    expect(
      find.textContaining('Gumagana pa rin ang 911', skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('hotline-143')), warnIfMissed: false);
    await tester.pump();
    expect(find.text(LimitedSosService.noDialer), findsNothing); // disabled
    await scrollTo(tester, find.byKey(const Key('hotline-911')));
    await tester.tap(find.byKey(const Key('hotline-911')));
    await tester.pump();
    expect(find.text(LimitedSosService.noDialer), findsOneWidget); // tried

    // Big "Tumawag sa 911" also stays enabled.
    await scrollTo(tester, find.byKey(const Key('injured-yes')));
    await tester.tap(find.byKey(const Key('injured-yes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('call-911')), findsOneWidget);
    expect(sos.dialed, isEmpty); // LimitedSosService throws, never records
  });

  testWidgets('only SMS missing: call works, text greyed', (tester) async {
    final sos = await openEmergency(tester, sosService: _SmsOnlyMissing());
    expect(
      find.text(
        'Hindi makapag-text ang device na ito (walang SIM?). Tawagan na lang.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('call-contact-0')));
    await tester.pump();
    expect(sos.dialed, [FakeProfileRepository.sample.contacts[0].phone]);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const Key('text-contact-0')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  test('QR text has name, plate, license, insurer, policy', () {
    final p = FakeProfileRepository.sample;
    final text = qrExchangeText(p);
    for (final v in [p.name, p.plateNo, p.licenseNo, p.insurer!, p.policyNo!]) {
      expect(text, contains(v));
    }
  });

  test('SOS message: full profile, exact format', () {
    expect(
      buildSosMessage(
        (lat: 14.5547, lng: 121.0244),
        null,
        profile: FakeProfileRepository.sample,
        now: DateTime(2026, 10, 10, 7, 52),
      ),
      'BiyaheBuddy PH - SOS ALERT\n'
      'Si Juan Dela Cruz (plate NAB 1234) ay naaksidente at humihingi ng '
      'tulong.\n'
      '$_maps\n'
      'Sasakyan: Kotse | Blood type: O+\n'
      'Tawagan siya agad. Kung hindi sumasagot, tumawag sa 911.\n'
      '- Awtomatikong ipinadala ng BiyaheBuddy PH app (7:52 AM, Okt 10)',
    );
  });

  test('SOS message: no GPS, no profile → no empty fields, never "null"', () {
    final m = buildSosMessage(null, null, now: DateTime(2026, 10, 10, 19, 5));
    expect(
      m,
      'BiyaheBuddy PH - SOS ALERT\n'
      'Ang driver na ito ay naaksidente at humihingi ng tulong.\n'
      'Lokasyon: hindi makuha ang GPS. Tawagan siya para malaman kung nasaan '
      'siya.\n'
      'Tawagan siya agad. Kung hindi sumasagot, tumawag sa 911.\n'
      '- Awtomatikong ipinadala ng BiyaheBuddy PH app (7:05 PM, Okt 10)',
    );
    expect(m, isNot(contains('null')));
    expect(m, isNot(contains('Sasakyan')));
  });

  test('SOS message: empty name and blood type are skipped', () {
    const p = Profile(
      name: '  ',
      age: 30,
      plateNo: 'ABC 123',
      licenseNo: '',
      restrictionCode: '',
      vehicleType: 'Motorsiklo',
    );
    final m = buildSosMessage(null, true, profile: p);
    expect(m, contains('Ang driver na ito (plate ABC 123) ay naaksidente'));
    expect(m, contains('\nMay sugatan.\n'));
    expect(m, contains('\nSasakyan: Motorsiklo\n'));
    expect(m, isNot(contains('Blood type')));
  });
}

class _SmsOnlyMissing extends RecordingSosService {
  @override
  Future<bool> canSendSms() async => false;
}
