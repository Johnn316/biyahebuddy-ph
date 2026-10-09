import 'dart:io';

import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/coding/asset_coding_service.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/repositories/asset_hotline_repository.dart';
import 'package:biyahebuddy_ph/data/repositories/prefs_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

void main() {
  group('bundled assets (guards the schemas in CLAUDE.md)', () {
    test('laws.json and fines.json seed the DB', () {
      final db = AppDatabase.open(
        ':memory:',
        lawsJson: _asset('laws.json'),
        finesJson: _asset('fines.json'),
      );
      addTearDown(db.close);
      int count(String table) =>
          db.db.select('SELECT count(*) AS c FROM $table').first['c'] as int;
      expect(count('laws'), greaterThan(0));
      expect(count('laws_fts'), count('laws'));
      expect(count('fines'), greaterThan(0));
      expect(count('fines_fts'), count('fines'));
    });

    test('coding.json and hotlines.json parse', () async {
      AssetCodingService.fromJson(_asset('coding.json'));
      final hotlines = AssetHotlineRepository.fromJson(_asset('hotlines.json'));
      expect(await hotlines.forZone(null), isNotEmpty);
    });
  });

  test('DB re-seeds only when the asset content changes', () {
    final dir = Directory.systemTemp.createTempSync('bb_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/t.db';
    String fines(String name) =>
        '[{"violation":"$name","agency":"lto","amount":1,'
        '"legal_basis":"x","aliases":[]}]';
    String stored(AppDatabase db) =>
        db.db.select('SELECT violation FROM fines').single['violation']
            as String;

    AppDatabase.open(path, lawsJson: '[]', finesJson: fines('A')).close();

    // Same assets: existing rows kept (tamper to prove no re-seed happened).
    var db = AppDatabase.open(path, lawsJson: '[]', finesJson: fines('A'));
    db.db.execute("UPDATE fines SET violation = 'kept'");
    db.close();
    db = AppDatabase.open(path, lawsJson: '[]', finesJson: fines('A'));
    expect(stored(db), 'kept');
    db.close();

    // New assets: rebuilt.
    db = AppDatabase.open(path, lawsJson: '[]', finesJson: fines('B'));
    expect(stored(db), 'B');
    db.close();
  });

  test('hotlines: zone first, then nationwide; zone is case-insensitive', () async {
    final repo = AssetHotlineRepository.fromJson('''[
      {"name": "911", "number": "911", "zone": null},
      {"name": "MMDA", "number": "136", "zone": "NCR"},
      {"name": "NLEX", "number": "1-35000", "zone": "NLEX"}
    ]''');
    expect((await repo.forZone('ncr')).map((h) => h.name), ['MMDA', '911']);
    expect((await repo.forZone(null)).map((h) => h.name), ['911']);
  });

  test('profile round-trips through shared_preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsProfileRepository(await SharedPreferences.getInstance());
    expect(await repo.load(), isNull);

    const profile = Profile(
      name: 'Juan',
      age: 30,
      plateNo: 'ABC 1234',
      licenseNo: 'N01',
      restrictionCode: 'B',
      vehicleType: 'Car',
      contacts: [EmergencyContact(name: 'Maria', phone: '0917')],
    );
    await repo.save(profile);
    expect((await repo.load())?.toJson(), profile.toJson());
  });

  test('corrupt stored profile loads as null so onboarding runs', () async {
    SharedPreferences.setMockInitialValues({'profile_v1': '{not json'});
    final repo = PrefsProfileRepository(await SharedPreferences.getInstance());
    expect(await repo.load(), isNull);
  });
}
