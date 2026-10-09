import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contracts/contracts.dart';

/// Stores the driver profile as JSON in shared_preferences (on-device only).
class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._prefs);

  static const _key = 'profile_v1';

  final SharedPreferences _prefs;

  @override
  Future<Profile?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt or old-format data: treat as no profile so onboarding runs.
      return null;
    }
  }

  @override
  Future<void> save(Profile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
