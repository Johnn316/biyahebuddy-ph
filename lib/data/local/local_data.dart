import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/local_ai_assistant.dart';
import '../ai/local_llm.dart';
import '../ai/local_model_manager.dart';
import '../ai/model_catalog.dart';
import '../ai/whisper_speech_service.dart';
import '../coding/asset_coding_service.dart';
import '../rag/law_retriever.dart';
import '../sos/android_sos_service.dart';
import '../sos/sos_platform.dart';
import '../repositories/asset_hotline_repository.dart';
import '../repositories/prefs_profile_repository.dart';
import '../repositories/sqlite_fines_repository.dart';
import 'app_database.dart';

/// Loads every on-device backend piece once at startup (fast: small JSON,
/// sqlite, and a file-size check of the models; the LLM itself loads lazily).
/// Needed because `CodingService.statusFor` and `ModelManager.isReady` are
/// sync but their data loads async.
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
    required this.models,
    required this.ai,
    required this.speech,
    required this.sos,
  });

  static LocalData? _instance;

  static bool get isReady => _instance != null;

  static LocalData get instance =>
      _instance ??
      (throw StateError('LocalData.init() was not awaited in main().'));

  final AppDatabase database;
  final PrefsProfileRepository profiles;
  final AssetCodingService coding;
  final SqliteFinesRepository fines;
  final AssetHotlineRepository hotlines;
  final LocalModelManager models;
  final LocalAiAssistant ai;
  final WhisperSpeechService speech;
  final AndroidSosService sos;

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

    final profiles = PrefsProfileRepository(prefs);
    final models = LocalModelManager();
    await models.refresh();

    final database = AppDatabase.open(
      '${dir.path}/biyahebuddy.db',
      lawsJson: laws,
      finesJson: fines,
    );
    return _instance = LocalData._(
      database: database,
      profiles: profiles,
      coding: AssetCodingService.fromJson(coding),
      fines: SqliteFinesRepository(database),
      hotlines: AssetHotlineRepository.fromJson(hotlines),
      models: models,
      ai: LocalAiAssistant(
        retriever: LawRetriever(database),
        llm: LocalLlm(modelPath: () => models.pathFor(ModelCatalog.llm)),
        isModelReady: () => models.isReady,
      ),
      speech: WhisperSpeechService(
        modelPath: () => models.pathFor(ModelCatalog.whisper),
        isModelReady: () => models.isReady,
      ),
      sos: AndroidSosService(
        platform: ChannelSosPlatform(),
        loadContacts: () async => (await profiles.load())?.contacts ?? const [],
      ),
    );
  }
}
