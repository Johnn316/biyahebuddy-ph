import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProfileRepository implements ProfileRepository {
  MemoryProfileRepository([this.profile]);

  Profile? profile;

  @override
  Future<Profile?> load() async => profile;

  @override
  Future<void> save(Profile p) async => profile = p;
}

class FixedCodingService implements CodingService {
  const FixedCodingService({required this.isCoding});

  final bool isCoding;

  @override
  CodingStatus statusFor(String plateNo, DateTime now) =>
      CodingStatus(isCoding: isCoding, message: 'test');
}

/// Phone-sized portrait viewport (logical 412x915, e.g. Pixel 7).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Records SOS calls instead of logging them.
class RecordingSosService implements SosService {
  RecordingSosService({this.location = (lat: 14.5547, lng: 121.0244)});

  final ({double lat, double lng})? location;
  final dialed = <String>[];
  final texts = <({List<String> phones, String message})>[];

  @override
  Future<({double lat, double lng})?> currentLocation() async => location;

  @override
  Future<void> smsContacts(
    List<EmergencyContact> contacts,
    String message,
  ) async => texts.add((
    phones: [for (final c in contacts) c.phone],
    message: message,
  ));

  @override
  Future<void> openDialer(String number) async => dialed.add(number);

  @override
  Future<void> enableVolumeTrigger() async {}
}
