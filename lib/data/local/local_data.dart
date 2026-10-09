import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../coding/asset_coding_service.dart';
import '../repositories/asset_hotline_repository.dart';
import '../repositories/prefs_profile_repository.dart';
import '../repositories/sqlite_fines_repository.dart';
import 'app_database.dart';

/// Loads every local data source once at startup (fast: small JSON + sqlite).
/// Needed because `CodingService.statusFor` is sync but assets load async.
///
/// Call `await LocalData.init()` in main() before runApp; providers.dart then
/// reads [LocalData.instance].
class LocalData {
  LocalData._({
    required this.database,
    required this.profiles,
    required this.coding,
    required this.fines,
    required this.hotlines,
  });

  static LocalData? _instance;

  static LocalData get instance =>
      _instance ??
      (throw StateError('LocalData.init() was not awaited in main().'));

  final AppDatabase database;
  final PrefsProfileRepository profiles;
  final AssetCodingService coding;
  final SqliteFinesRepository fines;
  final AssetHotlineRepository hotlines;

  static Future<LocalData> init({AssetBundle? bundle}) async {
    if (_instance != null) return _instance!;
    final assets = bundle ?? rootBundle;
    final (laws, fines, hotlines, coding, dir, prefs) = await (
      assets.loadString('assets/data/laws.json'),
      assets.loadString('assets/data/fines.json'),
      assets.loadString('assets/data/hotlines.json'),
      assets.loadString('assets/data/coding.json'),
      getApplicationSupportDirectory(),
      SharedPreferences.getInstance(),
    ).wait;

    final database = AppDatabase.open(
      '${dir.path}/biyahebuddy.db',
      lawsJson: laws,
      finesJson: fines,
    );
    return _instance = LocalData._(
      database: database,
      profiles: PrefsProfileRepository(prefs),
      coding: AssetCodingService.fromJson(coding),
      fines: SqliteFinesRepository(database),
      hotlines: AssetHotlineRepository.fromJson(hotlines),
    );
  }
}
