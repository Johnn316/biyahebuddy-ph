import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/contracts/contracts.dart';
import 'sos_platform.dart';

/// User-facing SOS errors (Taglish). Shown as-is by the UI.
abstract final class SosMessages {
  static const noSimSms =
      'Walang SIM ang device na ito — hindi makapag-text o makatawag. '
      'Gamitin ang ibang phone o ipakita ang QR card.';
  static const noContacts =
      'Wala pang emergency contact. Idagdag muna sa Profile.';
  static const smsPermission =
      'Kailangan ng pahintulot sa SMS para ma-text ang emergency contacts. '
      'Payagan ito sa Settings.';
  static String smsFailed(List<String> numbers) =>
      'May SIM pero hindi naipadala ang text sa: ${numbers.join(', ')}. '
      'Tingnan ang signal o load, tapos subukan ulit.';
  static String noDialer(String number) =>
      'Walang app pantawag sa device na ito. Tumawag sa $number gamit ang '
      'ibang phone.';
}

/// Real SosService. Never crashes on devices without SIM, GPS fix or dialer:
/// location returns null, SMS/dialer throw [SosUnavailable] with a message.
class AndroidSosService implements SosService {
  AndroidSosService({
    required this.platform,
    required this.loadContacts,
    this.locationTimeout = const Duration(seconds: 15),
  });

  final SosPlatform platform;

  /// Emergency contacts from the saved Profile (for the volume trigger).
  final Future<List<EmergencyContact>> Function() loadContacts;
  final Duration locationTimeout;

  @override
  Future<bool> canSendSms() => _safe(platform.canSendSms, false);

  @override
  Future<bool> canCall() => _safe(platform.canCall, false);

  /// Best effort, never throws: SOS must still go out without coordinates.
  @override
  Future<({double lat, double lng})?> currentLocation() async {
    try {
      if (!await platform.requestLocationPermission()) return null;
      if (!await platform.locationServiceEnabled()) {
        return await platform.lastKnownPosition();
      }
      try {
        return await platform.currentPosition(locationTimeout);
      } on Object catch (e) {
        debugPrint('[Sos] no fresh fix ($e); using last known');
        return await platform.lastKnownPosition();
      }
    } on Object catch (e) {
      debugPrint('[Sos] location unavailable: $e');
      return null;
    }
  }

  @override
  Future<void> smsContacts(
    List<EmergencyContact> contacts,
    String message,
  ) async {
    final numbers = [
      for (final c in contacts)
        if (c.phone.trim().isNotEmpty) c.phone.trim(),
    ];
    if (numbers.isEmpty) throw const SosUnavailable(SosMessages.noContacts);
    if (!await canSendSms()) throw const SosUnavailable(SosMessages.noSimSms);
    if (!await _safe(platform.requestSmsPermission, false)) {
      throw const SosUnavailable(SosMessages.smsPermission);
    }
    List<String> failed;
    try {
      failed = await platform.sendSms(numbers, message);
    } on Object catch (e) {
      debugPrint('[Sos] sendSms error: $e');
      failed = numbers;
    }
    if (failed.isNotEmpty) throw SosUnavailable(SosMessages.smsFailed(failed));
  }

  /// Opens the dialer prefilled (Android never auto-calls 911). On a phone
  /// with no SIM the dialer still opens: emergency numbers can work there.
  @override
  Future<void> openDialer(String number) async {
    if (!await _safe(() => platform.canOpenDialer(number), false)) {
      throw SosUnavailable(SosMessages.noDialer(number));
    }
    try {
      await platform.openDialer(number);
    } on Object {
      throw SosUnavailable(SosMessages.noDialer(number));
    }
  }

  /// Starts the native volume-up SOS service. Permissions that are denied
  /// (SMS/phone on a Wi-Fi tablet) don't block it: it then explains in its
  /// notification what it skipped.
  @override
  Future<void> enableVolumeTrigger() async {
    await _safe(platform.requestTriggerPermissions, null);
    final contacts = await _safe(loadContacts, const <EmergencyContact>[]);
    await platform.enableTrigger(contacts);
  }

  Future<void> disableVolumeTrigger() => platform.disableTrigger();

  Future<bool> isVolumeTriggerOn() => _safe(platform.isTriggerOn, false);

  /// Starts the SOS countdown as if volume-up was pressed 5 times.
  Future<void> debugTrigger() => platform.debugTrigger();

  static Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } on Object catch (e) {
      debugPrint('[Sos] $e');
      return fallback;
    }
  }
}
