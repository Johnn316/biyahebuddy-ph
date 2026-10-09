import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/contracts/contracts.dart';

typedef LatLng = ({double lat, double lng});

/// Everything SOS needs from the device. The real one talks to Android; tests
/// use a fake to simulate no SIM, location off, no dialer, etc.
abstract interface class SosPlatform {
  Future<bool> canSendSms();
  Future<bool> canCall();
  Future<bool> requestSmsPermission();

  /// Sends [message] to each number via SmsManager. Returns the numbers that
  /// failed (empty = all sent).
  Future<List<String>> sendSms(List<String> numbers, String message);

  Future<bool> locationServiceEnabled();
  Future<bool> requestLocationPermission();

  /// A fresh fix from Android LocationManager (never Google fused location).
  /// Throws on timeout.
  Future<LatLng> currentPosition(Duration timeout);
  Future<LatLng?> lastKnownPosition();

  Future<bool> canOpenDialer(String number);
  Future<void> openDialer(String number);

  /// Asks for notification / location / SMS / phone permissions (best effort).
  Future<void> requestTriggerPermissions();
  Future<void> enableTrigger(List<EmergencyContact> contacts);
  Future<void> disableTrigger();
  Future<bool> isTriggerOn();
  Future<void> debugTrigger();
}

/// Android implementation: MethodChannel to Kotlin (`.../sos/`), geolocator
/// forced onto LocationManager (works without Google Play Services, e.g.
/// Huawei), url_launcher for the dialer, permission_handler for permissions.
class ChannelSosPlatform implements SosPlatform {
  static const _channel = MethodChannel('ph.biyahebuddy/sos');

  @override
  Future<bool> canSendSms() async =>
      await _channel.invokeMethod<bool>('canSendSms') ?? false;

  @override
  Future<bool> canCall() async =>
      await _channel.invokeMethod<bool>('canCall') ?? false;

  @override
  Future<bool> requestSmsPermission() async =>
      (await Permission.sms.request()).isGranted;

  @override
  Future<List<String>> sendSms(List<String> numbers, String message) async {
    final failed = await _channel.invokeListMethod<String>('sendSms', {
      'numbers': numbers,
      'message': message,
    });
    return failed ?? const [];
  }

  @override
  Future<bool> locationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> requestLocationPermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  @override
  Future<LatLng> currentPosition(Duration timeout) async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,
        timeLimit: timeout,
      ),
    );
    return (lat: p.latitude, lng: p.longitude);
  }

  @override
  Future<LatLng?> lastKnownPosition() async {
    final p = await Geolocator.getLastKnownPosition(
      forceAndroidLocationManager: true,
    );
    return p == null ? null : (lat: p.latitude, lng: p.longitude);
  }

  @override
  Future<bool> canOpenDialer(String number) =>
      canLaunchUrl(Uri(scheme: 'tel', path: number));

  @override
  Future<void> openDialer(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  @override
  Future<void> requestTriggerPermissions() async {
    // Each may be denied/restricted (e.g. SMS on a Wi-Fi tablet); the trigger
    // still runs and explains what it skipped.
    await [
      Permission.notification,
      Permission.locationWhenInUse,
      Permission.sms,
      Permission.phone,
    ].request();
  }

  @override
  Future<void> enableTrigger(List<EmergencyContact> contacts) =>
      _channel.invokeMethod('enableVolumeTrigger', {
        'contacts': jsonEncode([for (final c in contacts) c.toJson()]),
      });

  @override
  Future<void> disableTrigger() => _channel.invokeMethod('disableVolumeTrigger');

  @override
  Future<bool> isTriggerOn() async =>
      await _channel.invokeMethod<bool>('isVolumeTriggerOn') ?? false;

  @override
  Future<void> debugTrigger() => _channel.invokeMethod('debugTrigger');
}
