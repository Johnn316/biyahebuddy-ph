import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/contracts/contracts.dart';
import 'model_catalog.dart';

/// Downloads the on-device models once into app support storage.
///
/// THIS IS THE ONLY NETWORK CODE IN THE APP. Everything else is offline.
/// Interrupted downloads resume from the `.part` file (HTTP Range).
class LocalModelManager implements ModelManager {
  LocalModelManager({this.models = ModelCatalog.all});

  final List<ModelSpec> models;

  Directory? _dir;
  bool _ready = false;
  final _complete = <String>{};

  /// Last result of [refresh] or a finished download. Call [refresh] once at
  /// startup; the getter is sync because the contract is.
  @override
  bool get isReady => _ready;

  Future<Directory> _modelDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    _dir = await Directory('${base.path}/models').create(recursive: true);
    return _dir!;
  }

  Future<String> pathFor(ModelSpec spec) async =>
      '${(await _modelDir()).path}/${spec.fileName}';

  Future<bool> _isComplete(ModelSpec spec) async {
    final file = File(await pathFor(spec));
    return await file.exists() && await file.length() == spec.sizeBytes;
  }

  /// Whether [spec]'s file is fully downloaded (as of the last [refresh]).
  /// Lets each feature use its own model even if another is still missing.
  bool has(ModelSpec spec) => _complete.contains(spec.id);

  /// Re-checks the files on disk and updates [isReady] and [has].
  Future<bool> refresh() async {
    _complete.clear();
    for (final spec in models) {
      if (await _isComplete(spec)) _complete.add(spec.id);
    }
    return _ready = _complete.length == models.length;
  }

  @override
  Stream<double> downloadModels() async* {
    final total = models.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    var doneBefore = 0;
    yield 0;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      for (final spec in models) {
        if (!await _isComplete(spec)) {
          await for (final got in _download(client, spec)) {
            yield (doneBefore + got) / total;
          }
        }
        doneBefore += spec.sizeBytes;
        yield doneBefore / total;
      }
    } finally {
      client.close(force: true);
    }
    await refresh();
  }

  /// Streams bytes-on-disk for [spec] while downloading it.
  Stream<int> _download(HttpClient client, ModelSpec spec) async* {
    final target = File(await pathFor(spec));
    final part = File('${target.path}.part');
    var have = await part.exists() ? await part.length() : 0;
    if (have > spec.sizeBytes) {
      await part.delete();
      have = 0;
    }

    final request = await client.getUrl(Uri.parse(spec.url));
    if (have > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
    final response = await request.close();

    final FileMode mode;
    if (response.statusCode == HttpStatus.partialContent) {
      mode = FileMode.append;
    } else if (response.statusCode == HttpStatus.ok) {
      mode = FileMode.write; // Server ignored Range: start over.
      have = 0;
    } else {
      await response.drain<void>();
      throw HttpException(
        'Model download failed (${response.statusCode}) for ${spec.fileName}',
      );
    }

    final sink = part.openWrite(mode: mode);
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        have += chunk.length;
        yield have;
      }
    } finally {
      await sink.close();
    }

    if (have != spec.sizeBytes) {
      throw HttpException(
        'Incomplete download for ${spec.fileName}: $have/${spec.sizeBytes} '
        'bytes. Retry to resume.',
      );
    }
    await part.rename(target.path);
  }
}
