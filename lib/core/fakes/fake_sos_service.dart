import 'package:flutter/foundation.dart';

import '../contracts/contracts.dart';

/// Logs instead of sending SMS / calling. Never touches real hardware.
class FakeSosService implements SosService {
  @override
  Future<({double lat, double lng})?> currentLocation() async =>
      (lat: 14.5547, lng: 121.0244); // Makati (sample)

  @override
  Future<void> smsContacts(
    List<EmergencyContact> contacts,
    String message,
  ) async =>
      debugPrint('[FakeSos] SMS to ${contacts.map((c) => c.phone)}: $message');

  @override
  Future<void> openDialer(String number) async =>
      debugPrint('[FakeSos] dial $number');

  @override
  Future<void> enableVolumeTrigger() async =>
      debugPrint('[FakeSos] volume trigger enabled (fake)');
}
