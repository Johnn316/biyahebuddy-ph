import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// All widget tests run with the system "reduce motion" setting on, so the
/// endlessly pulsing SOS rings don't block `pumpAndSettle`. The pulse itself
/// is covered by a dedicated test that turns animations back on.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await testMain();
}
