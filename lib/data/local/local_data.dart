import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/local_ai_assistant.dart';
import '../ai/local_llm.dart';
import '../ai/local_model_manager.dart';
import '../ai/model_catalog.dart';
import '../ai/whisper_speech_service.dart';
import '../coding/asset_coding_service.dart';
import '../rag/hybrid_retriever.dart';
import '../rag/law_retriever.dart';
import '../rag/text_embedder.dart';
import '../rag/vector_index.dart';
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

  /// Semantic retrieval, if the bundled embeddings match the bundled data and
  /// the embedding model. Otherwise null → keyword (FTS5) retrieval only.
  static Future<HybridRetriever?> _hybrid(
    AssetBundle assets,
    LawRetriever keyword,
    LocalModelManager models,
    String laws,
    String fines,
  ) async {
    try {
      final (embeddings, faq) = await (
        assets.loadString('assets/data/embeddings.json'),
        assets.loadString('assets/data/faq.json').catchError((_) => '[]'),
      ).wait;
      final index = VectorIndex.fromJson(embeddings);
      final spec = EmbeddingSpec.byId(index.modelId);
      if (index.sourceHash != VectorIndex.hashSources(laws, fines, faq)) {
        return null; // stale: rerun tools/build_embeddings.dart
      }
      return HybridRetriever(
        keyword: keyword,
        index: index,
        embedder: LlamaTextEmbedder(
          spec: spec,
          modelPath: () => models.pathFor(ModelCatalog.embedder),
        ),
      );
    } on Object {
      return null;
    }
  }

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
    final models = LocalModelManager(models: ModelCatalog.enabled);
    await models.refresh();

    final database = AppDatabase.open(
      '${dir.path}/biyahebuddy.db',
      lawsJson: laws,
      finesJson: fines,
    );
    final keyword = LawRetriever(database);
    final hybrid = await _hybrid(assets, keyword, models, laws, fines);
    return _instance = LocalData._(
      database: database,
      profiles: profiles,
      coding: AssetCodingService.fromJson(coding),
      fines: SqliteFinesRepository(database),
      hotlines: AssetHotlineRepository.fromJson(hotlines),
      models: models,
      ai: LocalAiAssistant(
        retriever: keyword,
        llm: LocalLlm(modelPath: () => models.pathFor(ModelCatalog.llm)),
        isModelReady: () => models.has(ModelCatalog.llm),
        hybrid: hybrid,
        isHybridReady: () => models.has(ModelCatalog.embedder),
      ),
      speech: WhisperSpeechService(
        modelPath: () => models.pathFor(ModelCatalog.whisper),
        isModelReady: () => models.has(ModelCatalog.whisper),
      ),
      sos: AndroidSosService(
        platform: ChannelSosPlatform(),
        loadContacts: () async => (await profiles.load())?.contacts ?? const [],
      ),
    );
  }
}
