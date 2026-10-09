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
