import '../contracts/contracts.dart';

/// Simulates a ~3 second model download. Nothing is fetched.
class FakeModelManager implements ModelManager {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Stream<double> downloadModels() async* {
    if (_ready) {
      yield 1.0;
      return;
    }
    for (var i = 0; i <= 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      yield i / 20;
    }
    _ready = true;
  }
}
