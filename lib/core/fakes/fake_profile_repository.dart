import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/contracts.dart';

/// Starts EMPTY so onboarding shows on first launch, then persists the saved
/// profile as JSON in shared_preferences so it survives app restarts.
/// Backend replaces this with the real (sqlite) ProfileRepository.
class FakeProfileRepository implements ProfileRepository {
  static const prefsKey = 'fake_profile_v1';

  /// Sample profile for tests and demos.
  static const sample = Profile(
    name: 'Juan Dela Cruz',
    age: 34,
    plateNo: 'NAB 1234',
    licenseNo: 'N01-23-456789',
    restrictionCode: 'B, B1',
    vehicleType: 'Kotse',
    bloodType: 'O+',
    insurer: 'Sample Insurance Co.',
    policyNo: 'POL-0000-SAMPLE',
    contacts: [
      EmergencyContact(name: 'Maria Dela Cruz (asawa)', phone: '09171234567'),
      EmergencyContact(name: 'Pedro Dela Cruz (kapatid)', phone: '09981234567'),
    ],
  );

  @override
  Future<Profile?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(prefsKey);
    if (raw == null) return null;
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Profile profile) async {
    await (await SharedPreferences.getInstance()).setString(
      prefsKey,
      jsonEncode(profile.toJson()),
    );
  }
}
