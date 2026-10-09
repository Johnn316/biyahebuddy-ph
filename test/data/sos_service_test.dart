import 'dart:async';

import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/sos/android_sos_service.dart';
import 'package:biyahebuddy_ph/data/sos/sos_platform.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configurable fake device. Defaults = a phone with SIM, GPS and dialer.
class FakeDevice implements SosPlatform {
  bool sms = true;
  bool call = true;
  bool smsPermission = true;
  bool locationPermission = true;
  bool locationOn = true;
  bool freshFixTimesOut = false;
  LatLng? lastKnown = (lat: 14.0, lng: 121.0);
  bool dialer = true;
  List<String> failNumbers = const [];
  bool throwEverywhere = false;

  List<String>? sentTo;
  String? dialed;
  List<EmergencyContact>? enabledWith;

  void _maybeThrow() {
    if (throwEverywhere) throw StateError('platform channel broke');
  }

  @override
  Future<bool> canSendSms() async {
    _maybeThrow();
    return sms;
  }

  @override
  Future<bool> canCall() async {
    _maybeThrow();
    return call;
  }

  @override
  Future<bool> requestSmsPermission() async => smsPermission;

  @override
  Future<List<String>> sendSms(List<String> numbers, String message) async {
    sentTo = numbers;
    return numbers.where(failNumbers.contains).toList();
  }

  @override
  Future<bool> locationServiceEnabled() async => locationOn;

  @override
  Future<bool> requestLocationPermission() async {
    _maybeThrow();
    return locationPermission;
  }

  @override
  Future<LatLng> currentPosition(Duration timeout) async {
    if (freshFixTimesOut) throw TimeoutException('no fix', timeout);
    return (lat: 14.5547, lng: 121.0244);
  }

  @override
  Future<LatLng?> lastKnownPosition() async => lastKnown;

  @override
  Future<bool> canOpenDialer(String number) async => dialer;

  @override
  Future<void> openDialer(String number) async => dialed = number;

  @override
  Future<void> requestTriggerPermissions() async => _maybeThrow();

  @override
  Future<void> enableTrigger(List<EmergencyContact> contacts) async =>
      enabledWith = contacts;

  @override
  Future<void> disableTrigger() async {}

  @override
  Future<bool> isTriggerOn() async => enabledWith != null;

  @override
  Future<void> debugTrigger() async {}
}

const _maria = EmergencyContact(name: 'Maria', phone: '09171234567');
const _pedro = EmergencyContact(name: 'Pedro', phone: '09981234567');

void main() {
  late FakeDevice device;
  late AndroidSosService sos;

  setUp(() {
    device = FakeDevice();
    sos = AndroidSosService(
      platform: device,
      loadContacts: () async => [_maria],
    );
  });

  Matcher unavailable(String messagePart) => throwsA(
    isA<SosUnavailable>().having(
      (e) => e.message,
      'message',
      contains(messagePart),
    ),
  );

  group('Wi-Fi tablet, no SIM', () {
    setUp(() {
      device
        ..sms = false
        ..call = false;
    });

    test('capabilities report false', () async {
      expect(await sos.canSendSms(), isFalse);
      expect(await sos.canCall(), isFalse);
    });

    test('SMS throws a clear no-SIM message and sends nothing', () async {
      await expectLater(
        sos.smsContacts([_maria], 'SOS'),
        unavailable('Walang SIM'),
      );
      expect(device.sentTo, isNull);
    });

    test('dialer still opens if the device has one (911 may work)', () async {
      await sos.openDialer('911');
      expect(device.dialed, '911');
    });

    test('volume trigger still enables', () async {
      await sos.enableVolumeTrigger();
      expect(device.enabledWith, [_maria]);
    });
  });

  test('no dialer app → clear message with the number', () async {
    device.dialer = false;
    await expectLater(sos.openDialer('911'), unavailable('Tumawag sa 911'));
  });

  group('location', () {
    test('fresh fix via LocationManager', () async {
      expect(await sos.currentLocation(), (lat: 14.5547, lng: 121.0244));
    });

    test('timeout → last known position', () async {
      device.freshFixTimesOut = true;
      expect(await sos.currentLocation(), (lat: 14.0, lng: 121.0));
    });

    test('location services off → last known, no crash', () async {
      device.locationOn = false;
      expect(await sos.currentLocation(), (lat: 14.0, lng: 121.0));
    });

    test('off and nothing cached → null', () async {
      device
        ..locationOn = false
        ..lastKnown = null;
      expect(await sos.currentLocation(), isNull);
    });

    test('permission denied → null, no crash', () async {
      device.locationPermission = false;
      expect(await sos.currentLocation(), isNull);
    });
  });

  group('SMS with SIM', () {
    test('sends to every contact', () async {
      await sos.smsContacts([_maria, _pedro], 'SOS');
      expect(device.sentTo, [_maria.phone, _pedro.phone]);
    });

    test('some numbers fail → names them (SIM present but not sent)', () async {
      device.failNumbers = [_pedro.phone];
      await expectLater(
        sos.smsContacts([_maria, _pedro], 'SOS'),
        unavailable('hindi naipadala ang text sa: ${_pedro.phone}'),
      );
    });

    test('SMS permission denied → clear message', () async {
      device.smsPermission = false;
      await expectLater(
        sos.smsContacts([_maria], 'SOS'),
        unavailable('pahintulot sa SMS'),
      );
    });

    test('no contacts → tells user to add one', () async {
      await expectLater(
        sos.smsContacts([], 'SOS'),
        unavailable('emergency contact'),
      );
    });
  });

  test('broken platform channel never crashes the checks', () async {
    device.throwEverywhere = true;
    expect(await sos.canSendSms(), isFalse);
    expect(await sos.currentLocation(), isNull);
    await expectLater(
      sos.smsContacts([_maria], 'SOS'),
      unavailable('Walang SIM'),
    );
    await sos.enableVolumeTrigger(); // permission request failure ignored
    expect(device.enabledWith, [_maria]);
  });
}
